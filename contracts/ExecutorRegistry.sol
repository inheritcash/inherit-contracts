pragma solidity ^0.5.8;

import "./IExecutorRegistry.sol";
import "./tokens/ERC20Interface.sol";
import "./ownership/Ownable.sol";

// The ExecutorRegistry is just a quick way for the app to find already active contract for a user needing an executor contract
// The registry includes users that have paid to use the service, and have a unique identifier

contract ExecutorRegistry is IExecutorRegistry, Ownable {

  mapping(string => address) private uniqueNameToUser;
  mapping(address => address) private userToExecutorContractMapping;

  uint256 public registrationFee;

  modifier onlyDistinctUser(address user) {
    require((user == msg.sender) || (user == tx.origin) ||(userToExecutorContractMapping[user] == msg.sender),"User dn correspond");
    _;
  }

  constructor (uint256 _registrationFee) public {
    registrationFee = _registrationFee;
  }

  function onlyDistinctName(address user, string memory uniqueNameForUser) internal view returns (bool success) {
    return ((uniqueNameToUser[uniqueNameForUser] == user) || (uniqueNameToUser[uniqueNameForUser] == address(0))) ;
  }

  function addOrUpdateExecutorContractRegistry(address user, string calldata uniqueNameForUser, address executorContract) external payable onlyDistinctUser(user) returns (bool success) {
      require(onlyDistinctName(user, uniqueNameForUser), "Name taken");

      // Pay to register name only once. You can self destruct and remove the executor and after add a new one with new name
      if((uniqueNameToUser[uniqueNameForUser] == address(0))) {
        require(msg.value == registrationFee * 1 szabo, "Exact registration fee not provided");
        require(owner.send(msg.value));
      }
      userToExecutorContractMapping[user] = executorContract;
      uniqueNameToUser[uniqueNameForUser] = user;
      return true;
    }

  function removeSpecificUserFromContractRegistry(address user) external onlyDistinctUser(user) returns (bool success) {
      delete userToExecutorContractMapping[user];
      return true;
  }

  function getExecutorContract(address user) external view returns (address executor) {
      return userToExecutorContractMapping[user];
  }

  function getExecutorContractFromUniqueName(string calldata uniqueName) external view returns (address executor) {
      return userToExecutorContractMapping[uniqueNameToUser[uniqueName]];
  }

  function changeRegistrationFee(uint256 _newFee) external onlyOwner {
    registrationFee = _newFee;
  }

  // IMPORTANT THIS IS A NUMBER OF SZABO
  function getRegistrationFee() external view returns (uint256 fee){
    return registrationFee;
  }

  //Utilities
  function reclaimERC20(address _tokenContract) external onlyOwner {
    require(_tokenContract != address(0), "Invalid address");
    ERC20Interface token = ERC20Interface(_tokenContract);
    uint256 balance = token.balanceOf(address(this));
    require(token.transfer(msg.sender, balance), "Transfer failed");
  }

  function reclaimETH() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}
