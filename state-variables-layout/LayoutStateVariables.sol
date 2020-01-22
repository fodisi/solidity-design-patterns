pragma solidity ^0.5.0;

contract Proxy {
  address _impl;
  address _owner;
}

contract LogicContract {
  address _impl;
  address _owner;
  address _logicOwner;
  mapping(address => uint256) balances;
  uint256 _supply;
  uint8 counter1;
  uint8 counter2;
}

contract Pausable {
 bool _isPaused;
}

contract LogicContract1 is Pausable, LogicContract {
 // (Pausable._isPaused) // Overwrites Proxy._impl
 address _impl;
 address _owner;
 address _logicOwner;
 mapping(address => uint256) balances;
 uint256 _supply;
 uint8 counter1;
 uint8 counter2;
}

contract LogicContract2 {
  address _impl;
  address _owner;
  mapping(address => uint256) balances; // Invalid
  address _logicOwner;
  uint256 _supply;
  uint8 counter1;
  uint8 counter2;
}

contract LogicContract3 {
  address _impl;
  address _owner;
  address _logicOwner;
  mapping(address => uint256) balances;
  uint256 _supply;
  uint16 counter1; // Invalid
  uint8 counter2;
}

contract LogicContract4 {
  address _impl;
  address _owner;
  address _logicOwner;
  mapping(address => uint256) balances;
  uint256 _supply;
  uint8 counter3; // Invalid
  uint8 counter1;
  uint8 counter2;
}

contract LogicContract5 {
  address _impl;
  address _owner;
  address _logicOwner;
  mapping(address => uint256) balances;
  uint256 _supply;
  uint8 counter1;
  uint8 counter2;
  uint16 counter3; // valid
}