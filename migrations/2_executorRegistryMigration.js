const ExecutorRegistry = artifacts.require('./ExecutorRegistry.sol');

module.exports = function(deployer) {
  deployer.deploy(ExecutorRegistry, 100000); // 0.1 ETH Reg Fee
};
