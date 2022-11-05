// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Counter {
    struct Chunk {
        uint256 fromTokenId;
        uint256 toTokenId;
        uint256 result;
    }

    Chunk[] public chunks;

    function getOne(uint256 tokenId) external view virtual returns (uint256);

    // TODO check idnft and sbt is paused
    function get(uint256 fromTokenId, uint256 toTokenId)
        public
        view
        returns (uint256 result)
    {
        for (uint256 i = fromTokenId; i <= toTokenId; i++) {
            try this.getOne(i) returns (uint256 result_i) {
                result += result_i;
            } catch {
                // TODO
            }
        }
    }

    function getTx(uint256 fromTokenId, uint256 toTokenId) external {
        Chunk memory chunk = Chunk(
            fromTokenId,
            toTokenId,
            get(fromTokenId, toTokenId)
        );
        chunks.push(chunk);
        // TODO
    }

    function reduce() external view returns (uint256 result) {
        for (uint256 i = 0; i < chunks.length; i++) {
            result += chunks[i].result;
        }
        return result;
    }

    function clear() external {
        delete chunks;
        // TODO
    }
}

interface ISBT {
    function POC(uint256 tokenId) external view returns (uint64);

    function VEPower(uint256 tokenId) external view returns (uint256);

    function VEPoint(uint256 tokenId) external view returns (uint64);

    function EventPoint(uint256 tokenId) external view returns (uint64);

    function TotalPoint(uint256 tokenId) external view returns (uint64);

    function Level(uint256 tokenId) external view returns (uint8);
}

contract Non_Trivial_Counter is Counter {
    address public sbt;

    constructor(address sbt_) {
        sbt = sbt_;
    }

    function getOne(uint256 tokenId) external view override returns (uint256) {
        if (ISBT(sbt).TotalPoint(tokenId) > 0) {
            return 1;
        }
        return 0;
    }
}
