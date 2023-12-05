// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "script/deploy.s.sol";

contract DeployScriptTest is Test {
  DeploySrcipt public deploy;
  string json;

  function setUp() public {
    deploy = new DeploySrcipt();
    json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
  }

  function testDeploy() public {}

  function testParseGlobalConfig() public {
    Config.Global memory global = deploy.parseGlobal(json);
    assertEq(global.vat_line, 778000000, "vat_line");
  }

  function testParseImportConfig() public {
    Config.ImportG memory importx = deploy.parseImport(json);
    assertEq(importx.gov, 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2, "gov");
  }

  function testParseTokenConfig() public {
    /// @dev TODO: fix this test: Stack too deep, why?
    // Config.RawToken[] memory tokens = deploy.parseRawTokens(json, 1);
    // assertEq(tokens.length, 35, "tokens.length");
  }
}
