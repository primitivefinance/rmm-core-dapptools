// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

/// @title   Cumulative Normal Distribution Math Lib API Test
/// @author  Primitive
/// @dev     ONLY FOR TESTING PURPOSES.

import "@primitivefinance/v2-core/contracts/libraries/ABDKMath64x64.sol";
import "@primitivefinance/v2-core/contracts/libraries/CumulativeNormalDistribution.sol";
import "@primitivefinance/v2-core/contracts/libraries/Units.sol";

import "../utils/Base.sol";

contract TestCdf is Base {
    using Units for *;
    using ABDKMath64x64 for *;
    using CumulativeNormalDistribution for *;

    uint256 public constant PRECISION = 1e18;

     function testCdf(int64 x) public pure returns (int128) {
        return x.getCDF();
    }

    function testinverseCDF(int128 x) public pure returns (int128 y) {
        if (x >= 2**64 || x <= 0) return 0;
        y = x.getInverseCDF();
    }

    function testFailsignedInverseCDF(uint64 x) public pure returns (int128 y) {
        int128 p = -x.divu(PRECISION);
        y = p.getInverseCDF();
    }

    function testinverseCDFHighTail() public pure returns (int128 y) {
        int128 p = CumulativeNormalDistribution.HIGH_TAIL.add(1);
        y = p.getInverseCDF();
    }

    function testinverseCDFLowTail() public pure returns (int128 y) {
        int128 p = CumulativeNormalDistribution.LOW_TAIL.sub(1);
        y = p.getInverseCDF();
    }
}