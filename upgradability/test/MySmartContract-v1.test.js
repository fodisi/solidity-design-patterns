const {expect} = require("chai");
const {expectRevert} = require("openzeppelin-test-helpers");


const MySmartContract = artifacts.require("MySmartContractV1");

// This tests version 1 of MySmartContract.
contract("MySmartContract", function([_, deployer ]) {

  it("increments counter", async function() {
    this.contract = await MySmartContract.new({from: deployer});

    await this.contract.incrementCounter();
    let counter = await this.contract.counter.call();
    expect(counter.toNumber()).to.equal(2);

    await this.contract.incrementCounter();
    counter = await this.contract.counter.call();
    expect(counter.toNumber()).to.equal(4);
  });

  it("reverts when stopped", async function() {
    this.contract = await MySmartContract.new({from: deployer});
    await this.contract.toggleContractPaused({from: deployer});
    await expectRevert(this.contract.incrementCounter(), "Contract is stopped.");
  });

});