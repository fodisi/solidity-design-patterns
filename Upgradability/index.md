# Upgradable Smart Contracts

When developing software, it's quite frequent the releasing of new versions of the software to add new functionalities or fix bugs. It is no different when it comes to smart contract development. However, updating a smart contract to a new version is usually not as simple as updating other types of software.

Most Blockchains, especially public ones like Ethereum, implement the intrinsic concept of immutability, which in theory, does not allow anyone to change the blockchain's "past". The immutability is applied to all transactions in the blockchain, including transactions used to deploy smart contracts and the associated code. In other words, once the smart contract's code is deployed to the blockchain, it will "live" forever "AS IS" - no one can change it. If a bug is found or a new functionality needs to be added, we cannot replace the source code of this specific deployed contract.

But, if a smart contract is immutable, how are you able to upgrade it to newer versions? The answer lies in deploying a new smart contract (and preferably disabling the first one). But this approach raises a couple of problems and challenges that need to be addressed. You'll see below three common topics:
- All clients need to be updated to reference the address of the new contract's version
- Disable the first contract's version so no one will continue using it
- Analyze the need to copy the data (state) from the first contract into the new contract (updated version)

In order to better illustrate these problems, in the next sections we'll reference Version 1 and Version 2 of `MySmartContract`, as below:

**Version 1**
```
contract MySmartContract {
  uint32 public counter;

  constructor() public {
    counter = 0;
  }

  function incrementCounter() public {
    counter += 2; // This bug is intentional in this version.
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


## Update All Clients to Reference New Address
When deployed to the blockchain, every instance of the smart contract is assigned to a unique address. This address is used to reference the smart contract's instance in order to invoke its methods and read/write data from/to the contract's storage. When we deploy an updated version of the contract to the blockchain, the new instance of the contract will be deployed at a new address. This new address is completely different from the first contract's address. This means that all clients, other smart contracts and/or dApps (decentralized applications), that interact with the smart contract will need to be updated, so they can use the address of the most up to date contract.

So, let's consider the following scenario:

You created `MySmartContract` with the code above. The `Version 1` of `MySmartContract` is deployed to the blockchain at address `A1` (this is not a real Ethereum address - used only for explanation purposes). All clients (smart contracts and/or dApps) that want to interact `Version 1` need to use the address `A1` to reference it.

Now, after a while, we noticed the bug in the method `incrementCounter`: it is incrementing the counter by 2, instead of 1. So a fix is required, resulting in `Version 2` of `MySmartContract`. `Version 2` is deployed then to the blockchain at address `D5`. At this point, you probably realized that if you want to interact with `Version 2`, you'll need to use the address `D5`, not `A1`. This is the reason why all clients that are interacting with `MySmartContract` will need to be updated as well.

You probably agree that having to update all other clients may be quite burdensome. Luckily, some design patterns, including Proxy Patterns, can help you. You'll see more about it in a following section.

## Disabling Version 1 of the Contract
We learned in the section above that all clients would need to be updated so they would use `Version 2`'s address (`D5`), not `Version 1` (`A1`). In some cases, there's no way to enforce all the clients to update at the same time to use the new address (`D5`). But, you could implement some technique to avoid `Version 1` from being used after it is deprecated. In other words, you could **stop** `MySmartContract`'s `Version 1`. This technique is implemented by the Design Pattern named *Circuit Breaker*. It's also commonly refer to as *Pausable Contracts* or *Emergency Stop*.

A *Circuit Breaker*, in general terms, stops a smart contract functionalities. Additionally, it can enable specific functionalities that should be available only when the contract is stopped. *Circuit Breakers* commonly implement some sort of [access restriction](https://solidity.readthedocs.io/en/latest/common-patterns.html#restricting-access), so only allowed actors (like an admin / owner) have permission to trigger the circuit breaker and stop the contract. Some scenarios where this pattern can be used are:
- Stopping a contract's functionalities when a bug is found
- Stop some contract's functionalities after a certain state is reached (frequently used together with a [State Machine](https://solidity.readthedocs.io/en/latest/common-patterns.html#state-machine) pattern)
- Stop the contract's functionalities during upgrades processes, so external actors cannot change the contract's state during the upgrade;
- Stop a deprecated version of a contract after a new version is deployed (this is what we're learning here)

 To learn more about *Circuit Breakers*, check our this Consensys' [post](https://consensys.github.io/smart-contract-best-practices/software_engineering/#circuit-breakers-pause-contract-functionality) and OpenZeppelin's reference implementation of [Pausable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/lifecycle/Pausable.sol) contract.


Now let's see how you could implement a *Circuit Breaker* to stop `MySmartContract`'s `incrementCounter` function, so `counter` wouldn't change during the migration process. This modification would need to be in place in `Version 1`, when it was deployed.

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

In the code above you can see that `Version 1` of `MySmartContract` now implements a modifier `isNotStopped`. This modifier will revert the transaction if the contract is stopped. The function `incrementCounter` was changed to use the modifier `isNotStopped`, so it will only execute when the contract is not stopped.

With this implementation, right before the migration starts, the owner of the contract can invoke the function `toggleContractStopped` to stop the contract. Note that this function uses the modifier `isOwner` to restrict access to the contract's owner.


## Contract's Storage Migration
Most smart contracts need to keep some sort of state in its internal storage. The number fo state variables required by each contract varies greatly depending on the use case. In our example, `MySmartContract`'s `Version 1` has a single state variable `counter`.

Now consider that `Version 1` of `MySmartContract` has been in use for a while. By the time you find the bug in `incrementCounter` function, the value of `counter` is already `100`. This scenario would raise some questions:
- What will you do with the state of `MySmartContract Version 2`?
- Can you reset the counter to 0 (zero) on `Version 2` or should you keep the state from `Version 1` (so `counter` is initialized with `100`)?

The answers to these questions depends on the use case. In our example, a really simple scenario, we wouldn't have any issues if counter was reset to `0`. However, in most cases this is not the desired approach.

Let's suppose you cannot reset the value to `0`, but need to set `counter` to `100` in `Version 2`. In a simple contract as `MySmartContract`, this wouldn't be difficult. You could change the constructor of `Version 2` to receive the initial value of `counter` as a parameter. At deployment, you would pass the value `100` to the constructor, and this would solve your problem. After implementing this approach, the constructor of `MySmartContract Version 2` would look like this:

```
  constructor(uint32 _counter) public {
    counter = _counter;
  }
