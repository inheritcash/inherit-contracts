pragma solidity ^0.5.8;

import "../../tokens/ERC721Interface.sol";

// Open Zepellin implementation

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721MetadataInterface is ERC721Interface {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) external view returns (string memory);
}
