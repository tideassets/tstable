// SPDX-License-Identifier: UNLICENSED
// FILEPATH: /Users/w/tideassets/contracts/tstable/script/user.sol

pragma solidity ^0.8.13;

import "dss-proxy-actions/DssProxyActions.sol";
import {
  ProxyRegistry, DSProxyFactory, DSProxy, DSProxyCache
} from "proxy-registry/ProxyRegistry.sol";

abstract contract ProxyCalls {
  DSProxy public proxy;
  address dssProxyActions;
  address dssProxyActionsEnd;
  address dssProxyActionsDsr;

  function transfer(address, address, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function open(address, bytes32, address) public returns (uint cdp) {
    bytes memory response = proxy.execute(dssProxyActions, msg.data);
    assembly {
      cdp := mload(add(response, 0x20))
    }
  }

  function give(address, uint, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function giveToProxy(address, address, uint, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function cdpAllow(address, uint, address, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function urnAllow(address, address, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function hope(address, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function nope(address, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function flux(address, uint, address, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function move(address, uint, address, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function frob(address, uint, int, int) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function frob(address, uint, address, int, int) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function quit(address, uint, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function enter(address, address, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function shift(address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function lockETH(address, address, uint) public payable {
    (bool success,) = address(proxy).call{value: msg.value}(
      abi.encodeWithSignature("execute(address,bytes)", dssProxyActions, msg.data)
    );
    require(success, "");
  }

  function safeLockETH(address, address, uint, address) public payable {
    (bool success,) = address(proxy).call{value: msg.value}(
      abi.encodeWithSignature("execute(address,bytes)", dssProxyActions, msg.data)
    );
    require(success, "");
  }

  function lockGem(address, address, uint, uint, bool) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function safeLockGem(address, address, uint, uint, bool, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function makeGemBag(address) public returns (address bag) {
    address payable target = payable(address(proxy));
    bytes memory data = abi.encodeWithSignature("execute(address,bytes)", dssProxyActions, msg.data);
    assembly {
      let succeeded :=
        call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize()
      let response := mload(0x40)
      mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(response, size)
      returndatacopy(add(response, 0x20), 0, size)

      bag := mload(add(response, 0x60))

      switch iszero(succeeded)
      case 1 {
        // throw if delegatecall failed
        revert(add(response, 0x20), size)
      }
    }
  }

  function freeETH(address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function freeGem(address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function exitETH(address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function exitGem(address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function draw(address, address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function wipe(address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function wipeAll(address, address, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function safeWipe(address, address, uint, uint, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function safeWipeAll(address, address, uint, address) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function lockETHAndDraw(address, address, address, address, uint, uint) public payable {
    (bool success,) = address(proxy).call{value: msg.value}(
      abi.encodeWithSignature("execute(address,bytes)", dssProxyActions, msg.data)
    );
    require(success, "");
  }

  function openLockETHAndDraw(address, address, address, address, bytes32, uint)
    public
    payable
    returns (uint cdp)
  {
    address payable target = payable(address(proxy));
    bytes memory data = abi.encodeWithSignature("execute(address,bytes)", dssProxyActions, msg.data);
    assembly {
      let succeeded :=
        call(sub(gas(), 5000), target, callvalue(), add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize()
      let response := mload(0x40)
      mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(response, size)
      returndatacopy(add(response, 0x20), 0, size)

      cdp := mload(add(response, 0x60))

      switch iszero(succeeded)
      case 1 {
        // throw if delegatecall failed
        revert(add(response, 0x20), size)
      }
    }
  }

  function lockGemAndDraw(address, address, address, address, uint, uint, uint, bool) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function openLockGemAndDraw(address, address, address, address, bytes32, uint, uint, bool)
    public
    returns (uint cdp)
  {
    bytes memory response = proxy.execute(dssProxyActions, msg.data);
    assembly {
      cdp := mload(add(response, 0x20))
    }
  }

  function openLockGNTAndDraw(address, address, address, address, bytes32, uint, uint)
    public
    returns (address bag, uint cdp)
  {
    bytes memory response = proxy.execute(dssProxyActions, msg.data);
    assembly {
      bag := mload(add(response, 0x20))
      cdp := mload(add(response, 0x40))
    }
  }

  function wipeAndFreeETH(address, address, address, uint, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function wipeAllAndFreeETH(address, address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function wipeAndFreeGem(address, address, address, uint, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function wipeAllAndFreeGem(address, address, address, uint, uint) public {
    proxy.execute(dssProxyActions, msg.data);
  }

  function end_freeETH(address a, address b, address c, uint d) public {
    proxy.execute(
      dssProxyActionsEnd,
      abi.encodeWithSignature("freeETH(address,address,address,uint256)", a, b, c, d)
    );
  }

  function end_freeGem(address a, address b, address c, uint d) public {
    proxy.execute(
      dssProxyActionsEnd,
      abi.encodeWithSignature("freeGem(address,address,address,uint256)", a, b, c, d)
    );
  }

  function end_pack(address a, address b, uint c) public {
    proxy.execute(
      dssProxyActionsEnd, abi.encodeWithSignature("pack(address,address,uint256)", a, b, c)
    );
  }

  function end_cashETH(address a, address b, bytes32 c, uint d) public {
    proxy.execute(
      dssProxyActionsEnd,
      abi.encodeWithSignature("cashETH(address,address,bytes32,uint256)", a, b, c, d)
    );
  }

  function end_cashGem(address a, address b, bytes32 c, uint d) public {
    proxy.execute(
      dssProxyActionsEnd,
      abi.encodeWithSignature("cashGem(address,address,bytes32,uint256)", a, b, c, d)
    );
  }

  function dsr_join(address a, address b, uint c) public {
    proxy.execute(
      dssProxyActionsDsr, abi.encodeWithSignature("join(address,address,uint256)", a, b, c)
    );
  }

  function dsr_exit(address a, address b, uint c) public {
    proxy.execute(
      dssProxyActionsDsr, abi.encodeWithSignature("exit(address,address,uint256)", a, b, c)
    );
  }

  function dsr_exitAll(address a, address b) public {
    proxy.execute(dssProxyActionsDsr, abi.encodeWithSignature("exitAll(address,address)", a, b));
  }
}

contract ProxyUser is ProxyCalls, DSProxy {
  constructor() DSProxy(address(new DSProxyCache())) {
    proxy = DSProxy(payable(address(this)));
    dssProxyActions = address(new DssProxyActions());
    dssProxyActionsEnd = address(new DssProxyActionsEnd());
    dssProxyActionsDsr = address(new DssProxyActionsDsr());
  }
}