```

If your use case is somewhat as simple as this (or similar), that's probably the way to go from a data migration standpoint. The complexity of implementing other approaches wouldn't be worth it. However, bear in mind that most production-ready smart contracts are not as simple as `MySmartContract` and frequently have a more complex state.

Assume a contract that uses multiple `structs`, `mappings`, and `arrays`. Copying all the data from `Version 1`'s state and writing it to `Version 2`'s would require at least:
- A bunch of transactions to be processed on the blockchain, which may take a considerable amount of time, depending on the data set
- Additional code to handle reading data from `Version 1` and writing it to `Version 2` (unless done manually)
- Spend real money to pay for gas. Remember that you need to pay gas to process transactions to the blockchain
- Freeze `Version 1`'s state by using some mechanism (as a *Circuit Break*) to make sure no more data is appended to `Version 1` during the migration.
- Implement access restriction mechanisms to restrict external parties (not related to the migration) from invoking functions of `Version 2` during the migration. This would be required to make sure `Version 1`'s data could be copied to `Version 2` without being compromised and/or corrupted in `Version 2`;

In contracts with a more complex state, the work required to perform an upgrade is quite significant, and can incur in considerable gas costs to copy data over the blockchain. Using [Libraries](https://solidity.readthedocs.io/en/latest/contracts.html#libraries) and [Proxies](**ADD LINK HERE TO MY ARTICLE**) can help you develop smart contracts that are easier to upgrade. With this approach, the data would be kept in a contract that stores the state but bears no logic (*state contract*). The second contract or library implements the logic, but bears no state* (*logic contract*). So when a bug is found in the logic, you only need to upgrade the *logic contract*, without worrying about migrating the state stored in the *state contract*.


\* This approach generally uses [Delegatecall](https://solidity.readthedocs.io/en/latest/introduction-to-smart-contracts.html#delegatecall-callcode-and-libraries). The *state contract* invokes the functions in the *logic contract* using *delegatecall*. The *logic contract* then executes its logic in the context of *state contract*, which means that *"storage, current address and balance still refer to the calling contract, only the code is taken from the called address."* (from Solidity docs).


## Conclusion
The principle of upgradable smart contracts is described in the Ethereum white paper's [DAO section](https://github.com/ethereum/wiki/wiki/White-Paper#decentralized-autonomous-organizations) that reads:

"*Although code is theoretically immutable, one can easily get around this and have de-facto mutability by having chunks of the code in separate contracts, and having the address of which contracts to call stored in the modifiable storage.
*"

Although it is achievable, upgrading smart contracts can be quite challenging. The immutability of the blockchain adds more complexity to smart contract's upgrades because it forces you to carefully analyze the scenario in which the smart contract will be used, understand the available mechanisms, and then decide which mechanisms are a good fit to your contract, so a potential and probable upgrade will be smooth.

Smart Contract upgradability is an active area of research. Related patterns, mechanisms and best practices are still under continuous discussion and development. Using *Libraries* and some Design Patterns like *Circuit Breaker*, *Access Restriction*, *Proxy* can help you to tackle some of the challenges. However, in more complex scenarios, these mechanisms alone may not be able to address all the issues, and you may need to consider other patterns like [Registry](https://consensys.github.io/smart-contract-best-practices/software_engineering/#upgrading-broken-contracts) or [Eternal Storage](https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/), not mentioned in this article.


Using *Libraries* and implementing design pattern that focus on upgradability are aligned with this principle and  Implementing 
 


