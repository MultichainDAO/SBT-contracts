// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IMultiHonor {
    function POC(uint256 tokenId) view external returns(uint64);
    function VEPower(uint256 tokenId) view external returns(uint64);
    function EventPower(uint256 tokenId) view external returns(uint64);
    function Total(uint256 tokenId) view external returns(uint64); 
    function Level(uint256 tokenId) view external returns(uint8);
}

/**
 * ID card NFT for MultiDAO
 */
contract IDNFT_v1 is ERC721EnumerableUpgradeable,OwnableUpgradeable {
    function initialize()public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC721_init_unchained("IDNFT", "IDNFT");
    }

    uint256 public nextTokenId;
    address public honor;
    mapping(uint256 => bool) public isAllowTransfer;

    event SetHonor(address honor);
    event AllowTransfer(uint256 tokenId);
    event ForbidTransfer(uint256 tokenId);

    function setHonor(address honor_) external onlyOwner {
        honor = honor_;
        emit SetHonor(honor);
    }

    function allowTransfer(uint256 tokenId) external onlyOwner {
        isAllowTransfer[tokenId] = true;
        emit AllowTransfer(tokenId);
    }

    function forbidTransfer(uint256 tokenId) external onlyOwner {
        isAllowTransfer[tokenId] = false;
        emit ForbidTransfer(tokenId);
    }

    // Only tokenIds which are approved by contract owner can be transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(isAllowTransfer[tokenId], "transfer is forbidden");
        isAllowTransfer[tokenId] = false;
        require(balanceOf(to) == 0, "receiver already has an ID card");
    }

    function claim() external returns(uint256 tokenId) {
        tokenId = nextTokenId;
        isAllowTransfer[tokenId] = true;
        _mint(msg.sender, tokenId);
        isAllowTransfer[tokenId] = false;
        nextTokenId++;
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId));
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _tokenURI(tokenId);
    }

    function _tokenURI(uint _tokenId) internal view returns (string memory output) {
        uint lvl = IMultiHonor(honor).Level(_tokenId);
        output = string(abi.encodePacked('ipfs://QmTYwELcSgghx32VMsSGgWFQvCAqZ5tg6kKaPh2MSJfwAj/', toString(lvl)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}