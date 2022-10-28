// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDIDAdaptor.sol";
import "../utils/Administrable.sol";

interface IClient {
    function onReceiveMessage(
        address caller,
        uint256 fromChainID,
        bytes memory message
    ) external virtual;
}

interface IMessageChannel {
    function send(uint256 toChainID, bytes memory message) external virtual;
}

interface IDCard {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function exists(uint256 tokenId) external view returns (bool);
}

interface IController {
    function verifyAccount(uint256 tokenId) external view returns (bool);
}

contract RemoteUserAdaptor is IDIDAdaptor, IClient, Administrable {
    bytes32 constant AccountType_RemoteUser = keccak256("RemoteUser");
    address public idcard;
    address public controller;
    uint256 public totalBinding;
    IMessageChannel public messageChannel;

    mapping(address => mapping(uint256 => bool)) peer;
    mapping(uint256 => address) public trustedOwnerOf; // idcard => trusted owner

    event InitAdaptor(address idcard, address controller);
    event ConnectRemoteUser(uint256 tokenId, address owner);
    event DisconnectRemoteUser(uint256 tokenId, address owner);
    event SetMessageChannel(address messageChannel);
    event SubmitVerifyInfo(uint256 tokenId, uint256 toChainID);

    constructor(address idcard_, address controller_) {
        idcard = idcard_;
        controller = controller_;
        setAdmin(msg.sender);
        emit InitAdaptor(idcard, controller);
    }

    function setMessageChannel(address messageChannel_) external onlyAdmin {
        messageChannel = IMessageChannel(messageChannel_);
        emit SetMessageChannel(address(messageChannel));
    }

    function connect(
        uint256 tokenId,
        address claimer,
        bytes32 accountType,
        bytes memory sign_info
    ) public override returns (bool) {
        require(msg.sender == controller);
        if (accountType == AccountType_RemoteUser) {
            if (claimer == trustedOwnerOf[tokenId]) {
                return true;
            }
        }
        return false;
    }

    function _receiveVerifyInfo(uint256 tokenId, address owner)
        internal
        returns (bool)
    {
        if (IDCard(idcard).ownerOf(tokenId) == owner) {
            trustedOwnerOf[tokenId] == owner;
            totalBinding += 1;
            emit ConnectRemoteUser(tokenId, owner);
            return true;
        }
        return false;
    }

    function disconnect(uint256 tokenId) external override returns (bool) {
        require(msg.sender == controller);
        address owner = trustedOwnerOf[tokenId];
        trustedOwnerOf[tokenId] = address(0);
        totalBinding -= 1;
        emit DisconnectRemoteUser(tokenId, owner);
        return true;
    }

    function verifyAccount(uint256 tokenId)
        public
        view
        override
        returns (bool res)
    {
        return (IDCard(idcard).ownerOf(tokenId) == trustedOwnerOf[tokenId]);
    }

    function onReceiveMessage(
        address caller,
        uint256 fromChainID,
        bytes memory message
    ) external override {
        require(peer[caller][fromChainID]);
        (uint256 tokenId, address owner) = abi.decode(
            message,
            (uint256, address)
        );
        _receiveVerifyInfo(tokenId, owner);
    }

    function submitVerifyInfo(uint256 tokenId, uint256 toChainID) external {
        require(IController(controller).verifyAccount(tokenId));
        address owner = IDCard(idcard).ownerOf(tokenId);
        bytes memory message = abi.encode(tokenId, owner);
        messageChannel.send(toChainID, message);
        emit SubmitVerifyInfo(tokenId, toChainID);
    }
}
