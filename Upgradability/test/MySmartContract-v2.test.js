const {expect} = require("chai");

const MySmartContract = artifacts.require("MySmartContract");

// This tests version 2 of MySmartContract.
contract("MySmartContract", function([_, deployer ]) {

  it("increments counter", async function() {
    this.contract = await MySmartContract.new(100, {from: deployer});
    
    await this.contract.incrementCounter();
    let counter = await this.contract.counter.call();
    expect(counter.toNumber()).to.equal(101);

    await this.contract.incrementCounter();
    counter = await this.contract.counter.call();
    expect(counter.toNumber()).to.equal(102);
  });

});
