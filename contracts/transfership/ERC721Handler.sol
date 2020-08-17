pragma solidity ^0.5.8;

import "./ERC20Handler.sol";
import "../tokens/ERC721.sol";

contract ERC721Handler is ERC721TokenReceiver, ERC20Handler {

  struct NFT {
    uint256 index; // Maps to nfts address
    mapping(uint256 => address) specificBeneficiaryForSpecificToken;
  }

  mapping(address => NFT) public erc721TokenContractToNFT;
  address [] public nftAddresses;

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4) {
	    // This function will require that we save an array of available erc721 tokens that they can later transfer in and out
	    // Modified to return information from the call
	    return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
  }

  function addERC721TokenContractToList(address contractAddress) public onlyOwner returns (address addedContract) {
      require(!checkIfNft(contractAddress), "Already an Nft");
      erc721TokenContractToNFT[contractAddress].index = nftAddresses.push(contractAddress).sub(1);
      // Note: Call setapprovalforall on this contract afterwards meaning the executing smart contract can do what it must with tokens
      // Note: Contract cannot call this during construction as the call with a smart contract to NFT doesnt work (msg.sender == smart contract address not tx.origin)

      return contractAddress;
  }

  function addERC721TokenContractToListWithBeneficiarySpecified(address contractAddress, uint256[] memory tokenIds, address[] memory specificBeneficiaryForTokenId) public onlyOwner returns (address addedContract) {
      require(tokenIds.length == specificBeneficiaryForTokenId.length, "Incorrect array lengths");
      addERC721TokenContractToList(contractAddress);
      return updateNFTWithSpecificBeneficiaries(contractAddress, tokenIds, specificBeneficiaryForTokenId);
  }

  // If the update is removing a specific beneficiary, as opposed to using the removeNFT function, you can use 0x0 address
  function updateNFTWithSpecificBeneficiaries(address contractAddress, uint256[] memory tokenIds, address[] memory specificBeneficiaryForTokenId) public onlyOwner returns (address addedContract) {
      require(checkIfNft(contractAddress), "No such Nft");
      for (uint i=0; i< tokenIds.length; i++) {
          erc721TokenContractToNFT[contractAddress].specificBeneficiaryForSpecificToken[tokenIds[i]] = specificBeneficiaryForTokenId[i];
      }
      return contractAddress;
  }

  function removeSpecificBeneficiariesFromNft(address contractAddress, uint256[] memory tokenIds) public onlyOwner returns (address addressOfModifiedContract) {
      require(checkIfNft(contractAddress), "No such Nft");
      for (uint i=0; i<tokenIds.length; i++) {
          delete(erc721TokenContractToNFT[contractAddress].specificBeneficiaryForSpecificToken[tokenIds[i]]);
      }
      return contractAddress;
  }

  function removeERC721Token(address contractAddress) public onlyOwner returns (uint256 index) {
      require(checkIfNft(contractAddress), "No such Nft");
      uint256 rowToDelete = erc721TokenContractToNFT[contractAddress].index;
      address keyToMove = nftAddresses[nftAddresses.length-1];
      nftAddresses[rowToDelete] = keyToMove;
      erc721TokenContractToNFT[keyToMove].index = rowToDelete;
      nftAddresses.length--;
      delete(erc721TokenContractToNFT[contractAddress]);

      return rowToDelete;
 }

  function checkIfNft(address nftAddress) public view returns (bool isNft) {
      if(nftAddresses.length == 0) return false;
      return (nftAddresses[erc721TokenContractToNFT[nftAddress].index] == nftAddress);
  }

  function getNftListLength() public view returns (uint256 count) {
      return nftAddresses.length;
  }

  function checkIfValidTokenIdForNFTUser(address nftAddress, uint256 tokenIdFromContract, address specificUser) public view returns (bool isTokenId) {
      require(checkIfNft(nftAddress), "No such nft");
      return (erc721TokenContractToNFT[nftAddress].specificBeneficiaryForSpecificToken[tokenIdFromContract] == specificUser);
  }

  function checkIfValidTokenIdsForMultipleNFTUser(address[] memory nftAddresses, uint256[] memory tokenIdsFromContract, address[] memory specificUsers) public view returns (bool[] memory isValidOrNot) {
      bool[] memory a = new bool[](nftAddresses.length);
      for (uint i=0; i< tokenIdsFromContract.length; i++) {
        a[i] = checkIfValidTokenIdForNFTUser(nftAddresses[i], tokenIdsFromContract[i], specificUsers[i]);
      }
      return a;
  }

  function getBeneficiaryAddressesForSpecificTokenIdsSingleNft(address nftAddress, uint256[] memory tokenIdsFromContract) public view returns (address[] memory specificBeneficiaries) {
      address[] memory a = new address[](tokenIdsFromContract.length);
      for (uint i=0; i< tokenIdsFromContract.length; i++) {
        a[i] = erc721TokenContractToNFT[nftAddress].specificBeneficiaryForSpecificToken[tokenIdsFromContract[i]];
      }
      return a;
  }
}
