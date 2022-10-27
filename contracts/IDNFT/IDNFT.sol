// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./IDNFTController.sol";

interface IMultiHonor {
    function Level(uint256 tokenId) external view returns (uint8);
}

/**
 * ID card NFT is a collection of crosschain composable DID NFT.
 */
contract IDCard_V2 is ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_CONTROLLER = keccak256("ROLE_CONTROLLER");

    uint256 maxTokenIdId;
    uint256 public nextTokenId;

    string public _baseURI_;
    string public defaultURI;
    address public honor;

    event InitV2();

    event SetDefaultURI(string defaultURI);
    event SetBaseURI(string baseURI);

    event SetHonor(address honor);

    event AllowTransfer(uint256 tokenId);
    event ForbidTransfer(uint256 tokenId);

    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __initRole();
        __ERC721_init_unchained("IDNFT", "IDNFT");
    }

    function __initRole() internal {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Initializes V2 settings.
    function initV2() public {
        _setDefaultURI(
            "ipfs://QmaVznKDucX1TyGZuhNrnmxmgMWfRXG6NW3QMg52mjvH1d/"
        );
        _setBaseURI("ipfs://QmTYwELcSgghx32VMsSGgWFQvCAqZ5tg6kKaPh2MSJfwAj/");
        emit InitV2();
    }

    /// @dev Sets default URI.
    function setDefaultURI(string memory defaultURI_) public {
        _checkRole(ROLE_ADMIN);
        _setDefaultURI(defaultURI_);
    }

    /// @dev Sets base URI.
    function setBaseURI(string memory baseURI) public {
        _checkRole(ROLE_ADMIN);
        _setBaseURI(baseURI);
    }

    function _setDefaultURI(string memory defaultURI_) internal {
        defaultURI = defaultURI_;
        emit SetDefaultURI(_baseURI_);
    }

    function _setBaseURI(string memory baseURI) internal {
        _baseURI_ = baseURI;
        emit SetBaseURI(_baseURI_);
    }

    /// @dev Sets MultiHonor address.
    function setHonor(address honor_) external {
        _checkRole(ROLE_ADMIN);
        honor = honor_;
        emit SetHonor(honor);
    }

    /// @dev Returns birth chain of the IDCard.
    function getChainID(uint256 tokenId) public view returns (uint256 chainID) {
        chainID = tokenId / maxTokenIdId;
        if (chainID == 0) {
            chainID = 137;
        }
        return chainID;
    }

    function mint(address owner, uint256 tokenId) external {
        _checkRole(ROLE_CONTROLLER);
        _mint(owner, tokenId);
    }

    function burn(uint256 tokenId) external {
        _checkRole(ROLE_CONTROLLER);
        _burn(tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @dev Returns token URI.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return _tokenURI(tokenId);
    }

    function _tokenURI(uint256 _tokenId)
        internal
        view
        returns (string memory output)
    {
        uint256 lvl = IMultiHonor(honor).Level(_tokenId);
        if (lvl == 0) {
            output = defaultURI;
        } else {
            output = string(abi.encodePacked(_baseURI_, toString(lvl)));
        }
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

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return false;
    }
}
