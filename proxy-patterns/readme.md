# Proxy Patterns


## Introduction
Proxy Patterns are frequently used to facilitate and improve smart contract's upgradability. There's a couple of different approaches when it comes to Proxy Patterns:

- Simple Proxy
- Delegate Proxy
- Structured Storage Proxy
- Unstructured Storage Proxy
- Transparent Proxy

Before we dive into each type of Proxy, take a look at this [article](../Upgradability/index.md) to better understand what are the problems (or at least the most common ones) with smart contract's upgradability that Proxy Patterns try to solve.


## How to Choose a Proxy Pattern
Although design patterns are really helpful, there's no recipe or such thing as "one size fits all". Every approach has generally pros and cons, different levels of complexity, risks and costs associated. The best way to choose a design pattern (or sometimes, a set of them), is to better understand the scenario in which the smart contract will be used - it's business rules, actors, and other requirements. A few questions can help us gather more information about the scenario and help us identify the best patterns:

1. What's the use case, and complexity of it, in which the smart contract will be used?
  
    Is this a smart contract responsible for handling financial transactions, stroring sensitive data or data that somehow is regulated, or is it just being used on a proof of concept or another scenario without risks of losing money or not complying with some law?

2. What's the expected frequency that the smart contract will be upgraded?

    Is it based on some "battle tested" and/or stable code or is it implementing something completely new that still needs to go through scrutiny to prove it is bug free in the "wild"?

3. Does the new version of the contract depends on state of the previous one?

    Do you need to keep the old data every time you deploy a new version or can the smart contract state can be re-initialized? And if you need to keep the data between the versions, how complex is the contract's state? Just a couple of [value types](https://solidity.readthedocs.io/en/v0.4.21/types.html#value-types) state variables or a more complex state composed of value and [reference types](https://solidity.readthedocs.io/en/v0.4.21/types.html#reference-types)?

4. Should your smart contract have more than one active version on the blockchain?

    If some client calls a method of Version 1 of your smart contract, should it fail, execute wherever the method is intended to do or somehow _forward_ the call to the new version?




