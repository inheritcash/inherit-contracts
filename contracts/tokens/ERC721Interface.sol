pragma solidity ^0.5.8;
/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.

interface ERC165Interface {
  /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC721Interface is ERC165Interface {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId) public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator) public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId) public;

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
/// @notice Handle the receipt of an NFT
/// @dev The ERC721 smart contract calls this function on the recipient
///  after a `transfer`. This function MAY throw to revert and reject the
///  transfer. Return of other than the magic value MUST result in the
///  transaction being reverted.
///  Note: the contract address is always the message sender.
/// @param _operator The address which called `safeTransferFrom` function
/// @param _from The address which previously owned the token
/// @param _tokenId The NFT identifier which is being transferred
/// @param _data Additional data with no specified format
/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
///  unless throwing
function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
