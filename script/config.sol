// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

library ConfigInfo {
  // 定义Calc结构体
  struct Calc {
    string cut;
    string step;
    string calcType;
  }

  // 定义ClipDeploy结构体
  struct ClipDeploy {
    string buf;
    Calc calc;
    string chip;
    string chop;
    string cusp;
    string hole;
    string tail;
    string tip;
    string cm_tolerance;
  }

  // 定义Ilk结构体
  struct Ilk {
    string autoLine;
    string autoLineGap;
    string autoLineTtl;
    ClipDeploy clipDeploy;
    string dust;
    string duty;
    string line;
    string mat;
    string name;
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
  struct Token {
    Ilk[] ilks;
    Import importx;
    JoinDeploy joinDeploy;
    string name;
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

  struct Config {
    Config0 config0;
    Config1 config1;
  }

  function initConfig() internal pure returns (Config memory config) {
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
}

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
    addToken("DAI", GoerlyTokens.DAI, GoerlyTokens.DAI_PRICE);
    addToken("WETH", GoerlyTokens.ETH, GoerlyTokens.ETH_PRICE);
    addToken("USDC", GoerlyTokens.USDC, GoerlyTokens.USDC_PRICE);
    addToken("WBTC", GoerlyTokens.WBTC, GoerlyTokens.WBTC_PRICE);
    addToken("USDT", GoerlyTokens.USDT, GoerlyTokens.USDT_PRICE);
    addToken("LINK", GoerlyTokens.LINK, GoerlyTokens.LINK_PRICE);
    addToken("AAVE", GoerlyTokens.AAVE, GoerlyTokens.AAVE_PRICE);
    addToken("MATIC", GoerlyTokens.MATIC, GoerlyTokens.MATIC_PRICE);
    addToken("WSTETH", GoerlyTokens.WSTETH, GoerlyTokens.WSTETH_PRICE);
    addToken("BAT", GoerlyTokens.BAT, GoerlyTokens.BAT_PRICE);
  }
}

library GoerlyTokens {
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
