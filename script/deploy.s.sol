// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DSValue} from "ds-value/value.sol";
import "./deploy.sol";
import "../test/deploy.t.base.sol";
import {PipLike} from "../src/spot.sol";

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

  // uint public DAI_LIQ_RATIO = 1500000000 ether;
  // uint public ETH_LIQ_RATIO = 1500000000 ether;
  // uint public USDC_LIQ_RATIO = 1500000000 ether;
  // uint public WBTC_LIQ_RATIO = 1500000000 ether;
  // uint public USDT_LIQ_RATIO = 1500000000 ether;
  // uint public LINK_LIQ_RATIO = 1500000000 ether;
  // uint public AAVE_LIQ_RATIO = 1500000000 ether;
  // uint public MATIC_LIQ_RATIO = 1500000000 ether;
  // uint public WSTETH_LIQ_RATIO = 1500000000 ether;
  // uint public BAT_LIQ_RATIO = 1500000000 ether;
}

interface IPip is PipLike {
  function poke(bytes32) external;
  // function peek() external returns (bytes32, bool);
}

contract DeploySrcipt is DssDeployTestBase, Script {
  TokenList public tl;

  function init_tokens() internal {
    TokenList tokenList = new TokenList();
    tokenList.addToken("DAI", GoerlyTokens.DAI, GoerlyTokens.DAI_PRICE);
    tokenList.addToken("WETH", GoerlyTokens.ETH, GoerlyTokens.ETH_PRICE);
    tokenList.addToken("USDC", GoerlyTokens.USDC, GoerlyTokens.USDC_PRICE);
    tokenList.addToken("WBTC", GoerlyTokens.WBTC, GoerlyTokens.WBTC_PRICE);
    tokenList.addToken("USDT", GoerlyTokens.USDT, GoerlyTokens.USDT_PRICE);
    tokenList.addToken("LINK", GoerlyTokens.LINK, GoerlyTokens.LINK_PRICE);
    tokenList.addToken("AAVE", GoerlyTokens.AAVE, GoerlyTokens.AAVE_PRICE);
    tokenList.addToken("MATIC", GoerlyTokens.MATIC, GoerlyTokens.MATIC_PRICE);
    tokenList.addToken("WSTETH", GoerlyTokens.WSTETH, GoerlyTokens.WSTETH_PRICE);
    tokenList.addToken("BAT", GoerlyTokens.BAT, GoerlyTokens.BAT_PRICE);
    tl = tokenList;
  }

  function gemJoin() internal {
    require(address(vat) != address(0), "vat must deployed before do this");
    for (uint i = 0; i < tl.tokenLength(); i++) {
      bytes32 symbol = tl.tokenList(i);
      GemJoin join = new GemJoin(address(vat), symbol, tl.tokens(symbol));
      LinearDecrease calc = calcFab.newLinearDecrease(address(this));
      calc.file(bytes32("tau"), 1 hours);
      dssDeploy.deployCollateralClip(symbol, address(join), address(new DSValue()), address(calc));
    }
  }

  function setParm() internal {
    this.file(address(vat), bytes32("Line"), uint(10000 * 10 ** 45));

    for (uint i = 0; i < tl.tokenLength(); i++) {
      bytes32 symbol = tl.tokenList(i);
      this.file(address(vat), symbol, bytes32("line"), uint(10000 * 10 ** 45));
      (PipLike pip,) = spotter.ilks(symbol);
      IPip(address(pip)).poke(bytes32(tl.prices(symbol)));
      this.file(address(spotter), symbol, bytes32("mat"), uint(1500000000 ether));
      spotter.poke(symbol);
    }
  }

  function run() public {
    // deploy the contract
    uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    vm.startBroadcast(deployerPrivateKey);

    init_tokens();
    _dssDeploy();
    gemJoin();
    setParm();

    vm.stopBroadcast();
  }
}
