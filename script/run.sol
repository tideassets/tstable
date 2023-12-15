// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Deploy2} from "./deploy.s.sol";
import {Admin} from "./admin.sol";
import {ProxyUser} from "./user.sol";

// This contract is used to run the deploy script.
contract Run is Deploy2 {
  function _run() internal override {
    Admin admin = Admin(0x8304A75e118D5e59Df8B90A556A72584BFd6CB6f);
    admin.file(address(vat), "Line", 1e9 * RAD);
    admin.file(address(vat), "Line", 1e9 * RAD);
  }
}
