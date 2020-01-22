pragma solidity ^0.5.0;

contract BaseStateLayout {
  address public currentVersion;
  address public owner;
}

contract HighLevelDelegateProxy is BaseStateLayout {
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(address initAddr) {
    require(initAddr != address(0));
    currentVersion = initAddr;
    owner = msg.sender; // this owner may be another contract with multisig, not a single contract owner
  }

  function upgrade(address newVersion) public onlyOwner()
  {
    require(newVersion != address(0));
    currentVersion = newVersion;
  }

  fallback() external payable {
    (bool success, ) = address(currentVersion).delegatecall(msg.data);
    require(success);
  }
}

contract HighLevelLogicContract is BaseLayoutState {
    uint public counter;

    function incrementCounter() {
        counter++;
    }
}