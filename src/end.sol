// SPDX-License-Identifier: AGPL-3.0-or-later

/// end.sol -- global settlement engine

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2018 Lev Livnev <lev@liv.nev.org.uk>
// Copyright (C) 2020-2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.20;

interface VatLike {
  function dai(address) external view returns (uint);
  function ilks(bytes32 ilk)
    external
    returns (
      uint Art, // [wad]
      uint rate, // [ray]
      uint spot, // [ray]
      uint line, // [rad]
      uint dust
    ); // [rad]

  function urns(bytes32 ilk, address urn)
    external
    returns (
      uint ink, // [wad]
      uint art
    ); // [wad]

  function debt() external returns (uint);
  function move(address src, address dst, uint rad) external;
  function hope(address) external;
  function flux(bytes32 ilk, address src, address dst, uint rad) external;
  function grab(bytes32 i, address u, address v, address w, int dink, int dart) external;
  function suck(address u, address v, uint rad) external;
  function cage() external;
}

interface CatLike {
  function ilks(bytes32)
    external
    returns (
      address flip,
      uint chop, // [ray]
      uint lump
    ); // [rad]

  function cage() external;
}

interface DogLike {
  function ilks(bytes32) external returns (address clip, uint chop, uint hole, uint dirt);
  function cage() external;
}

interface PotLike {
  function cage() external;
}

interface VowLike {
  function cage() external;
}

interface FlipLike {
  function bids(uint id)
    external
    view
    returns (
      uint bid, // [rad]
      uint lot, // [wad]
      address guy,
      uint48 tic, // [unix epoch time]
      uint48 end, // [unix epoch time]
      address usr,
      address gal,
      uint tab
    ); // [rad]

  function yank(uint id) external;
}

interface ClipLike {
  function sales(uint id)
    external
    view
    returns (uint pos, uint tab, uint lot, address usr, uint96 tic, uint top);
  function yank(uint id) external;
}

interface PipLike {
  function read() external view returns (bytes32);
}

interface SpotLike {
  function par() external view returns (uint);
  function ilks(bytes32) external view returns (PipLike pip, uint mat); // [ray]

  function cage() external;
}

interface CureLike {
  function tell() external view returns (uint);
  function cage() external;
}

/*
    This is the `End` and it coordinates Global Settlement. This is an
    involved, stateful process that takes place over nine steps.

    First we freeze the system and lock the prices for each ilk.

    1. `cage()`:
        - freezes user entrypoints
        - cancels flop/flap auctions
        - starts cooldown period
        - stops pot drips

    2. `cage(ilk)`:
       - set the cage price for each `ilk`, reading off the price feed

    We must process some system state before it is possible to calculate
    the final dai / collateral price. In particular, we need to determine

      a. `gap`, the collateral shortfall per collateral type by
         considering under-collateralised CDPs.

      b. `debt`, the outstanding dai supply after including system
         surplus / deficit

    We determine (a) by processing all under-collateralised CDPs with
    `skim`:

    3. `skim(ilk, urn)`:
       - cancels CDP debt
       - any excess collateral remains
       - backing collateral taken

    We determine (b) by processing ongoing dai generating processes,
    i.e. auctions. We need to ensure that auctions will not generate any
    further dai income.

    In the two-way auction model (Flipper) this occurs when
    all auctions are in the reverse (`dent`) phase. There are two ways
    of ensuring this:

    4a. i) `wait`: set the cooldown period to be at least as long as the
           longest auction duration, which needs to be determined by the
           cage administrator.

           This takes a fairly predictable time to occur but with altered
           auction dynamics due to the block.timestamp varying price of dai.

       ii) `skip`: cancel all ongoing auctions and seize the collateral.

           This allows for faster processing at the expense of more
           processing calls. This option allows dai holders to retrieve
           their collateral faster.

           `skip(ilk, id)`:
            - cancel individual flip auctions in the `tend` (forward) phase
            - retrieves collateral and debt (including penalty) to owner's CDP
            - returns dai to last bidder
            - `dent` (reverse) phase auctions can continue normally

    Option (i), `wait`, is sufficient (if all auctions were bidded at least
    once) for processing the system settlement but option (ii), `skip`,
    will speed it up. Both options are available in this implementation,
    with `skip` being enabled on a per-auction basis.

    In the case of the Dutch Auctions model (Clipper) they keep recovering
    debt during the whole lifetime and there isn't a max duration time
    guaranteed for the auction to end.
    So the way to ensure the protocol will not receive extra dai income is:

    4b. i) `snip`: cancel all ongoing auctions and seize the collateral.

           `snip(ilk, id)`:
            - cancel individual running clip auctions
            - retrieves remaining collateral and debt (including penalty)
              to owner's CDP

    When a CDP has been processed and has no debt remaining, the
    remaining collateral can be removed.

    5. `free(ilk)`:
        - remove collateral from the caller's CDP
        - owner can call as needed

    After the processing period has elapsed, we enable calculation of
    the final price for each collateral type.

    6. `thaw()`:
       - only callable after processing time period elapsed
       - assumption that all under-collateralised CDPs are processed
       - fixes the total outstanding supply of dai
       - may also require extra CDP processing to cover vow surplus

    7. `flow(ilk)`:
        - calculate the `fix`, the cash price for a given ilk
        - adjusts the `fix` in the case of deficit / surplus

    At this point we have computed the final price for each collateral
    type and dai holders can block.timestamp turn their dai into collateral. Each
    unit dai can claim a fixed basket of collateral.

    Dai holders must first `pack` some dai into a `bag`. Once packed,
    dai cannot be unpacked and is not transferrable. More dai can be
    added to a bag later.

    8. `pack(wad)`:
        - put some dai into a bag in preparation for `cash`

    Finally, collateral can be obtained with `cash`. The bigger the bag,
    the more collateral can be released.

    9. `cash(ilk, wad)`:
        - exchange some dai from your bag for gems from a specific ilk
        - the number of gems is limited by how big your bag is
*/

