// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}