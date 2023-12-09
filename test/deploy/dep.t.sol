// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "script/deploy.s.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";
import {GemJoin} from "../../src/join.sol";
import {FakeUser} from "dss-deploy/DssDeploy.t.base.sol";
import {LinearDecrease} from "../../src/abaci.sol";

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

contract WETH is DSToken("WETH") {}

contract DeployBase is Test, ProxyActions {
  DeploySrcipt public dssDeploy;
  WETH weth;
  GemJoin ethJoin;
  GemJoin colJoin;
  GemJoin col2Join;

  DSToken gov;
  DSValue pipETH;
  DSValue pipCOL;
  DSValue pipCOL2;

  Vat vat;
  Jug jug;
  Vow vow;
  Cat cat;
  Dog dog;
  Flapper flap;
  Flopper flop;
  Dai dai;
  DaiJoin daiJoin;
  Spotter spotter;
  Pot pot;
  Cure cure;
  End end;
  ESM esm;

  Flipper ethFlip;

  DSToken col;
  DSToken col2;
  Flipper colFlip;
  Clipper col2Clip;

  FakeUser user1;
  FakeUser user2;

  Vm hevm;

  // --- Math ---
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;
  uint constant RAD = 10 ** 45;

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
  }

  function rad(uint wad) internal pure returns (uint) {
    return wad * 10 ** 27;
  }

  function setUp() public virtual {
    dssDeploy = new DeploySrcipt();
    pipETH = new DSValue();
    pipCOL = new DSValue();
    pipCOL2 = new DSValue();
    user1 = new FakeUser();
    user2 = new FakeUser();
    hevm = vm;
  }

  function _dssDeploy() internal {
    dssDeploy.dssDeploy(99, 10);
    vat = dssDeploy.vat();
    jug = dssDeploy.jug();
    vow = dssDeploy.vow();
    cat = dssDeploy.cat();
    dog = dssDeploy.dog();
    flap = dssDeploy.flap();
    flop = dssDeploy.flop();
    dai = dssDeploy.dai();
    daiJoin = dssDeploy.daiJoin();
    spotter = dssDeploy.spotter();
    pot = dssDeploy.pot();
    cure = dssDeploy.cure();
    end = dssDeploy.end();
    esm = dssDeploy.esm();

    gov = dssDeploy.gov();
    pause = dssDeploy.admin().pause();
    authority = dssDeploy.authx();
    govActions = dssDeploy.admin().govActions();

    dssDeploy.govAuth(address(this));
    dssDeploy.pauseAuth(address(this));
    // dssDeploy.initTokens();
    // dssDeploy.deployTestnetTokens();
  }

  function deployKeepAuth() public {
    _dssDeploy();
    weth = new WETH();
    ethJoin = new GemJoin(address(vat), "ETH", address(weth));
    dssDeploy.deployCollateralFlip("ETH", address(ethJoin), address(pipETH));

    col = new DSToken("COL");
    colJoin = new GemJoin(address(vat), "COL", address(col));
    dssDeploy.deployCollateralFlip("COL", address(colJoin), address(pipCOL));

    col2 = new DSToken("COL2");
    col2Join = new GemJoin(address(vat), "COL2", address(col2));

    dssDeploy.deployCollateralClip("COL2", address(col2Join), address(pipCOL2), address(0));

    // Set Params
    this.file(address(vat), bytes32("Line"), uint(10000 * 10 ** 45));
    this.file(address(vat), bytes32("ETH"), bytes32("line"), uint(10000 * 10 ** 45));
    this.file(address(vat), bytes32("COL"), bytes32("line"), uint(10000 * 10 ** 45));
    this.file(address(vat), bytes32("COL2"), bytes32("line"), uint(10000 * 10 ** 45));

    pipETH.poke(bytes32(uint(300 * 10 ** 18))); // Price 300 DAI = 1 ETH (precision 18)
    pipCOL.poke(bytes32(uint(45 * 10 ** 18))); // Price 45 DAI = 1 COL (precision 18)
    pipCOL2.poke(bytes32(uint(30 * 10 ** 18))); // Price 30 DAI = 1 COL2 (precision 18)
    (ethFlip,,) = dssDeploy.ilks("ETH");
    (colFlip,,) = dssDeploy.ilks("COL");
    (, col2Clip,) = dssDeploy.ilks("COL2");
    this.file(address(spotter), "ETH", "mat", uint(1500000000 ether)); // Liquidation ratio 150%
    this.file(address(spotter), "COL", "mat", uint(1100000000 ether)); // Liquidation ratio 110%
    this.file(address(spotter), "COL2", "mat", uint(1500000000 ether)); // Liquidation ratio 150%
    spotter.poke("ETH");
    spotter.poke("COL");
    spotter.poke("COL2");
    (,, uint spot,,) = vat.ilks("ETH");
    assertEq(spot, 300 * RAY * RAY / 1500000000 ether);
    (,, spot,,) = vat.ilks("COL");
    assertEq(spot, 45 * RAY * RAY / 1100000000 ether);
    (,, spot,,) = vat.ilks("COL2");
    assertEq(spot, 30 * RAY * RAY / 1500000000 ether);

    dssDeploy.govAuth(address(flap));
    dssDeploy.govAuth(address(flop));

    gov.mint(10000 ether);
  }

  function deploy() public {
    deployKeepAuth();
    dssDeploy.releaseAuth();
  }
}
