pragma solidity ^0.5.8;

import "./ERC721Interface.sol";

// Open Zepellin implementation
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721EnumerableInterface is ERC721Interface {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}
