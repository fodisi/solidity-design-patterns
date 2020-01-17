pragma solidity >=0.4.0 < 0.7.0;

interface MasterSlave {
  function setValue(uint _value) external;
  function getValue() external view returns(uint);
}

contract SlaveCallee is MasterSlave {
  uint private value;

  function setValue(uint _value) external {
    value = _value;
  }

  // @note For demonstration purposes.
  // If value was declared as true, no need for function below.
  function getValue() external view returns(uint) {
    return value;
  }
}

contract MasterCaller is MasterSlave {
  address private slave;

  function upgradeSlave(address _slave) external {
    require(_slave != address(0), 'Invalid address');
    slave = _slave;
  }

  function setValue(uint _value) external {
    SlaveCallee(slave).setValue(_value);
  }

  function getValue() external view returns(uint) {
    return SlaveCallee(slave).getValue();
  }
}