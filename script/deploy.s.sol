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
import "dss-deploy/DssDeploy.sol";
import {ProxyActions, MockGuard} from "dss-deploy/DssDeploy.t.base.sol";
import {GovActions} from "dss-deploy/govActions.sol";
import {ProxyCalls} from "dss-proxy-actions/DssProxyActions.t.sol";
import {
  DssProxyActions,
  DssProxyActionsEnd,
  DssProxyActionsDsr
} from "dss-proxy-actions/DssProxyActions.sol";
import {ProxyRegistry, DSProxyFactory, DSProxy} from "proxy-registry/ProxyRegistry.sol";

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
  Authority public authx;
  DSToken public gov;
  GovActions public govActions;

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
    authx = new Authority();
    gov = new DSToken("GOV");
    gov.setAuthority(DSAuthority(address(new MockGuard())));
  }

  function pauseAuth() public auth {
    authx.permit(
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

  function dssDeploy(uint chainId) public {
    deployVat();
    deployDai(chainId);
    deployTaxation();
    deployAuctions(address(gov));
    deployLiquidator();
    deployEnd();
    deployPause(0, address(authx));
    deployESM(address(gov), 10);

    admin = new Admin(address(pause), address(govActions));
    authx.permit(
      address(admin), address(pause), bytes4(keccak256("plot(address,bytes32,bytes,uint256)"))
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
