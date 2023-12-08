// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DSToken} from "ds-token/token.sol";
import {DSValue} from "ds-value/value.sol";
import {DSAuth, DSAuthority} from "ds-auth/auth.sol";
import {PipLike} from "../src/spot.sol";
import {Config} from "./config.sol";
import {GovActions} from "dss-deploy/govActions.sol";
import {DSPause} from "ds-pause/pause.sol";
import {ProxyActions, MockGuard} from "dss-deploy/DssDeploy.t.base.sol";
import {GovActions} from "dss-deploy/govActions.sol";
import {ProxyCalls} from "dss-proxy-actions/DssProxyActions.t.sol";
import {
  DssProxyActions,
  DssProxyActionsEnd,
  DssProxyActionsDsr
} from "dss-proxy-actions/DssProxyActions.sol";
import {ProxyRegistry, DSProxyFactory, DSProxy} from "proxy-registry/ProxyRegistry.sol";
import {WETH9_} from "ds-weth/weth9.sol";
import {BAT} from "dss-gem-joins/tokens/BAT.sol";
import {WBTC} from "dss-gem-joins/tokens/WBTC.sol";
import {USDC} from "dss-gem-joins/tokens/USDC.sol";
import {USDT} from "dss-gem-joins/tokens/USDT.sol";
import {LINK} from "dss-gem-joins/tokens/LINK.sol";
import {MATIC} from "dss-gem-joins/tokens/MATIC.sol";
import {ZRX} from "dss-gem-joins/tokens/ZRX.sol";
import {AAVE} from "dss-gem-joins/tokens/AAVE.sol";
import {UNI} from "dss-gem-joins/tokens/UNI.sol";
import {GemJoin5} from "dss-gem-joins/join-5.sol";
import {GemJoin7} from "dss-gem-joins/join-7.sol";
import {GemJoin} from "../src/join.sol";
import {StairstepExponentialDecrease} from "../src/abaci.sol";
import "dss-deploy/DssDeploy.sol";

contract Authority is DSAuth, DSAuthority {
  MockGuard internal mg;

  constructor() {
    mg = new MockGuard();
  }

  function canCall(address src, address dst, bytes4 sig) external view returns (bool) {
    return mg.canCall(src, dst, sig);
  }

  function permit(address src, address dst, bytes4 sig) public auth {
    return mg.permit(src, dst, sig);
  }
}

contract Admin is ProxyActions {
  constructor(address pause_, address govActions_) {
    govActions = GovActions(govActions_);
    pause = DSPause(pause_);
  }
}

contract User is ProxyCalls {
  constructor(address proxyRegistry_) {
    dssProxyActions = address(new DssProxyActions());
    dssProxyActionsEnd = address(new DssProxyActionsEnd());
    dssProxyActionsDsr = address(new DssProxyActionsDsr());
    ProxyRegistry registry = ProxyRegistry(proxyRegistry_);
    proxy = DSProxy(registry.build());
  }
}

