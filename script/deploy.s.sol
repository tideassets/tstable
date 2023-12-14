// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DSToken} from "ds-token/token.sol";
import {DSValue} from "ds-value/value.sol";
import {DSAuth, DSAuthority} from "ds-auth/auth.sol";
import {PipLike} from "../src/spot.sol";
import {Config} from "./config.sol";
import {DSPause} from "ds-pause/pause.sol";
import {GovActions} from "dss-deploy/govActions.sol";
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
import {Clipper, AbacusLike} from "src/clip.sol";
import {LinearDecrease, StairstepExponentialDecrease, ExponentialDecrease} from "src/abaci.sol";
import {Dai} from "src/dai.sol";
import {Cure} from "src/cure.sol";
import {End} from "src/end.sol";
import {ESM} from "esm/ESM.sol";
import {Pot} from "src/pot.sol";
import {Spotter} from "src/spot.sol";
import {Authority, Admin} from "./admin.sol";

contract DeployScript is Config {
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
    address pip;
    address calc;
  }

  mapping(bytes32 => Ilk) public ilks;

  DSPause public pause;

  DSToken public gov;
  ProxyRegistry public registry;

  bytes32[] public tokenNames;
  mapping(bytes32 => Token) tokens;

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

    ilks[ilk].pip = pip;
    ilks[ilk].calc = calc;

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
    // gov token
    gov = new DSToken("GOV");
    gov.setAuthority(DSAuthority(address(new Authority())));

    // dss contracts and pause and esm
    deployVat();
    deployDai(chainId);
    deployTaxation();
    deployAuctions(address(gov));
    deployLiquidator();
    deployEnd();
    Authority au = new Authority();
    deployPause(0, address(au));
    deployESM(address(gov), minGov);

    // set pause auth
    // this = new Admin(address(pause));
    // pauseAuth(address(this));

    // create registry
    registry = new ProxyRegistry(address(new DSProxyFactory()));
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

  function initTokens(Token[] memory tokens_) public {
    tokenNames.push("ETH");
    tokenNames.push("USDC");
    tokenNames.push("LINK");
    tokenNames.push("AAVE");
    tokenNames.push("WBTC");
    tokenNames.push("BAT");
    tokenNames.push("USDT");
    tokenNames.push("UNI");
    tokenNames.push("MATIC");
    tokenNames.push("ZRX");

    for (uint i = 0; i < tokenNames.length; i++) {
      Token storage tokenx = tokens[tokenNames[i]];
      for (uint j = 0; j < tokens_.length; j++) {
        Token memory token = tokens_[j];
        if (tokenNames[i] == bytes32(bytes(token.name))) {
          for (uint k = 0; k < token.ilks.length; k++) {
            Ilkx memory ilkx = token.ilks[k];
            tokenx.ilks.push(ilkx);
          }
          tokenx.importx = token.importx;
          tokenx.name = token.name;
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
      Token storage tokenx = tokens[symbol];
      DSValue pip = new DSValue();
      if (symbol == "ETH") {
        tokenx.importx.gem = address(new WETH9_());
        pip.poke(bytes32(uint(2200 ether)));
      } else if (symbol == "BAT") {
        tokenx.importx.gem = address(new BAT(TOKEN_SUPLY));
        pip.poke(bytes32(uint(2 ether)));
      } else if (symbol == "WBTC") {
        tokenx.importx.gem = address(new WBTC(TOKEN_SUPLY));
        pip.poke(bytes32(uint(44000 ether)));
      } else if (symbol == "LINK") {
        tokenx.importx.gem = address(new LINK(TOKEN_SUPLY));
        pip.poke(bytes32(uint(15 ether)));
      } else if (symbol == "AAVE") {
        tokenx.importx.gem = address(new AAVE(TOKEN_SUPLY));
        pip.poke(bytes32(uint(100 ether)));
      } else if (symbol == "USDC") {
        tokenx.importx.gem = address(new USDC(TOKEN_SUPLY));
        pip.poke(bytes32(uint(1 ether)));
      } else if (symbol == "USDT") {
        tokenx.importx.gem = address(new USDT(TOKEN_SUPLY));
        pip.poke(bytes32(uint(1 ether)));
      } else if (symbol == "UNI") {
        tokenx.importx.gem = address(new UNI(TOKEN_SUPLY));
        pip.poke(bytes32(uint(16 ether)));
      } else if (symbol == "MATIC") {
        tokenx.importx.gem = address(new MATIC(TOKEN_SUPLY));
        pip.poke(bytes32(uint(54 ether)));
      } else if (symbol == "ZRX") {
        tokenx.importx.gem = address(new ZRX(TOKEN_SUPLY));
        pip.poke(bytes32(uint(25 ether)));
      } else {
        revert("no support");
      }
      tokenx.importx.pip = address(pip);
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
        deployCollateralClip(iname, join, token.importx.pip, address(calc));
        _setIlk(iname, ilkx);
      }
    }
  }

  function _setIlk(bytes32 iname, Ilkx memory ilkx) internal {
    // vat
    vat.file(iname, bytes32("line"), RAD * ilkx.line);
    vat.file(iname, bytes32("dust"), RAD * ilkx.dust);

    // get clip and calc
    (address aclip,,,) = dog.ilks(iname);
    Clipper clip = Clipper(aclip);
    StairstepExponentialDecrease calc = StairstepExponentialDecrease(address(clip.calc()));
    // calc
    calc.file(bytes32("cut"), RAY * ilkx.clipDeploy.calc.cut / PENCENT_DIVIDER);
    calc.file(bytes32("step"), ilkx.clipDeploy.calc.step);

    // // jug
    // uint duty = ilkx.duty * 60 * 60 * 24 * 365 * RAY / PENCENT_DIVIDER;
    // jug.file(iname, bytes32("duty"), duty);
    // spotter
    spotter.file(iname, bytes32("mat"), RAY * ilkx.mat / PENCENT_DIVIDER);
    // dog
    dog.file(iname, bytes32("hole"), RAD * ilkx.clipDeploy.hole);
    dog.file(
      iname, bytes32("chop"), WAD * (PENCENT_DIVIDER + ilkx.clipDeploy.chop) / PENCENT_DIVIDER
    );
    // clip
    clip.file(bytes32("buf"), RAY * ilkx.clipDeploy.buf / PENCENT_DIVIDER);
    clip.file(bytes32("tail"), ilkx.clipDeploy.tail);
    clip.file(bytes32("cusp"), RAY * ilkx.clipDeploy.cusp / PENCENT_DIVIDER);
    clip.file(bytes32("chip"), WAD * ilkx.clipDeploy.chip / PENCENT_DIVIDER);
    clip.file(bytes32("tip"), RAD * ilkx.clipDeploy.tip);
  }

  function _setIlks() internal {
    require(address(vat) != address(0), "vat must deployed before do this");
    for (uint i = 0; i < tokenNames.length; i++) {
      bytes32 tname = tokenNames[i];
      Token memory token = tokens[tname];
      for (uint j = 0; j < token.ilks.length; j++) {
        Ilkx memory ilkx = token.ilks[j];
        bytes32 iname = bytes32(bytes(abi.encodePacked(token.name, "-", ilkx.name)));
        _setIlk(iname, ilkx);
      }
    }
  }

  function _pokeIlks() internal {
    for (uint i = 0; i < tokenNames.length; i++) {
      bytes32 tname = tokenNames[i];
      Token memory token = tokens[tname];
      for (uint j = 0; j < token.ilks.length; j++) {
        Ilkx memory ilkx = token.ilks[j];
        bytes32 iname = bytes32(bytes(abi.encodePacked(token.name, "-", ilkx.name)));
        spotter.poke(iname);
      }
    }
  }

  function setParam(Global memory g) public {
    // vat
    vat.file(bytes32("Line"), RAD * g.vat_line);
    // dog
    dog.file(bytes32("Hole"), RAD * g.dog_hole);
    // cure
    cure.file(bytes32("wait"), g.cure_wait);
    // end
    end.file(bytes32("wait"), g.end_wait);
    // flap
    flap.file(bytes32("beg"), WAD * (PENCENT_DIVIDER + g.flap_beg) / PENCENT_DIVIDER);
    flap.file(bytes32("ttl"), g.flap_ttl);
    flap.file(bytes32("tau"), g.flap_tau);
    flap.file(bytes32("lid"), RAD * g.flap_lid);
    // flop
    flop.file(bytes32("beg"), WAD * (PENCENT_DIVIDER + g.flop_beg) / PENCENT_DIVIDER);
    flop.file(bytes32("ttl"), g.flop_ttl);
    flop.file(bytes32("tau"), g.flop_tau);
    flop.file(bytes32("pad"), WAD * (PENCENT_DIVIDER + g.flop_pad) / PENCENT_DIVIDER);
    // jug
    uint base = g.jug_base * RAY / PENCENT_DIVIDER / (60 * 60 * 24 * 365);
    jug.file(bytes32("base"), base);
    // pot
    // uint dsr = g.pot_dsr * RAY / PENCENT_DIVIDER/ (60 * 60 * 24 * 365);
    // pot.file(bytes32("dsr"), dsr);
    // vow
    vow.file(bytes32("wait"), g.vow_wait);
    vow.file(bytes32("dump"), WAD * g.vow_dump);
    vow.file(bytes32("sump"), RAD * g.vow_sump);
    vow.file(bytes32("bump"), RAD * g.vow_bump);
    vow.file(bytes32("hump"), RAD * g.vow_hump);
  }

  function setup() public {
    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
    G memory g = parseConfig(json);
    initTokens(g.tokens);
    uint chainId = vm.envUint("CHAIN_ID");

    // deploy the contract
    dssDeploy(chainId, WAD * g.global.esm_min);
    // set param
    setParam(g.global);

    // deploy testnet tokens
    deployTestnetTokens();
    // deploy ilks
    deployIlks();

    pauseAuth(address(this));
    gov.mint(1000 ether);

    Admin admin = new Admin(address(pause));
    pauseAuth(address(admin));
    admin.setDelay(0);
    end.file("wait", 0);
  }

  uint CHAIN_ID;
  Global gl;

  function _run() internal virtual {
    // deploy the contract
    dssDeploy(CHAIN_ID, WAD * gl.esm_min);
    // set param
    setParam(gl);

    gov.mint(1000 ether);

    Admin admin = new Admin(address(pause));
    pauseAuth(address(admin));
  }

  function _before() internal virtual {
    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/config.json"));
    G memory g = parseConfig(json);
    gl = g.global;

    initTokens(g.tokens);
    CHAIN_ID = vm.envUint("CHAIN_ID");
  }

  function run() public {
    _before();
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    vm.startBroadcast(deployer);

    _run();

    vm.stopBroadcast();
  }

  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }
}

