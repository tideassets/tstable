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

// if delay > 0,  the action should be executed twice: once for scheduling (plot) and once for actual execution (exec).
// You can also call it only once, then wait for enough time (the last call time + delay),
// and call execAll to execute all the actions added before in once go.
contract AdminActions is DSAuth {
  uint public delay;
  DSPause public pause;
  GovActions public govActions;

  struct ActInfo {
    bytes fax;
    uint eta;
  }

  mapping(address => ActInfo[]) public acts;
  mapping(address => mapping(bytes32 => uint)) public indexs;
  mapping(address => mapping(bytes32 => uint)) public plats;

  function _exec(bytes memory fax) internal {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    uint eta = block.timestamp + delay;

    if (delay > 0) {
      bytes32 data = keccak256(fax);
      uint eta_ = plats[msg.sender][data];
      if (eta_ == 0) {
        plats[msg.sender][data] = eta;
        pause.plot(usr, tag, (fax), eta);

        indexs[msg.sender][data] = acts[msg.sender].length;
        acts[msg.sender].push(ActInfo(fax, eta));
      } else {
        require(eta_ < block.timestamp, "delayed");
        plats[msg.sender][data] = 0;
        pause.exec(usr, tag, fax, eta_);

        ActInfo[] storage acts_ = acts[msg.sender];
        ActInfo memory last = acts_[acts_.length - 1];
        acts_[indexs[msg.sender][data]] = last;
        acts_.pop();
      }
    } else {
      pause.plot(usr, tag, fax, eta);
      pause.exec(usr, tag, fax, eta);
    }
  }

  function _execActs() internal {
    address usr = address(govActions);
    bytes32 tag;
    assembly {
      tag := extcodehash(usr)
    }
    ActInfo[] storage acts_ = acts[msg.sender];
    for (uint i = 0; i < acts_.length; i++) {
      ActInfo memory act = acts_[i];
      require(act.eta <= block.timestamp, "delayed");
      pause.exec(usr, tag, act.fax, act.eta);
    }
    delete acts[msg.sender];
  }

  function execAll() external auth {
    _execActs();
  }

  function rely(address, address) external auth {
    _exec(msg.data);
  }

  function deny(address, address) external auth {
    _exec(msg.data);
  }

  function file(address, bytes32, uint) external auth {
    _exec(msg.data);
  }

  function file(address, bytes32, bytes32, uint) external auth {
    _exec(msg.data);
  }

  function dripAndFile(address, bytes32, uint) external auth {
    _exec(msg.data);
  }

  function dripAndFile(address, bytes32, bytes32, uint) external auth {
    _exec(msg.data);
  }

  function cage(address) external auth {
    _exec(msg.data);
  }

  function setAuth(address) external auth {
    _exec(msg.data);
  }

  function setDelay(uint delay_) public auth {
    delay = delay_;
    _exec(msg.data);
  }

  function setAuthorityAndDelay(address, uint delay_) external auth {
    delay = delay_;
    _exec(msg.data);
  }
}

contract Admin is AdminActions {
  constructor(address pause_) {
    pause = DSPause(pause_);
    govActions = new GovActions();
  }
}
