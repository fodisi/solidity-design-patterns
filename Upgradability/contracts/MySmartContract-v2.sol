pragma solidity ^0.5.0;

contract MySmartContract {
  uint32 public counter;

  constructor(uint32 _counter) public {
    counter = _counter;
  }

  function incrementCounter() public {
    counter++;
  }
}
