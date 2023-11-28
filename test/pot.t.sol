// SPDX-License-Identifier: AGPL-3.0-or-later

// pot.t.sol -- tests for pot.sol

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

import "ds-test/test.sol";
import {Vat} from "../src/vat.sol";
import {Pot} from "../src/pot.sol";

interface Hevm {
    function warp(uint256) external;
}

contract DSRTest is DSTest {
    Hevm hevm;

    Vat vat;
    Pot pot;

    address vow;
    address self;
    address potb;

    function rad(uint256 wad_) internal pure returns (uint256) {
        return wad_ * 10 ** 27;
    }

    function wad(uint256 rad_) internal pure returns (uint256) {
        return rad_ / 10 ** 27;
    }

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        vat = new Vat();
        pot = new Pot(address(vat));
        vat.rely(address(pot));
        self = address(this);
        potb = address(pot);

        vow = address(bytes20("vow"));
        pot.file("vow", vow);

        vat.suck(self, self, rad(100 ether));
        vat.hope(address(pot));
    }

    function test_save_0d() public {
        assertEq(vat.dai(self), rad(100 ether));

        pot.join(100 ether);
        assertEq(wad(vat.dai(self)), 0 ether);
        assertEq(pot.pie(self), 100 ether);

        pot.drip();

        pot.exit(100 ether);
        assertEq(wad(vat.dai(self)), 100 ether);
    }

    function test_save_1d() public {
        pot.join(100 ether);
        pot.file("dsr", uint256(1000000564701133626865910626)); // 5% / day
        hevm.warp(block.timestamp + 1 days);
        pot.drip();
        assertEq(pot.pie(self), 100 ether);
        pot.exit(100 ether);
        assertEq(wad(vat.dai(self)), 105 ether);
    }

    function test_drip_multi() public {
        pot.join(100 ether);
        pot.file("dsr", uint256(1000000564701133626865910626)); // 5% / day
        hevm.warp(block.timestamp + 1 days);
        pot.drip();
        assertEq(wad(vat.dai(potb)), 105 ether);
        pot.file("dsr", uint256(1000001103127689513476993127)); // 10% / day
        hevm.warp(block.timestamp + 1 days);
        pot.drip();
        assertEq(wad(vat.sin(vow)), 15.5 ether);
        assertEq(wad(vat.dai(potb)), 115.5 ether);
        assertEq(pot.Pie(), 100 ether);
        assertEq(pot.chi() / 10 ** 9, 1.155 ether);
    }

    function test_drip_multi_inBlock() public {
        pot.drip();
        uint256 rho = pot.rho();
        assertEq(rho, block.timestamp);
        hevm.warp(block.timestamp + 1 days);
        rho = pot.rho();
        assertEq(rho, block.timestamp - 1 days);
        pot.drip();
        rho = pot.rho();
        assertEq(rho, block.timestamp);
        pot.drip();
        rho = pot.rho();
        assertEq(rho, block.timestamp);
    }

    function test_save_multi() public {
        pot.join(100 ether);
        pot.file("dsr", uint256(1000000564701133626865910626)); // 5% / day
        hevm.warp(block.timestamp + 1 days);
        pot.drip();
        pot.exit(50 ether);
        assertEq(wad(vat.dai(self)), 52.5 ether);
        assertEq(pot.Pie(), 50.0 ether);

        pot.file("dsr", uint256(1000001103127689513476993127)); // 10% / day
        hevm.warp(block.timestamp + 1 days);
        pot.drip();
        pot.exit(50 ether);
        assertEq(wad(vat.dai(self)), 110.25 ether);
        assertEq(pot.Pie(), 0.0 ether);
    }

    function test_fresh_chi() public {
        uint256 rho = pot.rho();
        assertEq(rho, block.timestamp);
        hevm.warp(block.timestamp + 1 days);
        assertEq(rho, block.timestamp - 1 days);
        pot.drip();
        pot.join(100 ether);
        assertEq(pot.pie(self), 100 ether);
        pot.exit(100 ether);
        // if we exit in the same transaction we should not earn DSR
        assertEq(wad(vat.dai(self)), 100 ether);
    }

    function testFail_stale_chi() public {
        pot.file("dsr", uint256(1000000564701133626865910626)); // 5% / day
        pot.drip();
        hevm.warp(block.timestamp + 1 days);
        pot.join(100 ether);
    }

    function test_file() public {
        hevm.warp(block.timestamp + 1);
        pot.drip();
        pot.file("dsr", uint256(1));
    }

    function testFail_file() public {
        hevm.warp(block.timestamp + 1);
        pot.file("dsr", uint256(1));
    }
}
