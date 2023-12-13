// SPDX-License-Identifier: AGPL-3.0-or-later

/// abaci.sol -- price decrease functions for auctions

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

interface Abacus {
  // 1st arg: initial price               [ray]
  // 2nd arg: seconds since auction start [seconds]
  // returns: current auction price       [ray]
  function price(uint, uint) external view returns (uint);
}

contract LinearDecrease is Abacus {
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
    require(wards[msg.sender] == 1, "LinearDecrease/not-authorized");
    _;
  }

  // --- Data ---
  uint public tau; // Seconds after auction start when the price reaches zero [seconds]

  // --- Events ---
  event Rely(address indexed usr);
  event Deny(address indexed usr);

  event File(bytes32 indexed what, uint data);

  // --- Init ---
  constructor() {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
  }

  // --- Administration ---
  function file(bytes32 what, uint data) external auth {
    if (what == "tau") tau = data;
    else revert("LinearDecrease/file-unrecognized-param");
    emit File(what, data);
  }

  // --- Math ---
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = x * y;
    require(y == 0 || z / y == x);
    z = z / RAY;
  }

  // Price calculation when price is decreased linearly in proportion to time:
  // tau: The number of seconds after the start of the auction where the price will hit 0
  // top: Initial price
  // dur: current seconds since the start of the auction
  //
  // Returns y = top * ((tau - dur) / tau)
  //
  // Note the internal call to mul multiples by RAY, thereby ensuring that the rmul calculation
  // which utilizes top and tau (RAY values) is also a RAY value.
  function price(uint top, uint dur) external view override returns (uint) {
    if (dur >= tau) return 0;
    return rmul(top, mul(tau - dur, RAY) / tau);
  }
}

contract StairstepExponentialDecrease is Abacus {
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
    require(wards[msg.sender] == 1, "StairstepExponentialDecrease/not-authorized");
    _;
  }

  // --- Data ---
  uint public step; // Length of time between price drops [seconds]
  uint public cut; // Per-step multiplicative factor     [ray]

  // --- Events ---
  event Rely(address indexed usr);
  event Deny(address indexed usr);

  event File(bytes32 indexed what, uint data);

  // --- Init ---
  // @notice: `cut` and `step` values must be correctly set for
  //     this contract to return a valid price
  constructor() {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
  }

  // --- Administration ---
  function file(bytes32 what, uint data) external auth {
    if (what == "cut") require((cut = data) <= RAY, "StairstepExponentialDecrease/cut-gt-RAY");
    else if (what == "step") step = data;
    else revert("StairstepExponentialDecrease/file-unrecognized-param");
    emit File(what, data);
  }

  // --- Math ---
  uint constant RAY = 10 ** 27;

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = x * y;
    require(y == 0 || z / y == x);
    z = z / RAY;
  }
  // optimized version from dss PR #78

  function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
    assembly {
      switch n
      case 0 { z := b }
      default {
        switch x
        case 0 { z := 0 }
        default {
          switch mod(n, 2)
          case 0 { z := b }
          default { z := x }
          let half := div(b, 2) // for rounding.
          for { n := div(n, 2) } n { n := div(n, 2) } {
            let xx := mul(x, x)
            if shr(128, x) { revert(0, 0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0, 0) }
            x := div(xxRound, b)
            if mod(n, 2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0, 0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0, 0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }

  // top: initial price
  // dur: seconds since the auction has started
  // step: seconds between a price drop
  // cut: cut encodes the percentage to decrease per step.
  //   For efficiency, the values is set as (1 - (% value / 100)) * RAY
  //   So, for a 1% decrease per step, cut would be (1 - 0.01) * RAY
  //
  // returns: top * (cut ^ dur)
  //
  //
  function price(uint top, uint dur) external view override returns (uint) {
    return rmul(top, rpow(cut, dur / step, RAY));
  }
}

// While an equivalent function can be obtained by setting step = 1 in StairstepExponentialDecrease,
// this continous (i.e. per-second) exponential decrease has be implemented as it is more gas-efficient
// than using the stairstep version with step = 1 (primarily due to 1 fewer SLOAD per price calculation).
contract ExponentialDecrease is Abacus {
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
    require(wards[msg.sender] == 1, "ExponentialDecrease/not-authorized");
    _;
  }

  // --- Data ---
  uint public cut; // Per-second multiplicative factor [ray]

  // --- Events ---
  event Rely(address indexed usr);
  event Deny(address indexed usr);

  event File(bytes32 indexed what, uint data);

  // --- Init ---
  // @notice: `cut` value must be correctly set for
  //     this contract to return a valid price
  constructor() {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
  }

  // --- Administration ---
  function file(bytes32 what, uint data) external auth {
    if (what == "cut") require((cut = data) <= RAY, "ExponentialDecrease/cut-gt-RAY");
    else revert("ExponentialDecrease/file-unrecognized-param");
    emit File(what, data);
  }

  // --- Math ---
  uint constant RAY = 10 ** 27;

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = x * y;
    require(y == 0 || z / y == x);
    z = z / RAY;
  }
  // optimized version from dss PR #78

  function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
    assembly {
      switch n
      case 0 { z := b }
      default {
        switch x
        case 0 { z := 0 }
        default {
          switch mod(n, 2)
          case 0 { z := b }
          default { z := x }
          let half := div(b, 2) // for rounding.
          for { n := div(n, 2) } n { n := div(n, 2) } {
            let xx := mul(x, x)
            if shr(128, x) { revert(0, 0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0, 0) }
            x := div(xxRound, b)
            if mod(n, 2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0, 0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0, 0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }

  // top: initial price
  // dur: seconds since the auction has started
  // cut: cut encodes the percentage to decrease per second.
  //   For efficiency, the values is set as (1 - (% value / 100)) * RAY
  //   So, for a 1% decrease per second, cut would be (1 - 0.01) * RAY
  //
  // returns: top * (cut ^ dur)
  //
  function price(uint top, uint dur) external view override returns (uint) {
    return rmul(top, rpow(cut, dur, RAY));
  }
}
