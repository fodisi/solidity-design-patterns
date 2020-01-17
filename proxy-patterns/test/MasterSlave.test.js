const {expect} = require("chai");

const MasterContract = artifacts.require("MasterCaller");
const SlaveContract = artifacts.require("SlaveCallee");

contract("MasterSlaveProxy", function([_, deployer ]) {

  it("gets and sets value", async function() {
    this.masterContract = await MasterContract.new({from: deployer});
    await this.masterContract.upgradeSlave(SlaveContract.address);

    await this.masterContract.setValue(100);
    let value = await this.masterContract.getValue();
    expect(value.toNumber()).to.equal(100);
  });

});