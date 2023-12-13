// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DSAuth, DSAuthority} from "ds-auth/auth.sol";
import {DSPause} from "ds-pause/pause.sol";
import {GovActions} from "dss-deploy/govActions.sol";


contract Authority is DSAuth, DSAuthority {
  mapping(address => mapping(address => mapping(bytes4 => bool))) acl;

  function canCall(address src, address dst, bytes4 sig) external view returns (bool) {
    return acl[src][dst][sig];
  }

  function permit(address src, address dst, bytes4 sig) public auth {
    acl[src][dst][sig] = true;
  }

  function forbid(address src, address dst, bytes4 sig) public auth {
    acl[src][dst][sig] = false;
  }
}

contract ProxyActions is DSAuth {
  DSPause public pause;
  GovActions public govActions;

  function rely(address from, address to) external auth {
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

  function deny(address from, address to) external auth {
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

  function file(address who, bytes32 what, uint data) external auth {
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

  function file(address who, bytes32 ilk, bytes32 what, uint data) external auth {
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

  function dripAndFile(address who, bytes32 what, uint data) external auth {
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

  function dripAndFile(address who, bytes32 ilk, bytes32 what, uint data) external auth {
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

  function cage(address end) external auth {
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

  function setAuth(address newAuthority) external auth {
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

  function setDelay(uint newDelay) external auth {
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

contract Admin is ProxyActions {
  constructor(address pause_) {
    pause = DSPause(pause_);
    govActions = new GovActions();
  }
}