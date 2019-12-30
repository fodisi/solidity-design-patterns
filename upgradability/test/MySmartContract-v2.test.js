const {expect} = require("chai");
const {expectRevert} = require("openzeppelin-test-helpers");


const MySmartContract = artifacts.require("MySmartContract");

// This tests version 2 of MySmartContract.
contract("MySmartContract", function([_, deployer ]) {

  it("sets counter value on deployment", async function() {
    this.contract = await MySmartContract.new(10, {from: deployer});

    let counter = await this.contract.counter.call();
    expect(counter.toNumber()).to.equal(10);

  });


  it("increments counter by one", async function() {
    this.contract = await MySmartContract.new(0, {from: deployer});

    await this.contract.incrementCounter();
    let counter = await this.contract.counter.call();
    expect(counter.toNumber()).to.equal(1);

    await this.contract.incrementCounter();
    counter = await this.contract.counter.call();
    expect(counter.toNumber()).to.equal(2);
  });

  it("reverts when stopped", async function() {
    this.contract = await MySmartContract.new(0, {from: deployer});
    await this.contract.toggleContractStopped({from: deployer});
    await expectRevert(this.contract.incrementCounter(), "Contract is stopped.");
  });

});
