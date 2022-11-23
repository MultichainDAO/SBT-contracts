// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDIDAdaptor.sol";

interface IBABT {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IDCard {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function exists(uint256 tokenId) external view returns (bool);
}

contract BABTAdaptor is IDIDAdaptorOwned {
    bytes32 constant AccountType_Binance = keccak256("BABT");
    address public idcard;
    address public controller;
    address public babt;
    uint256 public totalBinding;

    mapping(uint256 => uint256) public babtOf; // idcard => binance sbt
    mapping(uint256 => uint256) public idcardOf; // babt id => idcard

    event InitAdaptor(address idcard, address controller, address babt);
    event ConnectBABT(uint256 tokenId, uint256 babtId);
    event DisconnectBABT(uint256 tokenId, uint256 babtId);

    function initAdaptor(
        address idcard_,
        address controller_,
        address babt_
    ) public {
        require(msg.sender == owner);
        idcard = idcard_;
        controller = controller_;
        babt = babt_;
        emit InitAdaptor(idcard, controller, babt);
    }

    function connect(
        uint256 tokenId,
        address claimer,
        bytes32 accountType,
        bytes memory sign_info
    ) public override returns (bool) {
        require(msg.sender == controller);
        if (accountType == AccountType_Binance) {
            uint256 babtId = abi.decode(sign_info, (uint256));
            uint256 dTotalBinding = 1;
            if (
                idcardOf[babtId] != 0 && IDCard(idcard).exists(idcardOf[babtId])
            ) {
                if (verifyAccount(idcardOf[babtId])) {
                    return false;
                }
                dTotalBinding -= 1;
            }
            if (claimer != IBABT(babt).ownerOf(babtId)) {
                return false;
            }
            idcardOf[babtId] = tokenId;
            babtOf[tokenId] = babtId;
            totalBinding += dTotalBinding;
            emit ConnectBABT(tokenId, babtId);
            return true;
        }
        return false;
    }

    function disconnect(uint256 tokenId) external override returns (bool) {
        require(msg.sender == controller);
        return _disconnect(tokenId);
    }

    function _disconnect(uint256 tokenId) internal returns (bool) {
        uint256 babtId = babtOf[tokenId];
        idcardOf[babtId] = 0;
        babtOf[tokenId] = 0;
        totalBinding -= 1;
        emit DisconnectBABT(tokenId, babtId);
        return true;
    }

    function verifyAccount(uint256 tokenId)
        public
        view
        override
        returns (bool res)
    {
        try this.equalOwner(tokenId, babtOf[tokenId]) returns (bool equal) {
            res = equal;
        } catch {
            res = false;
        }
        return res;
    }

    function equalOwner(uint256 tokenId, uint256 babtId)
        public
        view
        returns (bool)
    {
        return (IDCard(idcard).ownerOf(tokenId) == IBABT(babt).ownerOf(babtId));
    }

    function getSignInfo(uint256 tokenId) external pure returns (bytes memory) {
        return abi.encode(tokenId);
    }
}
