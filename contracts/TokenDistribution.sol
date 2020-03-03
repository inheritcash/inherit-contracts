pragma solidity ^0.5.8;

import "./controller/SharesController.sol";
import "./ExecutorRegistry.sol";

contract TokenDistribution is SharesController {
  address activeExecutorRegistry;
  string thisExecutorContractName;

  constructor(address[] memory beneficiaryAddresses,
    bytes32[] memory beneficiaryNicknames,
    bytes32[] memory beneficiaryEmails,
    uint256[] memory beneficiaryShares,
    uint256 unixDurationToHitButton,
    uint256 unixDurationToOpenRemainingAssetsToAllBeneficiaries,
    address[] memory listedErc20Tokens,
    address[] memory listedErc721Tokens,
    string memory uniqueExecutorContractName,
    address[] memory defaultErc721UserAndActiveExecutorRegistry) public payable{
    require(beneficiaryNicknames.length == beneficiaryAddresses.length);
    require(beneficiaryEmails.length == beneficiaryAddresses.length);
    require(beneficiaryShares.length == beneficiaryAddresses.length);
    require(unixDurationToHitButton > 0 && unixDurationToOpenRemainingAssetsToAllBeneficiaries > 0);
    require(unixDurationToHitButton < unixDurationToOpenRemainingAssetsToAllBeneficiaries);

    principleAccount = msg.sender;
    for (uint i=0; i < beneficiaryAddresses.length; i++) {
        addBeneficiary(beneficiaryAddresses[i], beneficiaryNicknames[i], beneficiaryEmails[i], beneficiaryShares[i]);
    }

    assignUnixDurationToHitButton(unixDurationToHitButton);

    assignUnixDurationToOpenRemainingAssetsToAllBeneficiaries(unixDurationToOpenRemainingAssetsToAllBeneficiaries);

    for (uint j=0; j < listedErc20Tokens.length; j++) {
        addNewERC20Token(listedErc20Tokens[j]);
    }

    for (uint k=0; k < listedErc721Tokens.length; k++) {
        addERC721TokenContractToList(listedErc721Tokens[k]);
    }


    updateDefaultErc721ApprovedUser(defaultErc721UserAndActiveExecutorRegistry[0]);
    activeExecutorRegistry = address(0); // set to address of current live executor registry
    changeExecutorRegistryAddress(defaultErc721UserAndActiveExecutorRegistry[1]);

    ExecutorRegistry registry = ExecutorRegistry(activeExecutorRegistry);
    registry.addOrUpdateExecutorContractRegistry(msg.sender, uniqueExecutorContractName, address(this));
    thisExecutorContractName = uniqueExecutorContractName;
  }

  // This smart contract will use the last interaction to determine whether to distribute future funds, or not.

  function transferMeAvailableBeneficiaryETHBalance() public returns (bool success) {
        msg.sender.transfer(calculateBeneficiariesCurrentEthAllowance(msg.sender));
        return true;
  }

  // Need to be able to check SharesController and determine how much ETH corresponds to beneficiary
  function transferMeAvailableBeneficiaryERC20Balances() public returns (bool success) {
      uint256[] memory contractBalances = getAllCurrentErc20Inheritances(msg.sender);
      bool successfulTransfers = true;
      for (uint i=0; i < erc20TokenContracts.length; i++) {
          ERC20Interface erc20 = ERC20Interface(erc20TokenContracts[i]);
          successfulTransfers = successfulTransfers && erc20.transferFrom(principleAccount, msg.sender, contractBalances[i]);
      }
      return true;
  }

  function transferMeFungibleAssets() public returns (bool success) {
      return transferMeAvailableBeneficiaryETHBalance() && transferMeAvailableBeneficiaryERC20Balances();
  }

  // Need to be able to check SharesController and determine which ERC721 corresponds to beneficiary
  function transferMeAvailableSingleBeneficiaryERC721Token(address erc721Contract, uint256 tokenId) public returns (bool success) {
      require(overdueButton());
      bool isAssignedTokenIdToBeneficiary = erc721TokenContractToNFT[erc721Contract].specificBeneficiaryForSpecificToken[tokenId] == msg.sender;
      bool isTheDefaultUser = defaultErc721ApprovedUser == msg.sender;

      require(isAssignedTokenIdToBeneficiary ||
              (isTheDefaultUser && overdueBeneficiaryOpenRemainingAssets()) ||
              (isTheDefaultUser && erc721TokenContractToNFT[erc721Contract].specificBeneficiaryForSpecificToken[tokenId] == address(0)));
      ERC721Interface nft = ERC721Interface(erc721Contract);
      require(nft.isApprovedForAll(principleAccount, address(this)));
      // Transfer Single Beneficiary
      nft.safeTransferFrom(principleAccount, msg.sender, tokenId, "");
      return true;
  }

  function transferMeManyERC721Tokens(address[] memory erc721Contracts, uint256[] memory tokenIdsForMatchingContracts) public returns (bool success) {
      require(erc721Contracts.length == tokenIdsForMatchingContracts.length);
      for (uint i=0; i < erc721Contracts.length; i++) {
          transferMeAvailableSingleBeneficiaryERC721Token(erc721Contracts[i], tokenIdsForMatchingContracts[i]);
      }
      return true;
  }

  function transferMeAllAssets(address[] memory erc721Contracts, uint256[] memory tokenIdsForMatchingContracts) public returns (bool success) {
      return transferMeFungibleAssets() &&
       transferMeManyERC721Tokens(erc721Contracts, tokenIdsForMatchingContracts);
  }

  function changeExecutorRegistryAddress(address executorRegistry) public onlyOwner {
      require(executorRegistry != activeExecutorRegistry);
      activeExecutorRegistry = executorRegistry;
  }

  function getExecutorRegistryAddress() public view returns (address executorRegistryAddress) {
    return activeExecutorRegistry;
  }

  function getExecutorContractName() public view returns (string memory){
    return thisExecutorContractName;
  }
}

