pragma solidity ^0.5.8;

// The Interface for an Executor Registry

interface IExecutorRegistry {
  function addOrUpdateExecutorContractRegistry(address user, string calldata uniqueNameForUser, address executorContract) external payable returns (bool success);

  function removeSpecificUserFromContractRegistry(address user) external returns (bool success);

  function getExecutorContract(address user) external view returns (address executor);

  function getExecutorContractFromUniqueName(string calldata uniqueName) external view returns (address executor);

  function getRegistrationFee() external view returns (uint256 fee);
}
