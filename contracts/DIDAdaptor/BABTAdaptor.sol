// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDIDAdaptor.sol";

interface IBABT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IDCard {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract BABTAdaptor is IDIDAdaptor {
    bytes32 constant AccountType_Binance = keccak256("BABT");
    address idcard;
    address babt;

    mapping(uint256 => uint256) public babtOf; // idcard => binance sbt

    event ConnectBABT(uint256 tokenId, uint256 babtId);
    event DisconnectBABT(uint256 tokenId, uint256 babtId);

    function connect(
        uint256 tokenId,
        address claimer,
        bytes32 accountType,
        bytes memory sign_info
    ) public override returns (bool) {
        require(msg.sender == idcard);
        if (accountType == AccountType_Binance) {
            uint256 babtId = abi.decode(sign_info, (uint256));
            if (claimer != IBABT(babt).ownerOf(babtId)) {
                return false;
            }
            babtOf[tokenId] = babtId;
            emit ConnectBABT(tokenId, babtId);
            return true;
        }
        return false;
    }

    function disconnect(uint256 tokenId) external override returns (bool) {
        require(msg.sender == idcard);
        uint256 babtId = babtOf[tokenId];
        babtOf[tokenId] = 0;
        emit DisconnectBABT(tokenId, babtId);
        return true;
    }

    function verifyAccount(uint256 tokenId, address owner)
        public
        view
        override
        returns (bool)
    {
        return (IDCard(idcard).ownerOf(tokenId) == IBABT(babt).ownerOf(babtOf[tokenId]));
    }

    function getSignInfo(uint256 tokenId) external pure returns (bytes memory) {
        return abi.encode(tokenId);
    }
}