contract End {
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
    require(wards[msg.sender] == 1, "End/not-authorized");
    _;
  }

  // --- Data ---
  VatLike public vat; // CDP Engine
  CatLike public cat;
  DogLike public dog;
  VowLike public vow; // Debt Engine
  PotLike public pot;
  SpotLike public spot;
  CureLike public cure;

  uint public live; // Active Flag
  uint public when; // Time of cage                   [unix epoch time]
  uint public wait; // Processing Cooldown Length             [seconds]
  uint public debt; // Total outstanding dai following processing [rad]

  mapping(bytes32 => uint) public tag; // Cage price              [ray]
  mapping(bytes32 => uint) public gap; // Collateral shortfall    [wad]
  mapping(bytes32 => uint) public Art; // Total debt per ilk      [wad]
  mapping(bytes32 => uint) public fix; // Final cash price        [ray]

  mapping(address => uint) public bag; //    [wad]
  mapping(bytes32 => mapping(address => uint)) public out; //    [wad]

  // --- Events ---
  event Rely(address indexed usr);
  event Deny(address indexed usr);

  event File(bytes32 indexed what, uint data);
  event File(bytes32 indexed what, address data);

  event Cage();
  event Cage(bytes32 indexed ilk);
  event Snip(
    bytes32 indexed ilk, uint indexed id, address indexed usr, uint tab, uint lot, uint art
  );
  event Skip(
    bytes32 indexed ilk, uint indexed id, address indexed usr, uint tab, uint lot, uint art
  );
  event Skim(bytes32 indexed ilk, address indexed urn, uint wad, uint art);
  event Free(bytes32 indexed ilk, address indexed usr, uint ink);
  event Thaw();
  event Flow(bytes32 indexed ilk);
  event Pack(address indexed usr, uint wad);
  event Cash(bytes32 indexed ilk, address indexed usr, uint wad);

  // --- Init ---
  constructor() {
    wards[msg.sender] = 1;
    live = 1;
    emit Rely(msg.sender);
  }

  // --- Math ---
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = x + y;
    require(z >= x);
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
  }

  function min(uint x, uint y) internal pure returns (uint z) {
    return x <= y ? x : y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, y) / RAY;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = mul(x, WAD) / y;
  }

  // --- Administration ---
  function file(bytes32 what, address data) external auth {
    require(live == 1, "End/not-live");
    if (what == "vat") vat = VatLike(data);
    else if (what == "cat") cat = CatLike(data);
    else if (what == "dog") dog = DogLike(data);
    else if (what == "vow") vow = VowLike(data);
    else if (what == "pot") pot = PotLike(data);
    else if (what == "spot") spot = SpotLike(data);
    else if (what == "cure") cure = CureLike(data);
    else revert("End/file-unrecognized-param");
    emit File(what, data);
  }

  function file(bytes32 what, uint data) external auth {
    require(live == 1, "End/not-live");
    if (what == "wait") wait = data;
    else revert("End/file-unrecognized-param");
    emit File(what, data);
  }

  // --- Settlement ---
  function cage() external auth {
    require(live == 1, "End/not-live");
    live = 0;
    when = block.timestamp;
    vat.cage();
    cat.cage();
    dog.cage();
    vow.cage();
    spot.cage();
    pot.cage();
    cure.cage();
    emit Cage();
  }

  function cage(bytes32 ilk) external {
    require(live == 0, "End/still-live");
    require(tag[ilk] == 0, "End/tag-ilk-already-defined");
    (Art[ilk],,,,) = vat.ilks(ilk);
    (PipLike pip,) = spot.ilks(ilk);
    // par is a ray, pip returns a wad
    tag[ilk] = wdiv(spot.par(), uint(pip.read()));
    emit Cage(ilk);
  }

  function snip(bytes32 ilk, uint id) external {
    require(tag[ilk] != 0, "End/tag-ilk-not-defined");

    (address _clip,,,) = dog.ilks(ilk);
    ClipLike clip = ClipLike(_clip);
    (, uint rate,,,) = vat.ilks(ilk);
    (, uint tab, uint lot, address usr,,) = clip.sales(id);

    vat.suck(address(vow), address(vow), tab);
    clip.yank(id);

    uint art = tab / rate;
    Art[ilk] = add(Art[ilk], art);
    require(int(lot) >= 0 && int(art) >= 0, "End/overflow");
    vat.grab(ilk, usr, address(this), address(vow), int(lot), int(art));
    emit Snip(ilk, id, usr, tab, lot, art);
  }

  function skip(bytes32 ilk, uint id) external {
    require(tag[ilk] != 0, "End/tag-ilk-not-defined");

    (address _flip,,) = cat.ilks(ilk);
    FlipLike flip = FlipLike(_flip);
    (, uint rate,,,) = vat.ilks(ilk);
    (uint bid, uint lot,,,, address usr,, uint tab) = flip.bids(id);

    vat.suck(address(vow), address(vow), tab);
    vat.suck(address(vow), address(this), bid);
    vat.hope(address(flip));
    flip.yank(id);

    uint art = tab / rate;
    Art[ilk] = add(Art[ilk], art);
    require(int(lot) >= 0 && int(art) >= 0, "End/overflow");
    vat.grab(ilk, usr, address(this), address(vow), int(lot), int(art));
    emit Skip(ilk, id, usr, tab, lot, art);
  }

  function skim(bytes32 ilk, address urn) external {
    require(tag[ilk] != 0, "End/tag-ilk-not-defined");
    (, uint rate,,,) = vat.ilks(ilk);
    (uint ink, uint art) = vat.urns(ilk, urn);

    uint owe = rmul(rmul(art, rate), tag[ilk]);
    uint wad = min(ink, owe);
    gap[ilk] = add(gap[ilk], sub(owe, wad));

    require(wad <= 2 ** 255 && art <= 2 ** 255, "End/overflow");
    vat.grab(ilk, urn, address(this), address(vow), -int(wad), -int(art));
    emit Skim(ilk, urn, wad, art);
  }

  function free(bytes32 ilk) external {
    require(live == 0, "End/still-live");
    (uint ink, uint art) = vat.urns(ilk, msg.sender);
    require(art == 0, "End/art-not-zero");
    require(ink <= 2 ** 255, "End/overflow");
    vat.grab(ilk, msg.sender, msg.sender, address(vow), -int(ink), 0);
    emit Free(ilk, msg.sender, ink);
  }

  function thaw() external {
    require(live == 0, "End/still-live");
    require(debt == 0, "End/debt-not-zero");
    require(vat.dai(address(vow)) == 0, "End/surplus-not-zero");
    require(block.timestamp >= add(when, wait), "End/wait-not-finished");
    debt = sub(vat.debt(), cure.tell());
    emit Thaw();
  }

  function flow(bytes32 ilk) external {
    require(debt != 0, "End/debt-zero");
    require(fix[ilk] == 0, "End/fix-ilk-already-defined");

    (, uint rate,,,) = vat.ilks(ilk);
    uint wad = rmul(rmul(Art[ilk], rate), tag[ilk]);
    fix[ilk] = mul(sub(wad, gap[ilk]), RAY) / (debt / RAY);
    emit Flow(ilk);
  }

  function pack(uint wad) external {
    require(debt != 0, "End/debt-zero");
    vat.move(msg.sender, address(vow), mul(wad, RAY));
    bag[msg.sender] = add(bag[msg.sender], wad);
    emit Pack(msg.sender, wad);
  }

  function cash(bytes32 ilk, uint wad) external {
    require(fix[ilk] != 0, "End/fix-ilk-not-defined");
    vat.flux(ilk, address(this), msg.sender, rmul(wad, fix[ilk]));
    out[ilk][msg.sender] = add(out[ilk][msg.sender], wad);
    require(out[ilk][msg.sender] <= bag[msg.sender], "End/insufficient-bag-balance");
    emit Cash(ilk, msg.sender, wad);
  }
}
