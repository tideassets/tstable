// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/StdJson.sol";
import "../script/deploy.s.sol";

contract DeployScriptTest is Test {
  using stdJson for string;

  DeploySrcipt public deploy;

  function setUp() public {
    deploy = new DeploySrcipt();
  }

  function testDeploy() public {}

  function testParseConfig() public {
    // ConfigInfo.Token[] memory tokens = deploy.parseConfig();
    // assertEq(tokens.length, 35, "tokens length should be 35");
  }
}