interface OldAdmin {
  function setDelay(uint newDelay) external;
}

contract Deploy2 is DeployScript {
  bytes32[] ilk_names;
  address oldAdmin;

  struct AddrInfo {
    address addr;
    string name;
  }

  mapping(string => address) addrs;

  function _before() internal override {
    super._before();

    string memory json = vm.readFile(string.concat(vm.projectRoot(), "/script/config/421614.json"));
    bytes memory jsonBytes = vm.parseJson(json);
    AddrInfo[] memory addrs_ = abi.decode(jsonBytes, (AddrInfo[]));
    for (uint i = 0; i < addrs_.length; i++) {
      AddrInfo memory addr = addrs_[i];
      addrs[addr.name] = addr.addr;
    }
    vat = Vat(addrs["Vat"]);
    spotter = Spotter(addrs["Spotter"]);
    jug = Jug(addrs["Jug"]);
    vow = Vow(addrs["Vow"]);
    cat = Cat(addrs["Cat"]);
    dog = Dog(addrs["Dog"]);
    dai = Dai(addrs["Dai"]);
    daiJoin = DaiJoin(addrs["DaiJoin"]);
    flap = Flapper(addrs["Flapper"]);
    flop = Flopper(addrs["Flopper"]);
    pot = Pot(addrs["Pot"]);
    cure = Cure(addrs["Cure"]);
    end = End(addrs["End"]);
    esm = ESM(addrs["ESM"]);
    pause = DSPause(addrs["DSPause"]);
    gov = DSToken(addrs["DSToken"]);
    registry = ProxyRegistry(addrs["ProxyRegistry"]);
    oldAdmin = addrs["Admin"];
    console2.log("vat", address(vat));
    console2.log("spotter", address(spotter));
    console2.log("jug", address(jug));
    console2.log("vow", address(vow));
    console2.log("cat", address(cat));
    console2.log("dog", address(dog));
    console2.log("dai", address(dai));
    console2.log("daiJoin", address(daiJoin));
    console2.log("flap", address(flap));
    console2.log("flop", address(flop));
    console2.log("pot", address(pot));
    console2.log("cure", address(cure));
    console2.log("end", address(end));
    console2.log("esm", address(esm));
    console2.log("gov", address(gov));
    console2.log("registry", address(registry));
    console2.log("pause", address(pause));
    console2.log("oldAdmin", oldAdmin);
  }

  function _onlyTry() internal {
    Admin admin = Admin(0x8cDf2e4B7488dAaa4963c23eFfa5c5247C921FaC);
    admin.changeDelay(0, true);
    // OldAdmin(oldAdmin).setDelay(1);
  }

  function _setIlksDuty() internal {
    Admin admin = Admin(0x8cDf2e4B7488dAaa4963c23eFfa5c5247C921FaC);
    for (uint i = 0; i < tokenNames.length; i++) {
      bytes32 tname = tokenNames[i];
      Token memory token = tokens[tname];
      for (uint j = 0; j < token.ilks.length; j++) {
        Ilkx memory ilkx = token.ilks[j];
        bytes32 iname = bytes32(bytes(abi.encodePacked(token.name, "-", ilkx.name)));
        uint duty = ilkx.duty * RAY / PENCENT_DIVIDER / (60 * 60 * 24 * 365);
        admin.dripAndFile(address(jug), iname, "duty", duty);
      }
    }
  }

  function _setDsrAndBase() internal {
    Admin admin = Admin(0x8cDf2e4B7488dAaa4963c23eFfa5c5247C921FaC);
    uint dsr = gl.pot_dsr * RAY / PENCENT_DIVIDER / (60 * 60 * 24 * 365);
    admin.dripAndFile(address(pot), "dsr", dsr);
    uint base = gl.jug_base * RAY / PENCENT_DIVIDER / (60 * 60 * 24 * 365);
    admin.file(address(jug), bytes32("base"), base);
  }

  function _run() internal override {
    // deploy testnet tokens
    // deployTestnetTokens();
    // deploy ilks
    // deployIlks();
    // setParam(gl);
    // _setIlks();
    // vat.file(bytes32("Line"), WAD * 1e9);
    // (uint art, uint rate, uint spot, uint line, uint dust) = vat.ilks("ETH-A");
    // console2.log("ETH-A: art, rate, spot", art / WAD, rate / WAD, spot / WAD);
    // console2.log("ETH-A: line, dust", line / WAD, dust / WAD);
    // _pokeIlks();
    _setDsrAndBase();
    _setIlksDuty();
  }
}
