// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DSValue} from "ds-value/value.sol";
import {DSAuth} from "ds-auth/auth.sol";
import {PipLike} from "../src/spot.sol";
import {Config} from "./config.sol";
import {GovActions} from "dss-deploy/govActions.sol";
import {DSPause} from "ds-pause/pause.sol";
import "dss-deploy/DssDeploy.sol";
import {ProxyActions, MockGuard} from "dss-deploy/DssDeploy.t.base.sol";
import {GovActions} from "dss-deploy/govActions.sol";
import {ProxyCalls} from "dss-proxy-actions/DssProxyActions.t.sol";
import {ProxyRegistry, DSProxyFactory, DSProxy} from "proxy-registry/ProxyRegistry.sol";

contract Authority is MockGuard, DSAuth {
  function permit(address src, address dst, bytes4 sig) public auth {
    return super.permit(src, dst, sig);
  }
}

contract DssDeployTestBase is DSTest, ProxyActions {
  Hevm hevm;

  VatFab vatFab;
  JugFab jugFab;
  VowFab vowFab;
  CatFab catFab;
  DogFab dogFab;
  DaiFab daiFab;
  DaiJoinFab daiJoinFab;
  FlapFab flapFab;
  FlopFab flopFab;
  FlipFab flipFab;
  ClipFab clipFab;
  CalcFab calcFab;
  SpotFab spotFab;
  PotFab potFab;
  CureFab cureFab;
  EndFab endFab;
  ESMFab esmFab;
  PauseFab pauseFab;

  DssDeploy dssDeploy;

  DSToken gov;
  DSValue pipETH;
  DSValue pipCOL;
  DSValue pipCOL2;
}

contract Admin is ProxyActions {
  constructor(address pause_) {
    govActions = new GovActions();
    pause = DSPause(pause_);
  }
}

contract User is ProxyCalls {
  constructor(address proxyRegistry_) {
    dssProxyActions = address(new DssProxyActions());
    dssProxyActionsEnd = address(new DssProxyActionsEnd());
    dssProxyActionsDsr = address(new DssProxyActionsDsr());
    ProxyRegistry registry = ProxyRegistry(prxoxyRegistry_);
    proxy = DSProxy(registry.build());
  }
}

contract DeploySrcipt is Config, ProxyActions, ProxyCalls {
  uint constant ONE = 10 ** 18;
  VatFab vatFab;
  JugFab jugFab;
  VowFab vowFab;
  CatFab catFab;
  DogFab dogFab;
  DaiFab daiFab;
  DaiJoinFab daiJoinFab;
  FlapFab flapFab;
  FlopFab flopFab;
  FlipFab flipFab;
  ClipFab clipFab;
  CalcFab calcFab;
  SpotFab spotFab;
  PotFab potFab;
  CureFab cureFab;
  EndFab endFab;
  ESMFab esmFab;
  PauseFab pauseFab;

  DssDeploy dssDeploy;

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

  ProxyRegistry registry;
  Authority authority;
  Admin admin;

  function createUser() public returns (address) {
    return address(new User(address(registry)));
  }

  function _setup() internal {
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
    dssDeploy = new DssDeploy();
    proxyRegistry = new ProxyRegistry(address(new proxyFactory()));
    authority = new Authority();

    dssDeploy.addFabs1(vatFab, jugFab, vowFab, catFab, dogFab, daiFab, daiJoinFab);
    dssDeploy.addFabs2(
      flapFab,
      flopFab,
      flipFab,
      clipFab,
      calcFab,
      spotFab,
      potFab,
      cureFab,
      endFab,
      esmFab,
      pauseFab
    );
  }

  function _dssDeploy(uint chainId) internal {
    dssDeploy.deployVat();
    dssDeploy.deployDai(chainId);
    dssDeploy.deployTaxation();
    dssDeploy.deployAuctions(address(gov));
    dssDeploy.deployLiquidator();
    dssDeploy.deployEnd();
    dssDeploy.deployPause(0, address(authority));
    dssDeploy.deployESM(address(gov), 10);

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

    DSPause pause = dssDeploy.pause();
    admin = new Admin(address(pause));
    authority.permit(
      address(admin), address(pause), bytes4(keccak256("plot(address,bytes32,bytes,uint256)"))
    );
  }

  function run() public {
    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
    G memory g = parseConfig(json);
    // console2.log("g.golbal.vat_line", g.global.vat_line);
    // console2.log("g.import.gov", g.importx.gov);
    // console2.log("g.tokens.length", g.tokens.length);

    uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    uint chianId = vm.envUint("CHAIN_ID");

    vm.startBroadcast(deployerPrivateKey);

    // deploy the contract
    _setup();
    _dssDeploy(chianId);

    vm.stopBroadcast();
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
}
