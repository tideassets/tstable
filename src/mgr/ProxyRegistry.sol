pragma solidity >=0.8.20;

import "ds-proxy/proxy.sol";

// This Registry deploys new proxy instances through DSProxyFactory.build(address) and keeps a registry of owner => proxy
contract ProxyRegistry {
  mapping(address => DSProxy) public proxies;
  DSProxyFactory factory;

  constructor(address factory_) {
    factory = DSProxyFactory(factory_);
  }

  // deploys a new proxy instance
  // sets owner of proxy to caller
  function build() public returns (address payable proxy) {
    proxy = build(msg.sender);
  }

  // deploys a new proxy instance
  // sets custom owner of proxy
  function build(address owner) public returns (address payable proxy) {
    require(address(proxies[owner]) == address(0) || proxies[owner].owner() != owner); // Not allow new proxy if the user already has one and remains being the owner
    proxy = factory.build(owner);
    proxies[owner] = DSProxy(proxy);
  }
}
