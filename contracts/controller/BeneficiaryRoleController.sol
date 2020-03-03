pragma solidity ^0.5.8;

import "./DeadOrAliveController.sol";

contract BeneficiaryRoleController is DeadOrAliveController {
  // This smart contract will hold list of beneficiaries
  struct Beneficiary {
      bytes32 nickname;
      bytes32 email;
      uint256 index;
      mapping(address => uint256) erc20TokenBalanceHasWithdrawn; // Record erc20 balance when withdrawn
      uint256 ethHasWithdrawn; // Record ETH balance when withdrawn
      uint256 share; // Number corresponds to share% / 100 , use sumShares anyways to ensure it doesn't need to be out of 100
  }

  address[] private userIndex;
  mapping(address => Beneficiary) public userStructs;
  address public defaultErc721ApprovedUser;

  event BeneficiaryAdded(address indexed beneficiary, bytes32 indexed nickname, bytes32 indexed email, uint index);
  event BeneficiaryRemoved(address indexed beneficiary, uint index);
  event BeneficiaryUpdated(address indexed beneficiary, bytes32 indexed nickname, bytes32 indexed email, uint index);

 modifier onlyBeneficiary() {
       require(checkIfBeneficiary(msg.sender));
       _;
  }

  function addBeneficiary(address beneficiaryWallet, bytes32 beneficiaryNickname, bytes32 beneficiaryEmail, uint256 share) public onlyOwner returns (uint256 index) {
      require(!checkIfBeneficiary(beneficiaryWallet));
      userStructs[beneficiaryWallet].email = beneficiaryEmail;
      userStructs[beneficiaryWallet].nickname = beneficiaryNickname;
      userStructs[beneficiaryWallet].ethHasWithdrawn = 0;
      userStructs[beneficiaryWallet].index = userIndex.push(beneficiaryWallet).sub(1);
      updateShare(beneficiaryWallet, share);

      emit BeneficiaryAdded(beneficiaryWallet, beneficiaryNickname, beneficiaryEmail, userStructs[beneficiaryWallet].index);
      return userIndex.length - 1;
  }

  function removeBeneficiary(address beneficiaryWallet) public onlyOwner returns (uint256 index) {
      require(checkIfBeneficiary(beneficiaryWallet));
      uint rowToDelete = userStructs[beneficiaryWallet].index;
      address keyToMove = userIndex[userIndex.length-1];
      userIndex[rowToDelete] = keyToMove;
      userStructs[keyToMove].index = rowToDelete;
      delete(userStructs[beneficiaryWallet]);
      userIndex.length--;

      // Button gets hit here as we know the owner is alive
      hitTheDamnButton();

      emit BeneficiaryRemoved(beneficiaryWallet, rowToDelete);
      emit BeneficiaryUpdated(keyToMove, userStructs[keyToMove].nickname, userStructs[keyToMove].email, rowToDelete);
      return rowToDelete;
  }

  function updateBeneficiaryNickname(address beneficiaryWallet, bytes32 beneficiaryNickname) public onlyOwner returns (bool success) {
      require(checkIfBeneficiary(beneficiaryWallet));
      userStructs[beneficiaryWallet].nickname = beneficiaryNickname;
      
      // Button gets hit here as we know the owner is alive
      hitTheDamnButton();

      emit BeneficiaryUpdated(beneficiaryWallet, beneficiaryNickname, userStructs[beneficiaryWallet].email, userStructs[beneficiaryWallet].index);
      
      return true;
  }

  function updateBeneficiaryEmail(address beneficiaryWallet, bytes32 beneficiaryEmail) public onlyOwner returns (bool success) {
      require(checkIfBeneficiary(beneficiaryWallet));
      userStructs[beneficiaryWallet].email = beneficiaryEmail;
      
      // Button gets hit here as we know the owner is alive
      hitTheDamnButton();

      emit BeneficiaryUpdated(beneficiaryWallet, userStructs[beneficiaryWallet].nickname,  beneficiaryEmail, userStructs[beneficiaryWallet].index);
      
      return true;
  }

  function checkIfBeneficiary(address beneficiaryWallet) public view returns (bool isBeneficiary) {
      if(userIndex.length == 0) return false;
      return (userIndex[userStructs[beneficiaryWallet].index] == beneficiaryWallet);
  }

  function getBeneficiaryCount() public view returns (uint256 count) {
      return userIndex.length;
  }

  function getBeneficiaryAtIndex(uint256 index) public view returns (address userAddress) {
      return userIndex[index];
  }

  function updateShare(address beneficiary, uint256 beneficiaryShare) public onlyOwner returns (uint256 share) {
      userStructs[beneficiary].share = beneficiaryShare;
      // Button gets hit here as we know the owner is alive
      hitTheDamnButton();
      return beneficiaryShare;
  }


  function updateDefaultErc721ApprovedUser(address defaultUser) public onlyOwner returns (address newDefault) {
    require(checkIfBeneficiary(defaultUser), "Only beneficiaries are authorized to be default erc721 approved user");
      defaultErc721ApprovedUser = defaultUser;
      // Button gets hit here as we know the owner is alive
      hitTheDamnButton();
      return defaultUser;
  }

  function sumShares() public view returns (uint256 allShareSum) {
      uint256 shareSum = 0;
      for (uint i=0; i < getBeneficiaryCount(); i++) {
        shareSum = shareSum.add(userStructs[getBeneficiaryAtIndex(i)].share);
      }
      return shareSum;
  }
}
