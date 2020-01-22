pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
 // https://github.com/OpenZeppelin/openzeppelin-labs/blob/master/upgradeability_using_eternal_storage/contracts/Proxy.sol
contract Proxy {
  address internal impl;

  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  fallback() payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      // gets next available free memory pointer
      let ptr := mload(0x40)
      // copycalldata of size calldatasize starting from 0 of call data to location at ptr
      calldatacopy(ptr, 0, calldatasize)
      // calls the contract at "_impl" address, passing the ptr where data
      // is stored, and the size of the call data. Stores the result
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      // gets the size of the result
      let size := returndatasize
      // copies returned data of "size" to the "ptr" variable
      returndatacopy(ptr, 0, size)

      // reverts or returns data stored at "ptr"
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}