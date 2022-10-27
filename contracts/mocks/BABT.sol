// Test contract
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

contract BABT is ERC721EnumerableUpgradeable {
    function claim(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId));
        _burn(tokenId);
    }
}
