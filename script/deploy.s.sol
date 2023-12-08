// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DSToken} from "ds-token/token.sol";
import {DSValue} from "ds-value/value.sol";
import {DSAuth, DSAuthority} from "ds-auth/auth.sol";
import {PipLike} from "../src/spot.sol";
import {Config} from "./config.sol";
import {DSPause} from "ds-pause/pause.sol";
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
import {Vat} from "src/vat.sol";
import {Jug} from "src/jug.sol";
import {Vow} from "src/vow.sol";
import {Cat} from "src/cat.sol";
import {Dog} from "src/dog.sol";
import {DaiJoin} from "src/join.sol";
import {Flapper} from "src/flap.sol";
import {Flopper} from "src/flop.sol";
import {Flipper} from "src/flip.sol";
import {Clipper} from "src/clip.sol";
import {LinearDecrease, StairstepExponentialDecrease, ExponentialDecrease} from "src/abaci.sol";
import {Dai} from "src/dai.sol";
import {Cure} from "src/cure.sol";
import {End} from "src/end.sol";
import {ESM} from "esm/ESM.sol";
import {Pot} from "src/pot.sol";
import {Spotter} from "src/spot.sol";

contract Authority is DSAuth, DSAuthority {
  mapping(address => mapping(address => mapping(bytes4 => bool))) acl;

  function canCall(address src, address dst, bytes4 sig) external view returns (bool) {
    return acl[src][dst][sig];
  }

  function permit(address src, address dst, bytes4 sig) public auth {
    acl[src][dst][sig] = true;
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

contract ProxyActions {
  DSPause public pause;
  GovActions public govActions;

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
  Vat public vat;
  Jug public jug;
  Vow public vow;
  Cat public cat;
  Dog public dog;
  Dai public dai;
  DaiJoin public daiJoin;
  Flapper public flap;
  Flopper public flop;
  Spotter public spotter;
  Pot public pot;
  Cure public cure;
  End public end;
  ESM public esm;

  struct Ilk {
    Flipper flip;
    Clipper clip;
    address join;
  }

  mapping(bytes32 => Ilk) public ilks;

  DSToken public gov;
  ProxyRegistry public registry;

  bytes32[] public tokenNames;
  mapping(bytes32 => Token) tokens;

  function createUser() public returns (address) {
    return address(new User(address(registry)));
  }

  function deployVat() public {
    require(address(vat) == address(0), "VAT already deployed");
    vat = new Vat();
    spotter = new Spotter(address(vat));

    // Internal auth
    vat.rely(address(spotter));
  }

  function deployDai(uint chainId) public {
    require(address(vat) != address(0), "Missing previous step");

    // Deploy
    dai = new Dai(chainId);
    daiJoin = new DaiJoin(address(vat), address(dai));
    dai.rely(address(daiJoin));
  }

  function deployTaxation() public {
    require(address(vat) != address(0), "Missing previous step");

    // Deploy
    jug = new Jug(address(vat));
    pot = new Pot(address(vat));

    // Internal auth
    vat.rely(address(jug));
    vat.rely(address(pot));
  }

  function deployAuctions(address gov_) public {
    require(gov_ != address(0), "Missing GOV address");
    require(address(jug) != address(0), "Missing previous step");

    // Deploy
    flap = new Flapper(address(vat), gov_);
    flop = new Flopper(address(vat), gov_);
    vow = new Vow(address(vat), address(flap), address(flop));

    // Internal references set up
    jug.file("vow", address(vow));
    pot.file("vow", address(vow));

    // Internal auth
    vat.rely(address(flop));
    flap.rely(address(vow));
    flop.rely(address(vow));
  }

  function deployLiquidator() public {
    require(address(vow) != address(0), "Missing previous step");

    // Deploy
    cat = new Cat(address(vat));
    dog = new Dog(address(vat));

    // Internal references set up
    cat.file("vow", address(vow));
    dog.file("vow", address(vow));

    // Internal auth
    vat.rely(address(cat));
    vat.rely(address(dog));
    vow.rely(address(cat));
    vow.rely(address(dog));
  }

  function deployEnd() public {
    require(address(cat) != address(0), "Missing previous step");

    // Deploy
    cure = new Cure();
    end = new End();

    // Internal references set up
    end.file("vat", address(vat));
    end.file("cat", address(cat));
    end.file("dog", address(dog));
    end.file("vow", address(vow));
    end.file("pot", address(pot));
    end.file("spot", address(spotter));
    end.file("cure", address(cure));

    // Internal auth
    vat.rely(address(end));
    cat.rely(address(end));
    dog.rely(address(end));
    vow.rely(address(end));
    pot.rely(address(end));
    spotter.rely(address(end));
    cure.rely(address(end));
  }

  function deployPause(uint delay, address authority) public {
    require(address(dai) != address(0), "Missing previous step");
    require(address(end) != address(0), "Missing previous step");

    pause = new DSPause(delay, address(0), DSAuthority(authority));

    vat.rely(address(pause.proxy()));
    cat.rely(address(pause.proxy()));
    dog.rely(address(pause.proxy()));
    vow.rely(address(pause.proxy()));
    jug.rely(address(pause.proxy()));
    pot.rely(address(pause.proxy()));
    spotter.rely(address(pause.proxy()));
    flap.rely(address(pause.proxy()));
    flop.rely(address(pause.proxy()));
    cure.rely(address(pause.proxy()));
    end.rely(address(pause.proxy()));
  }

  function deployESM(address gov_, uint min) public {
    require(address(pause) != address(0), "Missing previous step");

    // Deploy ESM
    esm = new ESM(gov_, address(end), address(pause.proxy()), min);
    end.rely(address(esm));
    vat.rely(address(esm));
  }

  function deployCollateralFlip(bytes32 ilk, address join, address pip) public {
    require(ilk != bytes32(""), "Missing ilk name");
    require(join != address(0), "Missing join address");
    require(pip != address(0), "Missing pip address");
    require(address(pause) != address(0), "Missing previous step");

    // Deploy
    ilks[ilk].flip = new Flipper(address(vat), address(cat), ilk);
    ilks[ilk].join = join;
    Spotter(spotter).file(ilk, "pip", address(pip)); // Set pip

    // Internal references set up
    cat.file(ilk, "flip", address(ilks[ilk].flip));
    vat.init(ilk);
    jug.init(ilk);

    // Internal auth
    vat.rely(join);
    cat.rely(address(ilks[ilk].flip));
    ilks[ilk].flip.rely(address(cat));
    ilks[ilk].flip.rely(address(end));
    ilks[ilk].flip.rely(address(esm));
    ilks[ilk].flip.rely(address(pause.proxy()));
  }

  function deployCollateralClip(bytes32 ilk, address join, address pip, address calc) public {
    require(ilk != bytes32(""), "Missing ilk name");
    require(join != address(0), "Missing join address");
    require(pip != address(0), "Missing pip address");
    require(address(pause) != address(0), "Missing previous step");

    // Deploy
    ilks[ilk].clip = new Clipper(address(vat), address(spotter), address(dog), ilk);
    ilks[ilk].join = join;
    Spotter(spotter).file(ilk, "pip", address(pip)); // Set pip

    // Internal references set up
    dog.file(ilk, "clip", address(ilks[ilk].clip));
    ilks[ilk].clip.file("vow", address(vow));

    // Use calc with safe default if not configured
    if (calc == address(0)) {
      calc = address(new LinearDecrease());
      LinearDecrease(calc).file(bytes32("tau"), 1 hours);
    }
    ilks[ilk].clip.file("calc", calc);
    vat.init(ilk);
    jug.init(ilk);

    // Internal auth
    vat.rely(join);
    vat.rely(address(ilks[ilk].clip));
    dog.rely(address(ilks[ilk].clip));
    ilks[ilk].clip.rely(address(dog));
    ilks[ilk].clip.rely(address(end));
    ilks[ilk].clip.rely(address(esm));
    ilks[ilk].clip.rely(address(pause.proxy()));
  }

  function pauseAuth(address usr) public {
    Authority(address(pause.authority())).permit(
      usr, address(pause), bytes4(keccak256("plot(address,bytes32,bytes,uint256)"))
    );
  }

  function govAuth(address usr) public {
    Authority(address(gov.authority())).permit(
      usr, address(gov), bytes4(keccak256("mint(uint256)"))
    );
    Authority(address(gov.authority())).permit(
      usr, address(gov), bytes4(keccak256("burn(address,uint256)"))
    );
    Authority(address(gov.authority())).permit(
      usr, address(gov), bytes4(keccak256("mint(address,uint256)"))
    );
  }

  function authx() public view returns (Authority) {
    return Authority(address(pause.authority()));
  }

  function dssDeploy(uint chainId, uint minGov) public {
    gov = new DSToken("GOV");
    gov.setAuthority(DSAuthority(address(new Authority())));

    deployVat();
    deployDai(chainId);
    deployTaxation();
    deployAuctions(address(gov));
    deployLiquidator();
    deployEnd();
    deployPause(0, address(new Authority()));
    deployESM(address(gov), minGov);

    govActions = new GovActions();
    pauseAuth(address(this));
  }

  function releaseAuth() public {
    vat.deny(address(this));
    cat.deny(address(this));
    dog.deny(address(this));
    vow.deny(address(this));
    jug.deny(address(this));
    pot.deny(address(this));
    dai.deny(address(this));
    spotter.deny(address(this));
    flap.deny(address(this));
    flop.deny(address(this));
    cure.deny(address(this));
    end.deny(address(this));
  }

  function releaseAuthFlip(bytes32 ilk) public {
    ilks[ilk].flip.deny(address(this));
  }

  function releaseAuthClip(bytes32 ilk) public {
    ilks[ilk].clip.deny(address(this));
  }

  function run() public {
    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
    G memory g = parseConfig(json);
    initTokens(g.tokens);
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    uint chainId = vm.envUint("CHAIN_ID");

    vm.startBroadcast(deployer);
    // deploy the contract
    dssDeploy(chainId, WAD * g.global.esm_min);
    // set param
    setParam(g.global);
    // deploy testnet tokens
    deployTestnetTokens();
    // deploy ilks
    deployIlks();

    this.setDelay(1 hours);
    vm.stopBroadcast();

    console2.log("deployer", deployer);
    console2.log("pause", address(pause));
    console2.log("vat", address(vat));
    console2.log("daiJoin", address(daiJoin));
    console2.log("dai", address(dai));
    console2.log("daiJoin", address(daiJoin));
    console2.log("dog", address(dog));
    console2.log("flap", address(flap));
    console2.log("flop", address(flop));
    console2.log("jug", address(jug));
    console2.log("pot", address(pot));
    console2.log("spotter", address(spotter));
    console2.log("vow", address(vow));
    console2.log("end", address(end));
    console2.log("esm", address(esm));
    console2.log("gov", address(gov));
    console2.log("proxyRegistry", address(registry));
  }

  function initTokens(Token[] memory tokens_) public {
    tokenNames.push("WETH");
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

  uint constant TOKEN_SUPLY = 1e9 ether;
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;
  uint constant RAD = 10 ** 45;
  uint constant PENCENT_DIVIDER = 10000;

  function deployTestnetTokens() public {
    for (uint i = 0; i < tokenNames.length; i++) {
      bytes32 symbol = tokenNames[i];
      DSValue pip = new DSValue();
      if (symbol == "WETH") {
        tokens[symbol].importx.gem = address(new WETH9_());
        pip.poke(bytes32(uint(2200 ether)));
      } else if (symbol == "BAT") {
        tokens[symbol].importx.gem = address(new BAT(TOKEN_SUPLY));
        pip.poke(bytes32(uint(2 ether)));
      } else if (symbol == "WBTC") {
        tokens[symbol].importx.gem = address(new WBTC(TOKEN_SUPLY));
        pip.poke(bytes32(uint(44000 ether)));
      } else if (symbol == "LINK") {
        tokens[symbol].importx.gem = address(new LINK(TOKEN_SUPLY));
        pip.poke(bytes32(uint(15 ether)));
      } else if (symbol == "AAVE") {
        tokens[symbol].importx.gem = address(new AAVE(TOKEN_SUPLY));
        pip.poke(bytes32(uint(100 ether)));
      } else if (symbol == "USDC") {
        tokens[symbol].importx.gem = address(new USDC(TOKEN_SUPLY));
        pip.poke(bytes32(uint(1 ether)));
      } else if (symbol == "USDT") {
        tokens[symbol].importx.gem = address(new USDT(TOKEN_SUPLY));
        pip.poke(bytes32(uint(1 ether)));
      } else if (symbol == "UNI") {
        tokens[symbol].importx.gem = address(new UNI(TOKEN_SUPLY));
        pip.poke(bytes32(uint(16 ether)));
      } else if (symbol == "MATIC") {
        tokens[symbol].importx.gem = address(new MATIC(TOKEN_SUPLY));
        pip.poke(bytes32(uint(54 ether)));
      } else if (symbol == "ZRX") {
        tokens[symbol].importx.gem = address(new ZRX(TOKEN_SUPLY));
        pip.poke(bytes32(uint(25 ether)));
      }
      tokens[symbol].importx.pip = address(pip);
    }
  }

  function deployIlks() public {
    require(address(vat) != address(0), "vat must deployed before do this");
    for (uint i = 0; i < tokenNames.length; i++) {
      bytes32 tname = tokenNames[i];
      Token memory token = tokens[tname];
      for (uint j = 0; j < token.ilks.length; j++) {
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
        StairstepExponentialDecrease calc = new StairstepExponentialDecrease();
        // calc.file(bytes32("tau"), 1 hours);
        calc.file(bytes32("cut"), RAY * ilkx.clipDeploy.calc.cut);
        calc.file(bytes32("step"), ilkx.clipDeploy.calc.step);
        deployCollateralClip(iname, join, token.importx.pip, address(calc));

        // set ilk
        Ilk memory ilk = ilks[iname];
        // vat
        this.file(address(vat), iname, bytes32("line"), RAD * ilkx.line);
        this.file(address(vat), iname, bytes32("dust"), RAD * ilkx.dust);
        // jug
        this.file(address(jug), iname, bytes32("duty"), RAY * ilkx.duty / PENCENT_DIVIDER);
        // spotter
        this.file(address(spotter), iname, bytes32("mat"), RAY * ilkx.mat / PENCENT_DIVIDER);
        // dog
        this.file(address(dog), iname, bytes32("hole"), RAD * ilkx.clipDeploy.hole);
        this.file(address(dog), iname, bytes32("chop"), WAD * ilkx.clipDeploy.chop);
        // clip
        this.file(address(ilk.clip), bytes32("buf"), RAY * ilkx.clipDeploy.buf / PENCENT_DIVIDER);
        this.file(address(ilk.clip), bytes32("tail"), ilkx.clipDeploy.tail);
        this.file(address(ilk.clip), bytes32("cusp"), RAY * ilkx.clipDeploy.cusp);
        this.file(address(ilk.clip), bytes32("chip"), WAD * ilkx.clipDeploy.chip / PENCENT_DIVIDER);
        this.file(address(ilk.clip), bytes32("tip"), RAY * ilkx.clipDeploy.tip);
      }
    }
  }

  function setParam(Global memory g) public {
    // vat
    this.file(address(vat), bytes32("Line"), RAD * g.vat_line);
    // dog
    this.file(address(dog), bytes32("Hole"), RAD * g.dog_hole);
    // cure
    this.file(address(cure), bytes32("wait"), RAD * g.cure_wait);
    // end
    this.file(address(end), bytes32("wait"), g.end_wait);
    // flap
    this.file(address(flap), bytes32("beg"), WAD * g.flap_beg / PENCENT_DIVIDER);
    this.file(address(flap), bytes32("ttl"), g.flap_ttl);
    this.file(address(flap), bytes32("tau"), g.flap_tau);
    this.file(address(flap), bytes32("lid"), RAD * g.flap_lid);
    // flop
    this.file(address(flop), bytes32("beg"), WAD * g.flop_beg / PENCENT_DIVIDER);
    this.file(address(flop), bytes32("ttl"), g.flop_ttl);
    this.file(address(flop), bytes32("tau"), g.flop_tau);
    this.file(address(flop), bytes32("pad"), WAD * g.flop_pad / PENCENT_DIVIDER);
    // jug
    this.file(address(jug), bytes32("base"), RAY * g.jug_base / PENCENT_DIVIDER);
    // pot
    this.file(address(pot), bytes32("dsr"), RAY * g.pot_dsr / PENCENT_DIVIDER);
    // vow
    this.file(address(vow), bytes32("wait"), g.vow_wait);
    this.file(address(vow), bytes32("dump"), WAD * g.vow_dump);
    this.file(address(vow), bytes32("sump"), RAD * g.vow_sump);
    this.file(address(vow), bytes32("bump"), RAD * g.vow_bump);
    this.file(address(vow), bytes32("hump"), RAD * g.vow_hump);
  }
}

contract Deploy is Script {
  function run() public payable {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    uint chainId = vm.envUint("CHAIN_ID");

    vm.broadcast(deployer);
    DeploySrcipt script = new DeploySrcipt();

    script.run();

    console2.log("deployer", deployer);
    console2.log("pause", address(script.pause()));
    console2.log("vat", address(script.vat()));
    console2.log("daiJoin", address(script.daiJoin()));
    console2.log("dai", address(script.dai()));
    console2.log("daiJoin", address(script.daiJoin()));
    console2.log("dog", address(script.dog()));
    console2.log("flap", address(script.flap()));
    console2.log("flop", address(script.flop()));
    console2.log("jug", address(script.jug()));
    console2.log("pot", address(script.pot()));
    console2.log("spotter", address(script.spotter()));
    console2.log("vow", address(script.vow()));
    console2.log("end", address(script.end()));
    console2.log("esm", address(script.esm()));
    console2.log("gov", address(script.gov()));
    console2.log("proxyRegistry", address(script.registry()));
  }
}

/*
contract MyTest is Script {
  function run() public payable {
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    DSToken token = new DSToken("DST");
    vm.startBroadcast(deployer);
    WETH9_ weth = new WETH9_();

    vm.stopBroadcast();
  }
}
*/
