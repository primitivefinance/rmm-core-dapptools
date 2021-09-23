// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   ReplicationMath Lib API Test
/// @author  Primitive
/// @dev     For testing purposes ONLY
contract TestCalcInvariant is Base {
    using ABDKMath64x64 for *; // stores numerators as int128, denominator is 2^64.
    using CumulativeNormalDistribution for int128;
    using Units for int128;
    using Units for uint256;

    uint256 public scaleFactorRisky;
    uint256 public scaleFactorStable;

    function testset(uint256 prec0, uint256 prec1) public {
        scaleFactorRisky = prec0;
        scaleFactorStable = prec1;
    }

    function teststep0(
        uint256 reserveRisky,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (int128 reserve2) {
        reserve2 = ReplicationMath
        .getStableGivenRisky(0, scaleFactorRisky, scaleFactorStable, reserveRisky, strike, sigma, tau)
        .scaleToX64(scaleFactorStable);
    }

    function teststep1(uint256 reserveStable, int128 reserve2) public view returns (int128 invariant) {
        invariant = reserveStable.scaleToX64(scaleFactorStable).sub(reserve2);
    }

    /// @return invariant Uses the trading function to calculate the invariant, which starts at 0 and grows with fees
    function testcalcInvariantRisky(
        uint256 reserveRisky,
        uint256 reserveStable,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (int128 invariant) {
        int128 reserve2 = teststep0(reserveRisky, strike, sigma, tau);
        invariant = teststep1(reserveStable, reserve2);
    }

    function testcalcInvariantStable(
        uint256 reserveRisky,
        uint256 reserveStable,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) public view returns (int128 invariant) {
        int128 reserve2 = teststep0(reserveRisky, strike, sigma, tau);
        invariant = teststep1(reserveStable, reserve2);
    }
}
