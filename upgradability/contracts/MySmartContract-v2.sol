pragma solidity ^0.5.0;

contract MySmartContract {
  uint32 public counter;
  bool private stopped = false;
  address private owner;

  /**
  @dev Checks if the contract is not stopped; reverts if it is.
  */
  modifier isNotStopped {
    require(!stopped, 'Contract is stopped.');
    _;
  }

  /**
  @dev Enforces the caller to be the contract's owner.
  */
  modifier isOwner {
    require(msg.sender == owner, 'Sender is not owner.');
    _;
  }

  constructor(uint32 _counter) public {
    counter = _counter; // Allows setting counter's initial value on deployment.
    // Sets the contract's owner as the address that deployed the contract.
    owner = msg.sender;
  }

  /**
  @notice Increments the contract's counter if contract is active.
  @dev It will revert is the contract is stopped. See modifier "isNotStopped"
   */
  function incrementCounter() isNotStopped public {
    counter++; // Fixes bug introduced in version 1.
  }

  /**
  @dev Stops / Unstops the contract.
   */
  function toggleContractStopped() isOwner public {
      stopped = !stopped;
  }
}
