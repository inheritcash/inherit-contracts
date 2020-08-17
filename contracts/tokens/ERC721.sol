pragma solidity ^0.5.8;
/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.

contract ERC721 {
  // Required methods
  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function approve(address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) external;

  // Events
  event Transfer(address from, address to, uint256 tokenId);
  event Approval(address owner, address approved, uint256 tokenId);

  // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
  function supportsInterface(bytes4 _interfaceID) external view returns (bool);
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
