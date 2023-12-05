// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DSValue} from "ds-value/value.sol";
import "./deploy.sol";
import "../test/deploy/deploy.t.base.sol";
import {PipLike} from "../src/spot.sol";
import {Config} from "./config.sol";

interface IPip is PipLike {
  function poke(bytes32) external;
  // function peek() external returns (bytes32, bool);
}

contract DeploySrcipt is Config, DssDeployTestBase {
  uint constant ONE = 10 ** 18;

  // function gemJoin() internal {
  //   require(address(vat) != address(0), "vat must deployed before do this");
  //   for (uint i = 0; i < tl.tokenLength(); i++) {
  //     bytes32 symbol = tl.tokenList(i);
  //     GemJoin join = new GemJoin(address(vat), symbol, tl.tokens(symbol));
  //     LinearDecrease calc = calcFab.newLinearDecrease(address(this));
  //     calc.file(bytes32("tau"), 1 hours);
  //     dssDeploy.deployCollateralClip(symbol, address(join), address(new DSValue()), address(calc));
  //   }
  // }

  // function setParm() internal {
  //   this.file(address(vat), bytes32("Line"), uint(10000 * 10 ** 45));

  //   for (uint i = 0; i < tl.tokenLength(); i++) {
  //     bytes32 symbol = tl.tokenList(i);
  //     this.file(address(vat), symbol, bytes32("line"), uint(10000 * 10 ** 45));
  //     (PipLike pip,) = spotter.ilks(symbol);
  //     IPip(address(pip)).poke(bytes32(tl.prices(symbol)));
  //     this.file(address(spotter), symbol, bytes32("mat"), uint(1500000000 ether));
  //     spotter.poke(symbol);
  //   }
  // }

  function setUp() public override {
    super.setUp();
  }

  function run() public {
    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
    G memory g = parseConfig(json);
    console2.log("g.golbal.vat_line", g.global.vat_line);
    console2.log("g.import.gov", g.importx.gov);
    console2.log("g.tokens.length", g.tokens.length);

    // deploy the contract
    uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    _dssDeploy();

    vm.stopBroadcast();
  }
}
