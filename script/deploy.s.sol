// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DSValue} from "ds-value/value.sol";
import "./deploy.sol";
import "../test/deploy.t.base.sol";
import {PipLike} from "../src/spot.sol";
import {ConfigInfo} from "./config.sol";

interface IPip is PipLike {
  function poke(bytes32) external;
  // function peek() external returns (bytes32, bool);
}

contract DeploySrcipt is DssDeployTestBase, Script {
  uint constant ONE = 10 ** 18;
  uint public constant TOKEN_LENGTH = 35;

  function parseConfig() public view returns (ConfigInfo.Token[] memory tokens) {
    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
    tokens = new ConfigInfo.Token[](TOKEN_LENGTH);
    for (uint i = 0; i < TOKEN_LENGTH; i++) {
      bytes memory jsonBytes =
        vm.parseJson(json, string(abi.encodePacked(".tokens[", vm.toString(i), "]")));
      tokens[i] = abi.decode(jsonBytes, (ConfigInfo.Token));
    }
  }

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
    ConfigInfo.Config memory config = ConfigInfo.initConfig();
    ConfigInfo.Token[] memory ts = parseConfig();
    console2.log("token length: %s", vm.toString(ts.length));

    // deploy the contract
    uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    _dssDeploy();

    vm.stopBroadcast();
  }
}
