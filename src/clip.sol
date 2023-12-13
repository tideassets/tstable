// SPDX-License-Identifier: AGPL-3.0-or-later

/// clip.sol -- Dai auction module 2.0

// Copyright (C) 2020-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.13;

interface VatLike {
  function move(address, address, uint) external;
  function flux(bytes32, address, address, uint) external;
  function ilks(bytes32) external returns (uint, uint, uint, uint, uint);
  function suck(address, address, uint) external;
}

interface PipLike {
  function peek() external returns (bytes32, bool);
}

interface SpotterLike {
  function par() external returns (uint);
  function ilks(bytes32) external returns (PipLike, uint);
}

interface DogLike {
  function chop(bytes32) external returns (uint);
  function digs(bytes32, uint) external;
}

interface ClipperCallee {
  function clipperCall(address, uint, uint, bytes calldata) external;
}

interface AbacusLike {
  function price(uint, uint) external view returns (uint);
}

contract Clipper {
  // --- Auth ---
  mapping(address => uint) public wards;

  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }

  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }

  modifier auth() {
    require(wards[msg.sender] == 1, "Clipper/not-authorized");
    _;
  }

  // --- Data ---
  bytes32 public immutable ilk; // Collateral type of this Clipper
  VatLike public immutable vat; // Core CDP Engine

  DogLike public dog; // Liquidation module
  address public vow; // Recipient of dai raised in auctions
  SpotterLike public spotter; // Collateral price module
  AbacusLike public calc; // Current price calculator

  uint public buf; // Multiplicative factor to increase starting price                  [ray]
  uint public tail; // Time elapsed before auction reset                                 [seconds]
  uint public cusp; // Percentage drop before auction reset                              [ray]
  uint64 public chip; // Percentage of tab to suck from vow to incentivize keepers         [wad]
  uint192 public tip; // Flat fee to suck from vow to incentivize keepers                  [rad]
  uint public chost; // Cache the ilk dust times the ilk chop to prevent excessive SLOADs [rad]

  uint public kicks; // Total auctions
  uint[] public active; // Array of active auction ids

  struct Sale {
    uint pos; // Index in active array
    uint tab; // Dai to raise       [rad]
    uint lot; // collateral to sell [wad]
    address usr; // Liquidated CDP
    uint96 tic; // Auction start time
    uint top; // Starting price     [ray]
  }

  mapping(uint => Sale) public sales;

  uint internal locked;

  // Levels for circuit breaker
  // 0: no breaker
  // 1: no new kick()
  // 2: no new kick() or redo()
  // 3: no new kick(), redo(), or take()
  uint public stopped = 0;

  // --- Events ---
  event Rely(address indexed usr);
  event Deny(address indexed usr);

  event File(bytes32 indexed what, uint data);
  event File(bytes32 indexed what, address data);

  event Kick(
    uint indexed id,
    uint top,
    uint tab,
    uint lot,
    address indexed usr,
    address indexed kpr,
    uint coin
  );
  event Take(
    uint indexed id, uint max, uint price, uint owe, uint tab, uint lot, address indexed usr
  );
  event Redo(
    uint indexed id,
    uint top,
    uint tab,
    uint lot,
    address indexed usr,
    address indexed kpr,
    uint coin
  );

  event Yank(uint id);

  // --- Init ---
  constructor(address vat_, address spotter_, address dog_, bytes32 ilk_) {
    vat = VatLike(vat_);
    spotter = SpotterLike(spotter_);
    dog = DogLike(dog_);
    ilk = ilk_;
    buf = RAY;
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
  }

  // --- Synchronization ---
  modifier lock() {
    require(locked == 0, "Clipper/system-locked");
    locked = 1;
    _;
    locked = 0;
  }

  modifier isStopped(uint level) {
    require(stopped < level, "Clipper/stopped-incorrect");
    _;
  }

  // --- Administration ---
  function file(bytes32 what, uint data) external auth lock {
    if (what == "buf") buf = data;
    else if (what == "tail") tail = data; // Time elapsed before auction reset

    else if (what == "cusp") cusp = data; // Percentage drop before auction reset

    else if (what == "chip") chip = uint64(data); // Percentage of tab to incentivize (max: 2^64 - 1 => 18.xxx WAD = 18xx%)

    else if (what == "tip") tip = uint192(data); // Flat fee to incentivize keepers (max: 2^192 - 1 => 6.277T RAD)

    else if (what == "stopped") stopped = data; // Set breaker (0, 1, 2, or 3)

    else revert("Clipper/file-unrecognized-param");
    emit File(what, data);
  }

  function file(bytes32 what, address data) external auth lock {
    if (what == "spotter") spotter = SpotterLike(data);
    else if (what == "dog") dog = DogLike(data);
    else if (what == "vow") vow = data;
    else if (what == "calc") calc = AbacusLike(data);
    else revert("Clipper/file-unrecognized-param");
    emit File(what, data);
  }

  // --- Math ---
  uint constant BLN = 10 ** 9;
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function min(uint x, uint y) internal pure returns (uint z) {
    z = x <= y ? x : y;
  }

  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x);
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, y) / WAD;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, y) / RAY;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, RAY) / y;
  }

  // --- Auction ---

  // get the price directly from the OSM
  // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but
  // if mat has changed since the last poke, the resulting value will be
  // incorrect.
  function getFeedPrice() internal returns (uint feedPrice) {
    (PipLike pip,) = spotter.ilks(ilk);
    (bytes32 val, bool has) = pip.peek();
    require(has, "Clipper/invalid-price");
    feedPrice = rdiv(mul(uint(val), BLN), spotter.par());
  }

  // start an auction
  // note: trusts the caller to transfer collateral to the contract
  // The starting price `top` is obtained as follows:
  //
  //     top = val * buf / par
  //
  // Where `val` is the collateral's unitary value in USD, `buf` is a
  // multiplicative factor to increase the starting price, and `par` is a
  // reference per DAI.
  function kick(
    uint tab, // Debt                   [rad]
    uint lot, // Collateral             [wad]
    address usr, // Address that will receive any leftover collateral
    address kpr // Address that will receive incentives
  ) external auth lock isStopped(1) returns (uint id) {
    // Input validation
    require(tab > 0, "Clipper/zero-tab");
    require(lot > 0, "Clipper/zero-lot");
    require(usr != address(0), "Clipper/zero-usr");
    id = ++kicks;
    require(id > 0, "Clipper/overflow");

    active.push(id);

    sales[id].pos = active.length - 1;

    sales[id].tab = tab;
    sales[id].lot = lot;
    sales[id].usr = usr;
    sales[id].tic = uint96(block.timestamp);

    uint top;
    top = rmul(getFeedPrice(), buf);
    require(top > 0, "Clipper/zero-top-price");
    sales[id].top = top;

    // incentive to kick auction
    uint _tip = tip;
    uint _chip = chip;
    uint coin;
    if (_tip > 0 || _chip > 0) {
      coin = add(_tip, wmul(tab, _chip));
      vat.suck(vow, kpr, coin);
    }

    emit Kick(id, top, tab, lot, usr, kpr, coin);
  }

  // Reset an auction
  // See `kick` above for an explanation of the computation of `top`.
  function redo(
    uint id, // id of the auction to reset
    address kpr // Address that will receive incentives
  ) external lock isStopped(2) {
    // Read auction data
    address usr = sales[id].usr;
    uint96 tic = sales[id].tic;
    uint top = sales[id].top;

    require(usr != address(0), "Clipper/not-running-auction");

    // Check that auction needs reset
    // and compute current price [ray]
    (bool done,) = status(tic, top);
    require(done, "Clipper/cannot-reset");

    uint tab = sales[id].tab;
    uint lot = sales[id].lot;
    sales[id].tic = uint96(block.timestamp);

    uint feedPrice = getFeedPrice();
    top = rmul(feedPrice, buf);
    require(top > 0, "Clipper/zero-top-price");
    sales[id].top = top;

    // incentive to redo auction
    uint _tip = tip;
    uint _chip = chip;
    uint coin;
    if (_tip > 0 || _chip > 0) {
      uint _chost = chost;
      if (tab >= _chost && mul(lot, feedPrice) >= _chost) {
        coin = add(_tip, wmul(tab, _chip));
        vat.suck(vow, kpr, coin);
      }
    }

    emit Redo(id, top, tab, lot, usr, kpr, coin);
  }

  // Buy up to `amt` of collateral from the auction indexed by `id`.
  //
  // Auctions will not collect more DAI than their assigned DAI target,`tab`;
  // thus, if `amt` would cost more DAI than `tab` at the current price, the
  // amount of collateral purchased will instead be just enough to collect `tab` DAI.
  //
  // To avoid partial purchases resulting in very small leftover auctions that will
  // never be cleared, any partial purchase must leave at least `Clipper.chost`
  // remaining DAI target. `chost` is an asynchronously updated value equal to
  // (Vat.dust * Dog.chop(ilk) / WAD) where the values are understood to be determined
  // by whatever they were when Clipper.upchost() was last called. Purchase amounts
  // will be minimally decreased when necessary to respect this limit; i.e., if the
  // specified `amt` would leave `tab < chost` but `tab > 0`, the amount actually
  // purchased will be such that `tab == chost`.
  //
  // If `tab <= chost`, partial purchases are no longer possible; that is, the remaining
  // collateral can only be purchased entirely, or not at all.
  function take(
    uint id, // Auction id
    uint amt, // Upper limit on amount of collateral to buy  [wad]
    uint max, // Maximum acceptable price (DAI / collateral) [ray]
    address who, // Receiver of collateral and external call address
    bytes calldata data // Data to pass in external call; if length 0, no call is done
  ) external lock isStopped(3) {
    address usr = sales[id].usr;
    uint96 tic = sales[id].tic;

    require(usr != address(0), "Clipper/not-running-auction");

    uint price;
    {
      bool done;
      (done, price) = status(tic, sales[id].top);

      // Check that auction doesn't need reset
      require(!done, "Clipper/needs-reset");
    }

    // Ensure price is acceptable to buyer
    require(max >= price, "Clipper/too-expensive");

    uint lot = sales[id].lot;
    uint tab = sales[id].tab;
    uint owe;

    {
      // Purchase as much as possible, up to amt
      uint slice = min(lot, amt); // slice <= lot

      // DAI needed to buy a slice of this sale
      owe = mul(slice, price);

      // Don't collect more than tab of DAI
      if (owe > tab) {
        // Total debt will be paid
        owe = tab; // owe' <= owe
        // Adjust slice
        slice = owe / price; // slice' = owe' / price <= owe / price == slice <= lot
      } else if (owe < tab && slice < lot) {
        // If slice == lot => auction completed => dust doesn't matter
        uint _chost = chost;
        if (tab - owe < _chost) {
          // safe as owe < tab
          // If tab <= chost, buyers have to take the entire lot.
          require(tab > _chost, "Clipper/no-partial-purchase");
          // Adjust amount to pay
          owe = tab - _chost; // owe' <= owe
          // Adjust slice
          slice = owe / price; // slice' = owe' / price < owe / price == slice < lot
        }
      }

      // Calculate remaining tab after operation
      tab = tab - owe; // safe since owe <= tab
      // Calculate remaining lot after operation
      lot = lot - slice;

      // Send collateral to who
      vat.flux(ilk, address(this), who, slice);

      // Do external call (if data is defined) but to be
      // extremely careful we don't allow to do it to the two
      // contracts which the Clipper needs to be authorized
      DogLike dog_ = dog;
      if (data.length > 0 && who != address(vat) && who != address(dog_)) {
        ClipperCallee(who).clipperCall(msg.sender, owe, slice, data);
      }

      // Get DAI from caller
      vat.move(msg.sender, vow, owe);

      // Removes Dai out for liquidation from accumulator
      dog_.digs(ilk, lot == 0 ? tab + owe : owe);
    }

    if (lot == 0) {
      _remove(id);
    } else if (tab == 0) {
      vat.flux(ilk, address(this), usr, lot);
      _remove(id);
    } else {
      sales[id].tab = tab;
      sales[id].lot = lot;
    }

    emit Take(id, max, price, owe, tab, lot, usr);
  }

  function _remove(uint id) internal {
    uint _move = active[active.length - 1];
    if (id != _move) {
      uint _index = sales[id].pos;
      active[_index] = _move;
      sales[_move].pos = _index;
    }
    active.pop();
    delete sales[id];
  }

  // The number of active auctions
  function count() external view returns (uint) {
    return active.length;
  }

  // Return the entire array of active auctions
  function list() external view returns (uint[] memory) {
    return active;
  }

  // Externally returns boolean for if an auction needs a redo and also the current price
  function getStatus(uint id)
    external
    view
    returns (bool needsRedo, uint price, uint lot, uint tab)
  {
    // Read auction data
    address usr = sales[id].usr;
    uint96 tic = sales[id].tic;

    bool done;
    (done, price) = status(tic, sales[id].top);

    needsRedo = usr != address(0) && done;
    lot = sales[id].lot;
    tab = sales[id].tab;
  }

  // Internally returns boolean for if an auction needs a redo
  function status(uint96 tic, uint top) internal view returns (bool done, uint price) {
    price = calc.price(top, sub(block.timestamp, tic));
    done = (sub(block.timestamp, tic) > tail || rdiv(price, top) < cusp);
  }

  // Public function to update the cached dust*chop value.
  function upchost() external {
    (,,,, uint _dust) = VatLike(vat).ilks(ilk);
    chost = wmul(_dust, dog.chop(ilk));
  }

  // Cancel an auction during ES or via governance action.
  function yank(uint id) external auth lock {
    require(sales[id].usr != address(0), "Clipper/not-running-auction");
    dog.digs(ilk, sales[id].tab);
    vat.flux(ilk, address(this), msg.sender, sales[id].lot);
    _remove(id);
    emit Yank(id);
  }
}
