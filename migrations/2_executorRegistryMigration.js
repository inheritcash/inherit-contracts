const ExecutorRegistry = artifacts.require('./ExecutorRegistry.sol');

module.exports = function(deployer) {
  deployer.deploy(ExecutorRegistry);
};
