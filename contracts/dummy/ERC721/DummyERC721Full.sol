pragma solidity ^0.5.8;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";

// Open Zepellin implementation
/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract DummyERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor (string memory name, string memory symbol) ERC721Metadata(name, symbol) public {}

  function mint(address to, uint256 tokenId) public returns (bool) {
    _mint(to, tokenId);
    return true;
  }
}
