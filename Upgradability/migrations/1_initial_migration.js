const Migrations = artifacts.require("Migrations");
const MySmartContractV1 = artifacts.require("MySmartContractV1");
const MySmartContractV2 = artifacts.require("MySmartContract");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(MySmartContractV1);
  deployer.deploy(MySmartContractV2, 100);
};
