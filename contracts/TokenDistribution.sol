pragma solidity ^0.5.8;

import "./controller/SharesController.sol";
import "./IExecutorRegistry.sol";
import "./tokens/ERC20Interface.sol";

contract TokenDistribution is SharesController {
  address activeExecutorRegistry;
  string thisExecutorContractName;

  // 0.005 ETH as Gas Fee to forward for select beneficiaries (Number multiplied by szabo)
  uint256 internal constant BENEFICIARY_GAS_FEES = 5000;

  uint256 public constant CONTRACT_VERSION = 1;

  constructor(address[] memory beneficiaryAddresses,
    bytes32[] memory beneficiaryNicknames,
    bytes32[] memory beneficiaryEmails,
    uint256[] memory beneficiaryShares,
    uint256 unixDurationToHitButton,
    uint256 unixDurationToOpenRemainingAssetsToAllBeneficiaries,
    address[] memory listedErc20Tokens,
    address[] memory listedErc721Tokens,
    string memory uniqueExecutorContractName,
    address payable[] memory multiAddressParameter) public payable{
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

    // Multi Address Parameter
    // Default ERC721 Approved User Index 0
    updateDefaultErc721ApprovedUser(multiAddressParameter[0]);

    // Active Executor Registry you wish to connect contract to
    activeExecutorRegistry = address(0); // set to address of current live executor registry
    changeExecutorRegistryAddress(multiAddressParameter[1]);

    // Forward some gas fees
    for (uint l=2; l < multiAddressParameter.length; l++) {
      require(multiAddressParameter[l].send(BENEFICIARY_GAS_FEES * 1 szabo), 'Couldnt send');
    }

    IExecutorRegistry registry = IExecutorRegistry(activeExecutorRegistry);
    uint256 regFee = registry.getRegistrationFee();
    registry.addOrUpdateExecutorContractRegistry.value(regFee * 1 szabo)(msg.sender, uniqueExecutorContractName, address(this));
    thisExecutorContractName = uniqueExecutorContractName;
  }

  // @notice Will receive any eth sent to the contract
  function () external payable {
  }

  // This smart contract will use the last interaction to determine whether to distribute future funds, or not.

  function transferMeAvailableBeneficiaryETHBalance() public returns (bool success) {
      // Calculate eth allowance for Beneficiary
      uint256 ethBeneficiaryWithdrawalAllowance = calculateBeneficiariesCurrentEthAllowance(msg.sender);

      // Update what a specific user has withdrawn in eth
      userStructs[msg.sender].ethHasWithdrawn = userStructs[msg.sender].ethHasWithdrawn.add(ethBeneficiaryWithdrawalAllowance);

      // Temporarily store what has been withdrawn previously
      uint256 alreadyWithdrawnTotal = totalWeiOfEthWithdrawn;

      // Update what will have been withdrawn after tx
      totalWeiOfEthWithdrawn = totalWeiOfEthWithdrawn.add(ethBeneficiaryWithdrawalAllowance);

      // Get the current balance of ETH token available
      uint256 currentBalance = address(this).balance;

      //Update max balance
      if(currentBalance > totalMaximumWeiOfEthBalance.sub(alreadyWithdrawnTotal)) {
        totalMaximumWeiOfEthBalance = currentBalance.sub(alreadyWithdrawnTotal);
      }

        msg.sender.transfer(ethBeneficiaryWithdrawalAllowance);

        return true;
  }

  function transferMeAvailableBeneficiaryERC20BalancesMulti() public returns (bool success) {
      uint256[] memory contractBalances = getAllCurrentErc20Inheritances(msg.sender);
      bool successfulTransfers = true;
      for (uint i=0; i < erc20TokenContracts.length; i++) {
          // Instantiate the ERC20 contract
          ERC20Interface erc20 = ERC20Interface(erc20TokenContracts[i]);

          // Update the specific user amount of erc20 token balance withdrawn for this token
          userStructs[msg.sender].erc20TokenBalanceHasWithdrawn[erc20TokenContracts[i]] = userStructs[msg.sender].erc20TokenBalanceHasWithdrawn[erc20TokenContracts[i]].add(contractBalances[i]);

          // Get the previous amount of total token withdrawn prior to this transaction
          uint256 alreadyWithdrawnTotal = erc20ContractAddressToTokenInfo[erc20TokenContracts[i]].totalWeiWithdrawn;

          // Update total withdrawn and contract balance maximums
          erc20ContractAddressToTokenInfo[erc20TokenContracts[i]].totalWeiWithdrawn = erc20ContractAddressToTokenInfo[erc20TokenContracts[i]].totalWeiWithdrawn.add(contractBalances[i]);

          // Get the old maximum balance of ERC20 token available, and the current balance of erc20 token available
          uint256 maxBalance = erc20ContractAddressToTokenInfo[erc20TokenContracts[i]].totalWeiBalanceMax;
          uint256 currentBalance = erc20.balanceOf(principleAccount);

          //Update max balance
          if(currentBalance > maxBalance.sub(alreadyWithdrawnTotal)){
              erc20ContractAddressToTokenInfo[erc20TokenContracts[i]].totalWeiBalanceMax = currentBalance.sub(alreadyWithdrawnTotal);
          }

          // Make the erc20 transfer based on contract inheritance calculation
          successfulTransfers = successfulTransfers && erc20.transferFrom(principleAccount, msg.sender, contractBalances[i]);
      }
      return true;
  }

  function transferMeFungibleAssets() public returns (bool success) {
      return transferMeAvailableBeneficiaryETHBalance() && transferMeAvailableBeneficiaryERC20BalancesMulti();
  }

  // Need to be able to check SharesController and determine which ERC721 corresponds to beneficiary
  // Please note for this we need to know that the id and contract is approved beforehand off chain, so this could revert
  function transferMeAvailableSingleBeneficiaryERC721Token(address erc721Contract, uint256 tokenId) public returns (bool success) {
      require(overdueButton(), "Testament not overdue yet");
      bool isAssignedTokenIdToBeneficiary = erc721TokenContractToNFT[erc721Contract].specificBeneficiaryForSpecificToken[tokenId] == msg.sender;
      bool isTheDefaultUser = defaultErc721ApprovedUser == msg.sender;

      require(isAssignedTokenIdToBeneficiary ||
              (isTheDefaultUser && overdueBeneficiaryOpenRemainingAssets()) ||
              (isTheDefaultUser && erc721TokenContractToNFT[erc721Contract].specificBeneficiaryForSpecificToken[tokenId] == address(0)), "Cant transfer that nft");

      ERC721 nft = ERC721(erc721Contract);

      // Transfer Single Beneficiary
      nft.transferFrom(principleAccount, msg.sender, tokenId);

      return true;
  }

  function transferMeManyERC721Tokens(address[] memory erc721Contracts, uint256[] memory tokenIdsForMatchingContracts) public returns (bool success) {
      require(erc721Contracts.length == tokenIdsForMatchingContracts.length, "Invalid array lengths");
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
      require(executorRegistry != activeExecutorRegistry, "Same addr");
      activeExecutorRegistry = executorRegistry;
  }

  function getExecutorRegistryAddress() public view returns (address executorRegistryAddress) {
    return activeExecutorRegistry;
  }

  function getExecutorContractName() public view returns (string memory){
    return thisExecutorContractName;
  }

  //Utilities
  // If a random erc20 token is attached directly to the contract, the default user should take care of it.
  function reclaimERC20(address _tokenContract) external {
    require((msg.sender == defaultErc721ApprovedUser && overdueButton())
    || msg.sender == principleAccount);
    require(_tokenContract != address(0), "Invalid address");
    ERC20Interface token = ERC20Interface(_tokenContract);
    uint256 balance = token.balanceOf(address(this));
    require(token.transfer(msg.sender, balance), "Transfer failed");
  }

  function reclaimETH() onlyOwner external {
    msg.sender.transfer(address(this).balance);
  }

  // Self Destruct
  // Note this may be weird if you already removed from contract registry
  function selfDestructAndRemoveFromRegistry() public onlyOwner {
    IExecutorRegistry registry = IExecutorRegistry(activeExecutorRegistry);
    registry.removeSpecificUserFromContractRegistry(msg.sender);
    selfdestruct(msg.sender);
  }
}

