// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDIDAdaptor.sol";
import {MMR} from "../lib/mmr/MMR.sol";

interface IDCard {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function exists(uint256 tokenId) external view returns (bool);
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * VERIFY WHITELISTED ID CARD HOLDER.
 */
contract WhiteHolder is IDIDAdaptor {
    bytes32 constant AccountType_White = keccak256("White");
    address public idcard;
    address public controller;
    address public operator;
    bytes32 public currentRoot;
    uint256 public totalBinding;

    mapping(uint256 => address) public whiteHolderOf; // idcard => white holder
    mapping(address => uint256) public idcardOf; // white holder => idcard

    event InitAdaptor(address idcard, address controller, address operator);
    event ConnectPayer(uint256 tokenId, address premiumHolder);
    event DisconnectPayer(uint256 tokenId, address premiumHolder);
    event Withdraw(address to, uint256 amount);
    event TransferOperator(address to);
    event CommitRoot(bytes32 root);

    constructor(address idcard_, address controller_) {
        idcard = idcard_;
        controller = controller_;
        operator = msg.sender;
        emit InitAdaptor(idcard, controller, operator);
    }

    /// @notice Connect ID card to a white holder address.
    function connect(
        uint256 tokenId,
        address claimer,
        bytes32 accountType,
        bytes memory sign_info
    ) public override returns (bool) {
        require(msg.sender == controller);
        if (accountType == AccountType_White) {
            if (
                idcardOf[claimer] != 0 &&
                IDCard(idcard).exists(idcardOf[claimer])
            ) {
                return false;
            }
            if (verify(claimer, sign_info)) {
                idcardOf[claimer] = tokenId;
                whiteHolderOf[tokenId] = claimer;
                totalBinding += 1;
                return true;
            }
        }
        return false;
    }

    /// @notice Disconnect ID card from a white holder address.
    function disconnect(uint256 tokenId) external override returns (bool) {
        require(msg.sender == controller);
        address whiteHolder = whiteHolderOf[tokenId];
        idcardOf[whiteHolder] = 0;
        whiteHolderOf[tokenId] = address(0);
        totalBinding -= 1;
        emit DisconnectPayer(tokenId, whiteHolder);
        return true;
    }

    /// @notice Verify if the ID card holder is a premium holder.
    function verifyAccount(uint256 tokenId)
        public
        view
        override
        returns (bool res)
    {
        try this.equalOwner(tokenId, whiteHolderOf[tokenId]) returns (
            bool equal
        ) {
            res = equal;
        } catch {
            res = false;
        }
        return res;
    }

    function equalOwner(uint256 tokenId, address whiteHolder)
        public
        view
        returns (bool)
    {
        return (IDCard(idcard).ownerOf(tokenId) == whiteHolder);
    }

    function transferOperator(address to) external {
        require(msg.sender == operator);
        operator = to;
        emit TransferOperator(to);
    }

    /// @notice Commits root, only guardian.
    function commitRoot(bytes32 newRoot) public {
        require(msg.sender == operator);
        currentRoot = newRoot;
        emit CommitRoot(newRoot);
    }

    /// @notice Verifies inclusion proof.
    function verify(address addr, bytes memory proof)
        public
        view
        returns (bool)
    {
        (
            bytes32 root,
            uint256 width,
            uint256 index,
            bytes memory value,
            bytes32[] memory peaks,
            bytes32[] memory siblings
        ) = abi.decode(
                proof,
                (bytes32, uint256, uint256, bytes, bytes32[], bytes32[])
            );

        require(root == currentRoot);

        address proveaddr = abi.decode(value, (address));
        require(addr == proveaddr);

        return (MMR.inclusionProof(root, width, index, value, peaks, siblings));
    }
}
