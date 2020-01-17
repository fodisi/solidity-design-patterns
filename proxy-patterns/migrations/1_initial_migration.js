const Migrations = artifacts.require("Migrations");
const Slave = artifacts.require("SlaveCallee");
const Master = artifacts.require("MasterCaller");

module.exports = async function(deployer) {
  await deployer.deploy(Migrations);
  await deployer.deploy(Slave);
  await deployer.deploy(Master);
  const masterContract = await Master.deployed();
  await masterContract.upgradeSlave(
    Slave.address,
    { gas: 200000 }
  );

};
