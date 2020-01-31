# Upgradable Smart Contracts

When developing software, it's quite frequent the releasing of new versions to add new functionalities or bug fixes. There's no difference when it comes to smart contract development. Although, updating a smart contract to a new version is usually not as simple as updating other types of software of the same complexity.

Most Blockchains, especially public ones like Ethereum, implement the intrinsic concept of immutability, which in theory, does not allow anyone to change the blockchain's "past". The immutability is applied to all transactions in the blockchain, including transactions used to deploy smart contracts and the associated code. In other words, once the smart contract's code is deployed to the blockchain, it will "live" forever "AS IS" - no one can change it. If a bug is found or a new functionality needs to be added, we cannot replace the code of a deployed contract.

But, if a smart contract is immutable, how are you able to upgrade it to newer versions? The answer lies in deploying a new smart contract to the blockchain.

But this approach raises a couple of challenges that need to be addressed. The most basic and common ones are:
- All users that use the smart contract need to reference the address of the new contract's version
- The first contract's version should be disabled, enforcing every user to use the new version
- Usually, you need to make sure the data (state) from the old version is migrated or somehow available to the new version. In the most simple scenario, this means you need to copy/migrate the state from the old version to the new contract's version

The sections below describe these challenges in more detail. To better illustrate it, we'll use the two versions below of `MySmartContract` as a reference:

**Version 1**
```
contract MySmartContract {
  uint32 public counter;

  constructor() public {
    counter = 0;
  }

  function incrementCounter() public {
    counter += 2; // This "bug" is intentional.
  }
}
```

**Version 2**
```
contract MySmartContract {
  uint32 public counter;

  constructor(uint32 _counter) public {
    counter = _counter;
  }

  function incrementCounter() public {
    counter++;
  }
}
```


## Users to Reference the New Contract's Address
When deployed to the blockchain, every instance of the smart contract is assigned to a unique address. This address is used to reference the smart contract's instance in order to invoke its methods and read/write data from/to the contract's storage (state). When you deploy an updated version of the contract to the blockchain, the new instance of the contract will be deployed at a new address. This new address is different from the first contract's address. This means that all users, other smart contracts and/or dApps (decentralized applications) that interact with the smart contract will need to be updated so they use the address of the updated version. Spoiler: there are some options to avoid this issue, that you’ll see at the end of this section.

So, let's consider the following scenario:

You created `MySmartContract` using the code of `Version 1` above. It is deployed to the blockchain at address `A1` (this is not a real Ethereum address - used only for illustration purposes). All users that want to interact with `Version 1` need to use the address `A1` to reference it.

Now, after a while, we noticed the bug in the method `incrementCounter`: it is incrementing the counter by 2, instead of incrementing it by 1. A fix is implemented, resulting in `Version 2` of `MySmartContract`. This new contract's version is deployed to the blockchain at address `D5`. At this point, if a user wants to interact with `Version 2`, it needs to use the address `D5`, not `A1`. This is the reason why all users that are interacting with `MySmartContract` will need to update so they refer to the new address `D5`.

You probably agree that forcing users to update is not the best approach, considering that updating a smart contract's version should be as transparent as possible to users using it.

