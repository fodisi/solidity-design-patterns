pragma solidity ^0.5.0;

/**
 * @dev Renamed version 1 to MySmartContractV1 to quickly workaround Truffle's singleton feature when deploying contracts.
 * This allows us to have both contract versions deployed at the same time.
 */
contract MySmartContractV1 {
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

  constructor() public {
    counter = 0;
    // Sets the contract's owner as the address that deployed the contract.
    owner = msg.sender;
  }

  /**
  @notice Increments the contract's counter if contract is active.
  @dev It will revert is the contract is stopped. See modifier "isNotStopped"
   */
  function incrementCounter() isNotStopped public {
    counter += 2; // This is an intentional bug.
  }

  /**
  @dev Stops / Unstops the contract.
   */
  function toggleContractStopped() isOwner public {
      stopped = !stopped;
  }
}
