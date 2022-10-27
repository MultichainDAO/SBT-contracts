pragma solidity ^0.8.0;

import "../MessageChannel/MessageChannelBase.sol";

contract PseudoMessageChannel is MessageChannelBase {
    event Send(uint256 toChainID, bytes message);

    function send(uint256 toChainID, bytes memory message) external override {
        emit Send(toChainID, message);
    }

    function receiveMessage(
        address client,
        address caller,
        bytes memory message
    ) external {
        onReceive(client, caller, message);
    }
}
