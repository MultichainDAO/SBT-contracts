// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AnyCallApp.sol";
import "./MessageChannelBase.sol";

contract AnyCallV6Adaptor is AnyCallApp, MessageChannelBase {
    constructor(address anyCallProxy) AnyCallApp(anyCallProxy, 2) {}

    function _anyExecute(uint256 fromChainID, bytes calldata data)
        internal
        override
        returns (bool success, bytes memory result)
    {
        (address client, address caller, bytes memory message) = abi.decode(
            data,
            (address, address, bytes)
        );
        onReceive(client, caller, fromChainID, message);
        return (true, "");
    }

    function send(
        uint256 toChainID,
        address to,
        bytes memory message
    ) external override {
        bytes memory data = abi.encode(to, msg.sender, message);
        _anyCall(peer[toChainID], data, address(0), toChainID);
        return;
    }
}
