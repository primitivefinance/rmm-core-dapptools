// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ABDKMath64x64.sol";
import "@primitivefinance/v2-core/contracts/libraries/CumulativeNormalDistribution.sol";
import "@primitivefinance/v2-core/contracts/libraries/Units.sol";

import "../utils/Base.sol";

/// @title   getCDF(), getInverseCDF()
contract TestCumulativeDistribution is Base {
    using Units for *;
    using ABDKMath64x64 for *;
    using CumulativeNormalDistribution for *;

    /// @notice Fuzz CDF
    function testGetCDF(int128 x) public {
        int128 val = x.getCDF();
        assertTrue(val > 0, "CDF output a negative value");
    }

    /// @notice Prove CDF
    function proveGetCDF(int128 x) public {
        int128 val = x.getCDF();
        assertTrue(val > 0, "CDF output a negative value");
    }

    /// @notice Fuzz Inverse CDF
    function testGetInverseCDF(int128 x) public {
        if (x >= 2**64 || x <= 0) return;
        x.getInverseCDF();
    }

    /// @notice Fail on invalid range
    function testFailGetInverseCDFSigned(uint64 x) public {
        int128 p = -x.divu(1e18);
        p.getInverseCDF();
    }

    /// @notice Fuzz CDF High Tail Approximation
    function testGetInverseCDFHighTail() public {
        int128 p = CumulativeNormalDistribution.HIGH_TAIL.add(1);
        p.getInverseCDF();
    }

    /// @notice Fuzz CDF Low Tail Approximation
    function testGetInverseCDFLowTail() public {
        int128 p = CumulativeNormalDistribution.LOW_TAIL.sub(1);
        p.getInverseCDF();
    }
}