pragma solidity ^0.5.8;

// The ExecutorRegistry is just a quick way for the app to find already active contract for a user needing an executor contract
// The registry requires no admin or maintenance but can be added in the future

contract ExecutorRegistry {

  mapping(string => address) private uniqueNameToUser;
  mapping(address => address) private userToExecutorContractMapping;

  function onlyDistinctUser(address user) public view returns (bool success) {
    return (user == msg.sender) || (user == tx.origin);
  }

  function onlyDistinctName(address user, string memory uniqueNameForUser) public view returns (bool success) {
    return ((uniqueNameToUser[uniqueNameForUser] == user) || (uniqueNameToUser[uniqueNameForUser] == address(0))) ;
  }


  function addOrUpdateExecutorContractRegistry(address user, string memory uniqueNameForUser, address executorContract) public returns (bool success) {
      require(onlyDistinctUser(user));
      require(onlyDistinctName(user, uniqueNameForUser));
      userToExecutorContractMapping[user] = executorContract;
      uniqueNameToUser[uniqueNameForUser] = user;
      return true;
    }

  function removeSpecificUserFromContractRegistry(address user) public returns (bool success) {
      require(onlyDistinctUser(user));
      delete userToExecutorContractMapping[user]; 
      return true;
  }

  function getExecutorContract(address user) public view returns (address executor) {
      return userToExecutorContractMapping[user];
  }

  function getExecutorContractFromUniqueName(string memory uniqueName) public view returns (address executor) {
      return userToExecutorContractMapping[uniqueNameToUser[uniqueName]];
  }
}
