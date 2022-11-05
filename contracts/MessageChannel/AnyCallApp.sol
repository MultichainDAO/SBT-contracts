// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Administrable.sol";
import "./IAnycallV6Proxy.sol";
import "./IExecutor.sol";

abstract contract AnyCallApp is Administrable {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public anyCallProxy;

    mapping(uint256 => address) internal peer;

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor(address anyCallProxy_, uint256 flag_) {
        anyCallProxy = anyCallProxy_;
        flag = flag_;
    }

    function setPeers(uint256[] memory chainIDs, address[] memory peers)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < chainIDs.length; i++) {
            peer[chainIDs[i]] = peers[i];
        }
    }

    function getPeer(uint256 foreignChainID) external view returns (address) {
        return peer[foreignChainID];
    }

    function setAnyCallProxy(address proxy) public onlyAdmin {
        anyCallProxy = proxy;
    }

    function _anyExecute(uint256 fromChainID, bytes calldata data)
        internal
        virtual
        returns (bool success, bytes memory result);

    function _anyCall(
        address _to,
        bytes memory _data,
        address _fallback,
        uint256 _toChainID
    ) internal {
        if (flag == 2) {
            IAnycallV6Proxy(anyCallProxy).anyCall{value: msg.value}(
                _to,
                _data,
                _fallback,
                _toChainID,
                flag
            );
        } else {
            IAnycallV6Proxy(anyCallProxy).anyCall(
                _to,
                _data,
                _fallback,
                _toChainID,
                flag
            );
        }
    }

    function anyExecute(bytes calldata data)
        external
        onlyExecutor
        returns (bool success, bytes memory result)
    {
        (address callFrom, uint256 fromChainID, ) = IExecutor(
            IAnycallV6Proxy(anyCallProxy).executor()
        ).context();
        require(peer[fromChainID] == callFrom, "call not allowed");
        _anyExecute(fromChainID, data);
    }
}
