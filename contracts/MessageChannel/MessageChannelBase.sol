// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMessageChannel {
    function send(uint256 toChainID, bytes memory message) external virtual;
}

interface IClient {
    function onReceiveMessage(address caller, bytes memory message)
        external
        virtual;
}

abstract contract MessageChannelBase is IMessageChannel {
    function onReceive(
        address client,
        address caller,
        bytes memory message
    ) internal {
        IClient(client).onReceiveMessage(caller, message);
    }
}