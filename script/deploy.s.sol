// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DSValue} from "ds-value/value.sol";
import {PipLike} from "../src/spot.sol";
import {Config} from "./config.sol";
import {GovActions} from "dss-deploy/govActions.sol";
import {DSPause} from "ds-pause/pause.sol";
import "dss-deploy/DssDeploy.sol";

interface IPip is PipLike {
  function poke(bytes32) external;
  // function peek() external returns (bytes32, bool);
}

contract ProxyActions {
  DSPause pause;
  GovActions govActions;

  function rely(address from, address to) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax = abi.encodeWithSignature("rely(address,address)", from, to);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function deny(address from, address to) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax = abi.encodeWithSignature("deny(address,address)", from, to);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function file(address who, bytes32 what, uint data) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax = abi.encodeWithSignature("file(address,bytes32,uint256)", who, what, data);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function file(address who, bytes32 ilk, bytes32 what, uint data) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax =
      abi.encodeWithSignature("file(address,bytes32,bytes32,uint256)", who, ilk, what, data);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function dripAndFile(address who, bytes32 what, uint data) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax =
      abi.encodeWithSignature("dripAndFile(address,bytes32,uint256)", who, what, data);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function dripAndFile(address who, bytes32 ilk, bytes32 what, uint data) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax =
      abi.encodeWithSignature("dripAndFile(address,bytes32,bytes32,uint256)", who, ilk, what, data);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function cage(address end) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax = abi.encodeWithSignature("cage(address)", end);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function setAuthority(address newAuthority) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax = abi.encodeWithSignature("setAuthority(address,address)", pause, newAuthority);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function setDelay(uint newDelay) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax = abi.encodeWithSignature("setDelay(address,uint256)", pause, newDelay);
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }

  function setAuthorityAndDelay(address newAuthority, uint newDelay) external {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    bytes memory fax = abi.encodeWithSignature(
      "setAuthorityAndDelay(address,address,uint256)", pause, newAuthority, newDelay
    );
    uint eta = block.timestamp;

    pause.plot(usr, tag, fax, eta);
    pause.exec(usr, tag, fax, eta);
  }
}

contract DeploySrcipt is Config, ProxyActions {
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
    // govActions = new GovActions();

    dssDeploy = new DssDeploy();

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
    pause = dssDeploy.pause();
    // authority.permit(
    //   address(this), address(pause), bytes4(keccak256("plot(address,bytes32,bytes,uint256)"))
    // );
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