There are different strategies that can be used to address this problem. Some design patterns like [Registry](https://consensys.github.io/smart-contract-best-practices/software_engineering/#upgrading-broken-contracts), different types of [Proxies](https://blog.openzeppelin.com/proxy-patterns/) can be used to make it easier to upgrade and provide transparency to users. Another great option is to use the [Ethereum Name Service](https://ens.domains/) and register a user-friend name that resolves to your contract’s address. With this option, users of the contract don’t need to know the contract’s address, only its user-friendly name. As a result, upgrading to a new address would be transparent to your contract’s users.

The specific strategy to be used depends on the scenario the smart contract will be used.


## Disabling Old Versions of the Contract
We learned in the section above that all users would need an update to use `Version 2`'s address (`D5`) or our contract should implement some mechanism to make this process transparent to users. Despite that, if you're the owner of the contract, you probably want to enforce that all users use only the most up to date version `D5`. If a user inadvertently or not  uses `A1`, you want to guarantee that `Version 1` is deprecated and unavailable for usage.

In such scenarios, you could implement a technique to **stop** `MySmartContract`'s `Version 1`. This technique is implemented by a Design Pattern named [Circuit Breaker](https://consensys.github.io/smart-contract-best-practices/software_engineering/#circuit-breakers-pause-contract-functionality). It's also commonly referred to as *Pausable Contracts* or *Emergency Stop*.

A Circuit Breaker, in general terms, stops a smart contract functionalities. Additionally, it can enable specific functionalities that will be available only when the contract is stopped. This pattern commonly implements some sort of [access restriction](https://solidity.readthedocs.io/en/latest/common-patterns.html#restricting-access), so only allowed actors (like an admin or owner) have the required permission to trigger the Circuit Breaker and stop the contract.

Some scenarios where this pattern can be used are:
- Stopping a contract's functionalities when a bug is found
- Stop some contract's functionalities after a certain state is reached (frequently used together with a [State Machine](https://solidity.readthedocs.io/en/latest/common-patterns.html#state-machine) pattern)
- Stop the contract's functionalities during upgrades processes, so external actors cannot change the contract's state during the upgrade;
- Stop a deprecated version of a contract after a new version is deployed

Now let's see how you could implement a Circuit Breaker to stop `MySmartContract`'s `incrementCounter` function, so `counter` wouldn't change during the migration process. This modification would need to be in place in `Version 1`, when it was first deployed.

```
// Version 1 implementing a Circuit Breaker with access restriction to owner
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

  constructor() public {
    counter = 0;
    // Sets the contract's owner as the address that deployed the contract.
    owner = msg.sender;
  }

  /**
  @notice Increments the contract's counter if contract is active.
  @dev It will revert if the contract is stopped. See modifier "isNotStopped"
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
```

In the code above you can see that `Version 1` of `MySmartContract` now implements a modifier `isNotStopped`. This modifier will revert the transaction if the contract is stopped. The function `incrementCounter` was changed to use the modifier `isNotStopped`, so it will only execute when the contract is NOT stopped.

With this implementation, right before the migration starts, the owner of the contract can invoke the function `toggleContractStopped` and stop the contract. Note that this function uses the modifier `isOwner` to restrict access to the contract's owner.

To learn more about Circuit Breakers, make sure you check Consensys' post about [Circuit Breakers](https://consensys.github.io/smart-contract-best-practices/software_engineering/#circuit-breakers-pause-contract-functionality) and OpenZeppelin's reference implementation of [Pausable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/lifecycle/Pausable.sol) contracts.


## Contract's Data (State) Migration
Most smart contracts need to keep some sort of state in its internal storage. The number of state variables required by each contract varies greatly depending on the use case. In our example, the original `MySmartContract`'s `Version 1` has a single state variable `counter`.

Now consider that `Version 1` of `MySmartContract` has been in use for a while. By the time you find the bug in `incrementCounter` function, the value of `counter` is already at `100`. This scenario would raise some questions:
- What will you do with the state of `MySmartContract Version 2`?
- Can you reset the counter to 0 (zero) in `Version 2` or should you migrate the state from `Version 1` to make sure `counter` is initialized with `100` in `Version 2`?

The answers to these questions will depend on the use case. In the example of this article, which is a really simple scenario and `counter` has no important usage, you wouldn't have any issues if `counter` is reset to `0`. But, this is not the desired approach in most cases.

Let's suppose you cannot reset the value to `0` and need to set `counter` to `100` in `Version 2`. In a simple contract as `MySmartContract` this wouldn't be difficult. You could change the constructor of `Version 2` to receive the initial value of `counter` as a parameter. At deployment, you would pass the value `100` to the constructor, and this would solve your problem.

After implementing this approach, the constructor of `MySmartContract Version 2` would look like this:

```
  constructor(uint32 _counter) public {
    counter = _counter;
  }
```

If your use case is as simple as presented above (or similar), this is probably the way to go from a data migration perspective. The complexity of implementing other approaches wouldn't be worth it. But, bear in mind that most production-ready smart contracts are not as simple as `MySmartContract` and frequently have a more complex state.

Now consider a contract that uses multiple [structs](https://solidity.readthedocs.io/en/latest/types.html#structs), [mappings](https://solidity.readthedocs.io/en/latest/types.html#mapping-types), and [arrays](https://solidity.readthedocs.io/en/latest/types.html#arrays). If you need to copy data between contract versions with such complex storage, you would probably face one or more the challenges below:
- A bunch of transactions to be processed on the blockchain, which may take a considerable amount of time, depending on the data set
- Additional code to handle reading data from "`Version 1`" and writing it to "`Version 2`" (unless done manually)
- Spend real money to pay for gas. Remember that you need to pay gas to process transactions in the blockchain. According to the [Ethereum Yellow Paper - Appendix G. Fee Schedule](https://ethereum.github.io/yellowpaper/paper.pdf), the `SSTORE` operation, upcode used to write data to Ethereum, costs 20000 [gas units](https://solidity.readthedocs.io/en/latest/introduction-to-smart-contracts.html#gas) *"when the storage value is set to non-zero from zero"* and 5000 [gas units](https://solidity.readthedocs.io/en/latest/introduction-to-smart-contracts.html#gas) *"when storage value’s zeroness remains unchanged"*.
- Freeze `Version 1`'s state by using some mechanism (like a Circuit Breaker) to make sure no more data is appended to `Version 1` during the migration.
- Implement access restriction mechanisms to avoid external parties (not related to the migration) from invoking functions of `Version 2` during the migration. This would be required to make sure `Version 1`'s data could be copied/migrated to `Version 2` without being compromised and/or corrupted in `Version 2`;

In contracts with a more complex state, the work required to perform an upgrade is quite significant, and can incur considerable gas costs to copy data over the blockchain. Using [Libraries](https://solidity.readthedocs.io/en/latest/contracts.html#libraries) and [Proxies](https://blog.openzeppelin.com/proxy-patterns/) can help you develop smart contracts that are easier to upgrade. With this approach, the data would be kept in a contract that stores the state but bears no logic (*state contract*). The second contract or library implements the logic, but bears no state (*logic contract*). So when a bug is found in the logic, you only need to upgrade the *logic contract*, without worrying about migrating the state stored in the *state contract* (see *Note* below).


*Note:* This approach generally uses [Delegatecall](https://solidity.readthedocs.io/en/latest/introduction-to-smart-contracts.html#delegatecall-callcode-and-libraries). The *state contract* invokes the functions in the *logic contract* using *delegatecall*. The *logic contract* then executes its logic in the context of *state contract*, which means that *"storage, current address and balance still refer to the calling contract, only the code is taken from the called address."* (from Solidity docs referenced above).

## Making `MySmartContract` Easier to Upgrade
Below you can see how `Version 1` and `Version 2` would look like if we implement the changes described here in this article. It's important to mention again that the strategies used for `MySmartContract` are acceptable considering its simplicity: state variables and logic.

First, let's see `Version 1` changes:

**Version 1 - Without Upgradable Mechanisms**
```
contract MySmartContract {
  uint32 public counter;

  constructor() public {
    counter = 0;
  }

  function incrementCounter() public {
    counter += 2; // This "bug" is intentional.
  }
}
```

In the code below, `Version 1` implements a [Circuit Breaker](https://consensys.github.io/smart-contract-best-practices/software_engineering/#circuit-breakers-pause-contract-functionality) with an [Access Restriction](https://solidity.readthedocs.io/en/latest/common-patterns.html#restricting-access) mechanism that allows the owner to stop the contract once it is deprecated.

**Version 1 - With Deprecation Mechanism**
```
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
```

Now let's see how `Version 2` would look like:
**Version 2 - Without Upgradable Mechanisms**
```
contract MySmartContract {
  uint32 public counter;

  constructor(uint32 _counter) public {
    counter = _counter;
  }

  function incrementCounter() public {
    counter++;
  }
}
```

In the code below `Version 2` implements the same [Circuit Breaker](https://consensys.github.io/smart-contract-best-practices/software_engineering/#circuit-breakers-pause-contract-functionality) and [Access Restriction](https://solidity.readthedocs.io/en/latest/common-patterns.html#restricting-access) mechanisms as `Version 1`. In addition, it implements a constructor that allows setting the initial value of `counter` during deployment. This mechanism can be used, which can be used during an upgrade to copy data from an old version.

**Version 2 - With Simple Upgradable Mechanism**
```
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
```

Although the changes above implement some mechanisms that help upgrading smart contracts, the first challenge described in the beginning of this article, *Users to Reference the New Contract's Address*, is not solved with these simple techniques. More advanced patterns like [Proxies](https://blog.openzeppelin.com/proxy-patterns/) and [Registry](https://consensys.github.io/smart-contract-best-practices/software_engineering/#upgrading-broken-contracts), or using the [ENS](https://ens.domains/) to register a user-friendly name to your contract,  would be required to avoid all users from upgrading to reference the new address of `Version 2`.


## Conclusion
The principle of upgradable smart contracts is described in the Ethereum white paper's [DAO section](https://github.com/ethereum/wiki/wiki/White-Paper#decentralized-autonomous-organizations) that reads:

"*Although code is theoretically immutable, one can easily get around this and have de-facto mutability by having chunks of the code in separate contracts, and having the address of which contracts to call stored in the modifiable storage.
*"

Although it is achievable, upgrading smart contracts can be quite challenging. The immutability of the blockchain adds more complexity to smart contract's upgrades because it forces you to carefully analyze the scenario in which the smart contract will be used, understand the available mechanisms, and then decide which mechanisms are a good fit to your contract, so a potential and probable upgrade will be smooth.

Smart Contract upgradability is an active area of research. Related patterns, mechanisms and best practices are still under continuous discussion and development. Using *Libraries* and some Design Patterns like [Circuit Breaker](https://consensys.github.io/smart-contract-best-practices/software_engineering/#circuit-breakers-pause-contract-functionality), [Access Restriction](https://solidity.readthedocs.io/en/latest/common-patterns.html#restricting-access), [Proxies](https://blog.openzeppelin.com/proxy-patterns/) and [Registry](https://consensys.github.io/smart-contract-best-practices/software_engineering/#upgrading-broken-contracts) can help you to tackle some of the challenges. However, in more complex scenarios, these mechanisms alone may not be able to address all the issues, and you may need to consider more complex patterns like [Eternal Storage](https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/), not mentioned in this article.

You can check the full source code, including related unit tests (not mentioned in this article for simplicity reasons), as well as other patterns and best practices in this [github repository](https://github.com/fodisi/solidity-design-patterns).



