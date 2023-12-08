// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

abstract contract Config is Script {
  // 定义Calc结构体
  struct RawCalc {
    string cut; // %
    string step;
    string calcType;
  }
  // string tu;

  struct Calc {
    string calcType;
    uint cut; // %
    uint step;
    uint tu;
  }

  function convCalc(RawCalc memory in_) public pure returns (Calc memory out_) {
    out_.calcType = in_.calcType;
    out_.cut = parsePercentString(in_.cut);
    out_.step = vm.parseUint(in_.step);
    // out_.tu = vm.parseUint(in_.tu);
  }

  // 定义ClipDeploy结构体
  struct RawClipDeploy {
    string buf;
    RawCalc calc;
    string chip;
    string chop;
    string cusp;
    string hole;
    string tail;
    string tip;
    string cm_tolerance;
  }

  struct ClipDeploy {
    uint buf; // %
    Calc calc;
    uint chip; // %
    uint chop; // %
    uint cusp; // %
    uint hole;
    uint tail;
    uint tip;
    uint cm_tolerance;
  }

  function convClipDeploy(RawClipDeploy memory in_) public pure returns (ClipDeploy memory out_) {
    out_.buf = parsePercentString(in_.buf);
    convCalc(in_.calc);
    out_.chip = parsePercentString(in_.chip);
    out_.chop = parsePercentString(in_.chop);
    out_.cusp = parsePercentString(in_.cusp);
    out_.hole = vm.parseUint(in_.hole);
    out_.tail = vm.parseUint(in_.tail);
    out_.tip = vm.parseUint(in_.tip);
    out_.cm_tolerance = vm.parseUint(in_.cm_tolerance);
  }
  // 定义Ilk结构体

  struct RawIlk {
    string autoLine;
    string autoLineGap;
    string autoLineTtl;
    RawClipDeploy clipDeploy;
    string dust;
    string duty; // %
    string line;
    string mat; // %
    string name;
  }

  struct Ilkx {
    uint autoLine;
    uint autoLineGap;
    uint autoLineTtl;
    ClipDeploy clipDeploy;
    uint dust;
    uint duty;
    uint line;
    uint mat;
    string name;
  }

  function convIlk(RawIlk memory in_) public pure returns (Ilkx memory out_) {
    out_.autoLine = vm.parseUint(in_.autoLine);
    out_.autoLineGap = vm.parseUint(in_.autoLineGap);
    out_.autoLineTtl = vm.parseUint(in_.autoLineTtl);
    out_.clipDeploy = convClipDeploy(in_.clipDeploy);
    out_.dust = vm.parseUint(in_.dust);
    out_.duty = parsePercentString(in_.duty);
    out_.line = vm.parseUint(in_.line);
    out_.mat = parsePercentString(in_.mat);
    if (out_.line == 0) {
      out_.line = out_.autoLine;
    }
    out_.name = in_.name;
  }

  struct Import {
    address gem;
    address pip;
  }

  struct ExtraParam {
    string name;
    string value;
  }

  struct JoinDeploy {
    ExtraParam[] extraParams;
    string src;
  }

  // 定义Token结构体
  struct RawToken {
    RawIlk[] ilks;
    Import importx;
    JoinDeploy joinDeploy;
    string name;
  }

  struct Token {
    Ilkx[] ilks;
    Import importx;
    JoinDeploy joinDeploy;
    string name;
  }

  function convToken(RawToken memory in_) public pure returns (Token memory out_) {
    out_.name = in_.name;
    out_.importx = in_.importx;
    out_.joinDeploy = in_.joinDeploy;
    out_.ilks = new Ilkx[](in_.ilks.length);
    for (uint i = 0; i < in_.ilks.length; i++) {
      out_.ilks[i] = convIlk(in_.ilks[i]);
    }
  }

  struct RawConfig0 {
    string pauseDelay;
    string vat_line;
    string vow_wait;
    string vow_dump;
    string vow_sump;
    string vow_bump;
    string vow_hump;
    string cat_box;
    string dog_hole;
    string jug_base;
  }

  struct Config0 {
    uint pauseDelay;
    uint vat_line;
    uint vow_wait;
    uint vow_dump;
    uint vow_sump;
    uint vow_bump;
    uint vow_hump;
    uint cat_box;
    uint dog_hole;
    uint jug_base;
  }

  function convConfig0(RawConfig0 memory in_) public pure returns (Config0 memory out_) {
    out_.pauseDelay = vm.parseUint(in_.pauseDelay);
    out_.vat_line = vm.parseUint(in_.vat_line);
    out_.vow_wait = vm.parseUint(in_.vow_wait);
    out_.vow_dump = vm.parseUint(in_.vow_dump);
    out_.vow_sump = vm.parseUint(in_.vow_sump);
    out_.vow_bump = vm.parseUint(in_.vow_bump);
    out_.vow_hump = vm.parseUint(in_.vow_hump);
    out_.cat_box = vm.parseUint(in_.cat_box);
    out_.dog_hole = vm.parseUint(in_.dog_hole);
    out_.jug_base = vm.parseUint(in_.jug_base);
  }

  struct RawConfig1 {
    string pot_dsr;
    string cure_wait;
    string end_wait;
    string esm_min;
    string flap_beg;
    string flap_ttl;
    string flap_tau;
    string flap_lid;
    string flop_beg;
    string flop_pad;
    string flop_ttl;
    string flop_tau;
    string flash_max;
  }

  struct Config1 {
    uint pot_dsr;
    uint cure_wait;
    uint end_wait;
    uint esm_min;
    uint flap_beg;
    uint flap_ttl;
    uint flap_tau;
    uint flap_lid;
    uint flop_beg;
    uint flop_pad;
    uint flop_ttl;
    uint flop_tau;
    uint flash_max;
  }

  function convConfig1(RawConfig1 memory in_) public pure returns (Config1 memory out_) {
    out_.pot_dsr = vm.parseUint(in_.pot_dsr);
    out_.cure_wait = vm.parseUint(in_.cure_wait);
    out_.end_wait = vm.parseUint(in_.end_wait);
    out_.esm_min = vm.parseUint(in_.esm_min);
    out_.flap_beg = vm.parseUint(in_.flap_beg);
    out_.flap_ttl = vm.parseUint(in_.flap_ttl);
    out_.flap_tau = vm.parseUint(in_.flap_tau);
    out_.flap_lid = vm.parseUint(in_.flap_lid);
    out_.flop_beg = vm.parseUint(in_.flop_beg);
    out_.flop_pad = vm.parseUint(in_.flop_pad);
    out_.flop_ttl = vm.parseUint(in_.flop_ttl);
    out_.flop_tau = vm.parseUint(in_.flop_tau);
    out_.flash_max = vm.parseUint(in_.flash_max);
  }

  struct RawGlobal {
    string cat_box;
    string cure_wait;
    string description;
    string dog_hole;
    string end_wait;
    string esm_min;
    string flap_beg; // %
    string flap_lid;
    string flap_tau;
    string flap_ttl;
    string flash_max;
    string flop_beg; // %
    string flop_pad; // %
    string flop_tau;
    string flop_ttl;
    string jug_base; // %
    string pauseDelay;
    string pot_dsr; // %
    string vat_line;
    string vow_bump;
    string vow_dump;
    string vow_hump;
    string vow_sump;
    string vow_wait;
  }

  struct Global {
    uint cat_box;
    uint cure_wait;
    string description;
    uint dog_hole;
    uint end_wait;
    uint esm_min;
    uint flap_beg;
    uint flap_lid;
    uint flap_tau;
    uint flap_ttl;
    uint flash_max;
    uint flop_beg;
    uint flop_pad;
    uint flop_tau;
    uint flop_ttl;
    uint jug_base;
    uint pauseDelay;
    uint pot_dsr;
    uint vat_line;
    uint vow_bump;
    uint vow_dump;
    uint vow_hump;
    uint vow_sump;
    uint vow_wait;
  }

  function convGlobal(RawGlobal memory in_) public pure returns (Global memory out_) {
    out_.cat_box = vm.parseUint(in_.cat_box);
    out_.cure_wait = vm.parseUint(in_.cure_wait);
    out_.dog_hole = vm.parseUint(in_.dog_hole);
    out_.end_wait = vm.parseUint(in_.end_wait);
    out_.esm_min = vm.parseUint(in_.esm_min);
    out_.flap_beg = parsePercentString(in_.flap_beg);
    out_.flap_lid = vm.parseUint(in_.flap_lid);
    out_.flap_tau = vm.parseUint(in_.flap_tau);
    out_.flap_ttl = vm.parseUint(in_.flap_ttl);
    out_.flash_max = vm.parseUint(in_.flash_max);
    out_.flop_beg = parsePercentString(in_.flop_beg);
    out_.flop_pad = parsePercentString(in_.flop_pad);
    out_.flop_tau = vm.parseUint(in_.flop_tau);
    out_.flop_ttl = vm.parseUint(in_.flop_ttl);
    out_.jug_base = parsePercentString(in_.jug_base);
    out_.pauseDelay = vm.parseUint(in_.pauseDelay);
    out_.pot_dsr = parsePercentString(in_.pot_dsr);
    out_.vat_line = vm.parseUint(in_.vat_line);
    out_.vow_bump = vm.parseUint(in_.vow_bump);
    out_.vow_dump = vm.parseUint(in_.vow_dump);
    out_.vow_hump = vm.parseUint(in_.vow_hump);
    out_.vow_sump = vm.parseUint(in_.vow_sump);
    out_.vow_wait = vm.parseUint(in_.vow_wait);
  }

  /*
  "import": {
    "chainlog": "0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F",
    "gov": "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
    "authority": "0x0a3f6849f78076aefaDf113F5BED87720274dDC0",
    "proxyRegistry": "0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4",
    "faucet": "0x0000000000000000000000000000000000000000"
  },
  */

  struct ImportG {
    address authority;
    address chainlog;
    address faucet;
    address gov;
    address proxyRegistry;
  }

  struct Global_ {
    Config0 config0;
    Config1 config1;
  }

  struct RawG {
    RawGlobal global;
    ImportG importx;
    RawToken[] tokens;
  }

  struct G {
    Global global;
    ImportG importx;
    Token[] tokens;
  }

  struct RawG2 {
    RawConfig0 config0;
    RawConfig1 config1;
    ImportG importx;
    RawToken[] tokens;
  }

  struct G2 {
    Config0 config0;
    Config1 config1;
    ImportG importx;
    Token[] tokens;
  }

  function ConvG2(RawG2 memory in_) public pure returns (G2 memory out_) {
    out_.config0 = convConfig0(in_.config0);
    out_.config1 = convConfig1(in_.config1);
    out_.importx = in_.importx;
    out_.tokens = new Token[](in_.tokens.length);
    for (uint i = 0; i < in_.tokens.length; i++) {
      out_.tokens[i] = convToken(in_.tokens[i]);
    }
  }

  function convG(RawG memory in_) public pure returns (G memory out_) {
    out_.global = convGlobal(in_.global);
    out_.importx = in_.importx;
    out_.tokens = new Token[](in_.tokens.length);
    for (uint i = 0; i < in_.tokens.length; i++) {
      out_.tokens[i] = convToken(in_.tokens[i]);
    }
  }

  function initGlobalConfig() public pure returns (Global_ memory config) {
    uint ONE = 10 ** 18;
    config.config0 = Config0({
      pauseDelay: 0,
      vat_line: 778000000 * ONE,
      vow_wait: 561600,
      vow_dump: 250 * ONE,
      vow_sump: 50000 * ONE,
      vow_bump: 10000 * ONE,
      vow_hump: 500000 * ONE,
      cat_box: 10000000 * ONE,
      dog_hole: 100000000 * ONE,
      jug_base: 0
    });
    config.config1 = Config1({
      pot_dsr: 0,
      cure_wait: 0,
      end_wait: 262800,
      esm_min: 100000 * ONE,
      flap_beg: 2,
      flap_ttl: 1800,
      flap_tau: 259200,
      flap_lid: 150000 * ONE,
      flop_beg: 3,
      flop_pad: 20,
      flop_ttl: 21600,
      flop_tau: 259200,
      flash_max: 500000000 * ONE
    });
  }

  function parseConfig(string memory json) public pure returns (G memory g) {
    bytes memory jsonBytes = vm.parseJson(json);
    RawG memory rg = abi.decode(jsonBytes, (RawG));
    g = convG(rg);
  }

  function parseGlobal(string memory json) public pure returns (Global memory global) {
    bytes memory jsonBytes = vm.parseJson(json, ".global");
    RawGlobal memory rglobal = abi.decode(jsonBytes, (RawGlobal));
    global = convGlobal(rglobal);
  }

  function parseImport(string memory json) public pure returns (ImportG memory importx) {
    bytes memory jsonBytes = vm.parseJson(json, ".import");
    importx = abi.decode(jsonBytes, (ImportG));
  }

  function parseConfig2(string memory json) public pure returns (RawG2 memory rg) {
    bytes memory jsonBytes = vm.parseJson(json);
    rg = abi.decode(jsonBytes, (RawG2));
  }

  function parseRawTokens(string memory json, uint len)
    public
    pure
    returns (RawToken[] memory tokens)
  {
    tokens = new RawToken[](len);
    for (uint i = 0; i < len; i++) {
      bytes memory jsonBytes =
        vm.parseJson(json, string(abi.encodePacked(".tokens[", vm.toString(i), "]")));
      tokens[i] = abi.decode(jsonBytes, (RawToken));
    }
  }

  function parseTokens(string memory json) public pure returns (Token[] memory tokens) {
    uint TOKEN_LENGTH = 35;
    tokens = new Token[](TOKEN_LENGTH);
    for (uint i = 0; i < TOKEN_LENGTH; i++) {
      bytes memory jsonBytes =
        vm.parseJson(json, string(abi.encodePacked(".tokens[", vm.toString(i), "]")));
      tokens[i] = convToken(abi.decode(jsonBytes, (RawToken)));
    }
  }

  function parseConfig0(string memory json) public pure returns (Config0 memory config) {
    bytes memory jsonBytes = vm.parseJson(json, ".config0");
    RawConfig0 memory rconfig = abi.decode(jsonBytes, (RawConfig0));
    config = convConfig0(rconfig);
  }

  function parseConfig1(string memory json) public pure returns (Config1 memory config) {
    bytes memory jsonBytes = vm.parseJson(json, ".config1");
    RawConfig1 memory rconfig = abi.decode(jsonBytes, (RawConfig1));
    config = convConfig1(rconfig);
  }

  function parsePercentString(string memory str) public pure returns (uint) {
    bytes memory b = bytes(str);
    uint i;
    uint result = 0;
    bool hasDot = false;
    uint decimalPlaces = 2; // 默认小数点后有两位
    for (; i < b.length; i++) {
      uint8 tempByte = uint8(b[i]);
      if (tempByte >= 48 && tempByte <= 57) {
        result = result * 10 + (tempByte - 48); // convert char to number
        if (hasDot) {
          if (--decimalPlaces == 0) {
            break;
          }
        }
      } else if (tempByte == 46) {
        require(!hasDot, "More than one dot in the string!");
        hasDot = true;
      } else {
        revert("Invalid character in string!");
      }
    }
    for (; decimalPlaces > 0; decimalPlaces--) {
      result *= 10;
    }
    return result;
  }
}

