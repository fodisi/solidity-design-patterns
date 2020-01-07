# Proxy Patterns


## Introduction
Proxy Patterns are frequently used to facilitate and improve smart contract's upgradability. There's a couple of different approaches when it comes to Proxy Patterns:

- Simple Proxy
- Delegate Proxy
- Structured Storage Proxy
- Unstructured Storage Proxy
- Transparent Proxy

If you're not familiar with how and when Proxy Patterns can be used to help creating upgradable smart contracts, take a look at this [article](../upgradability/readme.md). It describes some common challenges in upgrading smart contracts and highlights some patterns, including Proxies, that can be usefull under certain scenarios.


## How to Choose a Proxy Pattern
Proxy Patterns can be really helpful, but there isn't an unique recipe to be followed to determine which pattern you should use (if you should use one). Every proxy type has its own pros and cons, different levels of complexity, required knowledge, risks and costs associated with it.

The best way to choose a proxy pattern (and other design patterns too) is to understand the scenario in which your smart contract will be used - it's business rules, actors, complexity, usage, requirements, etc. A few questions can help you gather more information about the scenario in order to identify the best type of proxy pattern:

1. What's the use case, and complexity of it, in which the smart contract will be used?
  
    Is this a smart contract responsible for handling financial transactions, stroring sensitive data or data that somehow is regulated, or is it just being used on a proof of concept or another scenario without risks of losing money or not complying with some law?

2. What's the expected frequency that the smart contract will be upgraded?

    Is it based on some "battle tested" and/or stable code or is it implementing something completely new (that still needs to go through scrutiny to be proved "bug free in the wild")?

3. Does the new version of the contract depends on the state of the previous one?

    Do you need to keep the old data every time you deploy a new version or can the smart contract state can be re-initialized? And if you need to keep the data between the versions, how complex is the contract's state? Just a couple of [value types](https://solidity.readthedocs.io/en/v0.4.21/types.html#value-types) state variables or a more complex state composed of value and [reference types](https://solidity.readthedocs.io/en/v0.4.21/types.html#reference-types)?

4. Can your smart contract have more than one active version on the blockchain?

    If some client calls a method of Version 1 of your smart contract, should it fail, execute wherever the method is intended to do, or somehow _forward_ the call to the newest version?