contract DeploySrcipt is Config, DssDeploy {
  ProxyRegistry registry;
  Admin admin;
  DSToken public gov;
  GovActions public govActions;
  bytes32[] public tokenNames;
  mapping(bytes32 => Token) tokens;

  function createUser() public returns (address) {
    return address(new User(address(registry)));
  }

  function setUp() public {
    vatFab = new VatFab();
    jugFab = new JugFab();
    vowFab = new VowFab();
    catFab = new CatFab();
    dogFab = new DogFab();
    daiFab = new DaiFab();
    daiJoinFab = new DaiJoinFab();
    flapFab = new FlapFab();
    flopFab = new FlopFab();
    flipFab = new FlipFab();
    clipFab = new ClipFab();
    calcFab = new CalcFab();
    spotFab = new SpotFab();
    potFab = new PotFab();
    cureFab = new CureFab();
    endFab = new EndFab();
    esmFab = new ESMFab();
    pauseFab = new PauseFab();

    govActions = new GovActions();
    registry = new ProxyRegistry(address(new DSProxyFactory()));
    gov = new DSToken("GOV");
    gov.setAuthority(DSAuthority(address(new MockGuard())));
  }

  function pauseAuth() public auth {
    Authority(address(pause.authority())).permit(
      msg.sender, address(pause), bytes4(keccak256("plot(address,bytes32,bytes,uint256)"))
    );
  }

  function govAuth() public auth {
    MockGuard(address(gov.authority())).permit(
      msg.sender, address(gov), bytes4(keccak256("mint(uint256)"))
    );
    MockGuard(address(gov.authority())).permit(
      msg.sender, address(gov), bytes4(keccak256("mint(address,uint256)"))
    );
  }

  function authx() public view returns (Authority) {
    return Authority(address(pause.authority()));
  }

  function dssDeploy(uint chainId) public {
    deployVat();
    deployDai(chainId);
    deployTaxation();
    deployAuctions(address(gov));
    deployLiquidator();
    deployEnd();
    deployPause(0, address(new Authority()));
    deployESM(address(gov), 10);

    admin = new Admin(address(pause), address(govActions));
    Authority(address(pause.authority())).permit(
      address(this), address(pause), bytes4(keccak256("plot(address,bytes32,bytes,uint256)"))
    );
  }

  function run() public {
    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
    G memory g = parseConfig(json);
    console2.log("g.golbal.vat_line", g.global.vat_line);
    // console2.log("g.import.gov", g.importx.gov);
    // console2.log("g.tokens.length", g.tokens.length);

    uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    uint chianId = vm.envUint("CHAIN_ID");

    vm.startBroadcast(deployerPrivateKey);

    // deploy the contract
    setUp();
    dssDeploy(chianId);
    releaseAuth();

    vm.stopBroadcast();
  }

  function setGlobalConfig(Global memory g) public {}

  function initTokens(Token[] memory tokens_) public {
    tokenNames.push("ETH");
    tokenNames.push("BAT");
    tokenNames.push("WBTC");
    tokenNames.push("LINK");
    tokenNames.push("AAVE");
    tokenNames.push("USDC");
    tokenNames.push("USDT");
    tokenNames.push("UNI");
    tokenNames.push("MATIC");
    tokenNames.push("ZRX");

    for (uint i = 0; i < tokenNames.length; i++) {
      Token storage tokenx = tokens[tokenNames[i]];
      for (uint j = 0; j < tokens_.length; j++) {
        Token memory token = tokens_[j];
        if (tokenNames[i] == bytes32(bytes(tokens_[j].name))) {
          for (uint k = 0; k < token.ilks.length; k++) {
            Ilkx memory ilkx = token.ilks[k];
            tokenx.ilks.push(ilkx);
          }
          tokenx.importx = token.importx;
          tokenx.name = token.name;
          // tokenx.joinDeploy = token.joinDeploy;
        }
      }
    }
  }

  function initIlks() public {}

  uint constant TOKEN_SUPLY = 1e10 ether;
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;
  uint constant RAD = 10 ** 45;

  function deployTestnetTokens() public {
    for (uint i = 0; i < tokenNames.length; i++) {
      bytes32 symbol = tokenNames[i];
      tokens[symbol].importx.pip = address(new DSValue());
      if (symbol == "ETH") {
        tokens[symbol].importx.gem = address(new WETH9_());
      } else if (symbol == "BAT") {
        tokens[symbol].importx.gem = address(new BAT(TOKEN_SUPLY));
      } else if (symbol == "WBTC") {
        tokens[symbol].importx.gem = address(new WBTC(TOKEN_SUPLY));
      } else if (symbol == "LINK") {
        tokens[symbol].importx.gem = address(new LINK(TOKEN_SUPLY));
      } else if (symbol == "AAVE") {
        tokens[symbol].importx.gem = address(new AAVE(TOKEN_SUPLY));
      } else if (symbol == "USDC") {
        tokens[symbol].importx.gem = address(new USDC(TOKEN_SUPLY));
      } else if (symbol == "USDT") {
        tokens[symbol].importx.gem = address(new USDT(TOKEN_SUPLY));
      } else if (symbol == "UNI") {
        tokens[symbol].importx.gem = address(new UNI(TOKEN_SUPLY));
      } else if (symbol == "MATIC") {
        tokens[symbol].importx.gem = address(new MATIC(TOKEN_SUPLY));
      } else if (symbol == "ZRX") {
        tokens[symbol].importx.gem = address(new ZRX(TOKEN_SUPLY));
      }
    }
  }

  function deployIlks() public {
    require(address(vat) != address(0), "vat must deployed before do this");
    for (uint i = 0; i < tokenNames.length; i++) {
      bytes32 tname = tokenNames[i];
      Token memory token = tokens[tname];
      for (uint j = 0; i < token.ilks.length; j++) {
        Ilkx memory ilkx = token.ilks[j];
        bytes32 iname = bytes32(bytes(abi.encodePacked(token.name, "-", ilkx.name)));
        address join;
        if (tname == "WBTC" || tname == "USDC") {
          join = address(new GemJoin5(address(vat), iname, token.importx.gem));
        } else if (tname == "USDT") {
          join = address(new GemJoin7(address(vat), iname, token.importx.gem));
        } else {
          join = address(new GemJoin(address(vat), iname, token.importx.gem));
        }
        StairstepExponentialDecrease calc = calcFab.newStairstepExponentialDecrease(address(this));
        calc.file(bytes32("tau"), 1 hours);
        calc.file(bytes32("cut"), RAY * ilkx.clipDeploy.calc.cut);
        calc.file(bytes32("step"), ilkx.clipDeploy.calc.step);
        deployCollateralClip(iname, join, token.importx.pip, address(calc));

        // set ilk
        Ilk memory ilk = ilks[iname];
        // vat
        admin.file(address(vat), iname, bytes32("line"), RAD * ilkx.line);
        admin.file(address(vat), iname, bytes32("dust"), RAD * ilkx.dust);
        // jug
        admin.file(address(jug), iname, bytes32("duty"), RAY * ilkx.duty);
        // spotter
        admin.file(address(spotter), iname, bytes32("mat"), RAY * ilkx.mat);
        // dog
        admin.file(address(dog), iname, bytes32("hole"), RAD * ilkx.clipDeploy.hole);
        admin.file(address(dog), iname, bytes32("chop"), WAD * ilkx.clipDeploy.chop);
        // clip
        admin.file(address(ilk.clip), iname, bytes32("buf"), RAY * ilkx.clipDeploy.buf);
        admin.file(address(ilk.clip), iname, bytes32("tail"), ilkx.clipDeploy.tail);
        admin.file(address(ilk.clip), iname, bytes32("cusp"), RAY * ilkx.clipDeploy.cusp);
        admin.file(address(ilk.clip), iname, bytes32("chip"), WAD * ilkx.clipDeploy.chip);
        admin.file(address(ilk.clip), iname, bytes32("tip"), RAY * ilkx.clipDeploy.tip);
      }
    }
  }

  function setParam(Global memory g) public {
    // vat
    admin.file(address(vat), bytes32("Line"), RAD * g.vat_line);
    // dog
    admin.file(address(dog), bytes32("Hole"), RAD * g.dog_hole);
    // cure
    admin.file(address(cure), bytes32("wait"), RAD * g.cure_wait);
    // end
    admin.file(address(end), bytes32("wait"), g.end_wait);
    // esm
    admin.file(address(esm), bytes32("min"), WAD * g.esm_min);
    // flap
    admin.file(address(flap), bytes32("beg"), WAD * g.flap_beg);
    admin.file(address(flap), bytes32("ttl"), g.flap_ttl);
    admin.file(address(flap), bytes32("tau"), g.flap_tau);
    admin.file(address(flap), bytes32("lid"), RAD * g.flap_lid);
    // flop
    admin.file(address(flop), bytes32("beg"), WAD * g.flop_beg);
    admin.file(address(flop), bytes32("ttl"), g.flop_ttl);
    admin.file(address(flop), bytes32("tau"), g.flop_tau);
    admin.file(address(flop), bytes32("pad"), WAD * g.flop_pad);
    // jug
    admin.file(address(jug), bytes32("base"), RAY * g.jug_base);
    // pot
    admin.file(address(pot), bytes32("dsr"), RAY * g.pot_dsr);
    // vow
    admin.file(address(vow), bytes32("wait"), g.vow_wait);
    admin.file(address(vow), bytes32("dump"), WAD * g.vow_dump);
    admin.file(address(vow), bytes32("sump"), RAD * g.vow_sump);
    admin.file(address(vow), bytes32("bump"), RAD * g.vow_bump);
    admin.file(address(vow), bytes32("hump"), RAD * g.vow_hump);
    // pause
    admin.file(address(pause), bytes32("delay"), g.pauseDelay);
  }
}