/*
contract TokenList {
  mapping(bytes32 => address) public tokens;
  mapping(bytes32 => uint) public prices;
  bytes32[] public tokenList;

  function addToken(bytes32 symbol, address token, uint price) public {
    require(tokens[symbol] == address(0), "already added");
    tokens[symbol] = token;
    prices[symbol] = price;
    tokenList.push(symbol);
  }

  function tokenLength() public view returns (uint) {
    return tokenList.length;
  }

  constructor() {
    // addToken("DAI", GoerliTokens.DAI, GoerliTokens.DAI_PRICE);
    // addToken("WETH", GoerliTokens.ETH, GoerliTokens.ETH_PRICE);
    // addToken("USDC", GoerliTokens.USDC, GoerliTokens.USDC_PRICE);
    // addToken("WBTC", GoerliTokens.WBTC, GoerliTokens.WBTC_PRICE);
    // addToken("USDT", GoerliTokens.USDT, GoerliTokens.USDT_PRICE);
    // addToken("LINK", GoerliTokens.LINK, GoerliTokens.LINK_PRICE);
    // addToken("AAVE", GoerliTokens.AAVE, GoerliTokens.AAVE_PRICE);
    // addToken("MATIC", GoerliTokens.MATIC, GoerliTokens.MATIC_PRICE);
    // addToken("WSTETH", GoerliTokens.WSTETH, GoerliTokens.WSTETH_PRICE);
    // addToken("BAT", GoerliTokens.BAT, GoerliTokens.BAT_PRICE);
  }
}


library GoerliTokens {
  address public constant DAI = 0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844;
  address public constant ETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
  address public constant USDC = 0x6Fb5ef893d44F4f88026430d82d4ef269543cB23;
  address public constant WBTC = 0x7ccF0411c7932B99FC3704d68575250F032e3bB7;
  address public constant USDT = 0x5858f25cc225525A7494f76d90A6549749b3030B;
  address public constant LINK = 0x4724A967A4F7E42474Be58AbdF64bF38603422FF;
  address public constant AAVE = 0x251661BB7C6869165eF35810E5e1D25Ed57be2Fe;
  address public constant MATIC = 0x5B3b6CF665Cc7B4552F4347623a2A9E00600CBB5;
  address public constant WSTETH = 0x6320cD32aA674d2898A68ec82e869385Fc5f7E2f;
  address public constant BAT = 0x75645f86e90a1169e697707C813419977ea26779;

  uint public constant DAI_PRICE = 10 ** 18;
  uint public constant ETH_PRICE = 2000 * 10 ** 18;
  uint public constant USDC_PRICE = 10 ** 18;
  uint public constant WBTC_PRICE = 37000 * 10 ** 18;
  uint public constant USDT_PRICE = 10 ** 18;
  uint public constant LINK_PRICE = 14 * 10 ** 18;
  uint public constant AAVE_PRICE = 97 * 10 ** 18;
  uint public constant MATIC_PRICE = 54 ** 18;
  uint public constant WSTETH_PRICE = 2000 * 10 ** 18;
  uint public constant BAT_PRICE = 2 ** 18;
}

*/
