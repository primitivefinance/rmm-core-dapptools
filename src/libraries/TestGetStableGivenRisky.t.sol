// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   getStableGivenRisky()
contract TestGetStableGivenRisky is Base {
    using ABDKMath64x64 for *; // stores numerators as int128, denominator is 2^64.
    using CumulativeNormalDistribution for int128;
    using Units for int128;
    using Units for uint256;

    /// 0. Scale strike to respective decimals
    /// 1. Calculate { sigma * sqrt( tau ) }
    /// 2. Scale reserveRisky to respective decimals
    /// 3. Calculate { getInverseCDF( 1 - reserveRiskyScaled ) }
    /// 4. Calculate { Step 3. + Step 1. }
    /// 5. Calculate { Step 0. * getCDF( Step 4. ) + Invariant }

    /// @notice Fuzz scaling of strike to its respective decimal places
    function testStep0(uint128 strike, uint scaleFactorStable) public {
        if(scaleFactorStable > WAD) return;
        int128 K = strike.scaleToX64(scaleFactorStable);
        uint256 X = K.scaleFromX64(scaleFactorStable);
        assertEq(strike, X);
    }

    /// @notice Prove scaling of strike to its respective decimal places
    function proveStep0(uint128 strike, uint scaleFactorStable) public {
        testStep0(strike, scaleFactorStable);
    }

    /// @notice Fuzz { sigma * sqrt( tau ) }
    function testStep1(uint64 sigma, uint32 tau) public {
        if(sigma > RAY) return;
        ReplicationMath.getProportionalVolatility(sigma, tau);
    }

    /// @notice Fuzz scaling of reserveRisky to its respective decimals
    function testStep2(uint128 reserveRisky, uint scaleFactorRisky) public {
        if(scaleFactorRisky > WAD) return;
        int128 reserve = reserveRisky.scaleToX64(scaleFactorRisky);
        uint256 scaled = reserve.scaleFromX64(scaleFactorRisky);
        assertEq(reserve, scaled);
    }

    /// @notice Prove scaling of reserveRisky to its respective decimal places
    function proveStep2(uint128 reserveRisky, uint scaleFactorRisky) public {
        testStep2(reserveRisky, scaleFactorRisky);
    }

    /// @notice Fuzz { getInverseCDF( 1 - reserveRiskyScaled ) }
    function testStep3(int128 reserveRiskyScaled) public {
        if(reserveRiskyScaled > ReplicationMath.ONE_INT) return;
        ReplicationMath.ONE_INT.sub(reserveRiskyScaled).getInverseCDF();
    }

    /// @notice Fuzz { Step 3. + Step 1. }
    function testStep4(
        int128 reserve,
        uint64 sigma,
        uint32 tau
    ) public {
        testStep3(reserve).add(testStep1(sigma, tau));
    }

    /// @notice Fuzz { Step 0. * getCDF( Step 4. ) + Invariant }
    function testStep5(
        uint128 strike,
        uint scaleFactorStable,
        int128 reserve,
        uint64 sigma,
        uint32 tau,
        int128 invariantLast,
    ) public {
        testStep0(strike, scaleFactorStable).mul(testStep4(reserve, sigma, tau).getCDF()).add(invariantLast);
    }

    /// @notice Fuzz getStableGivenRisky
    function testGetStableGivenRisky(
        int128 invariantLast,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint128 reserveRisky,
        uint128 strike,
        uint64 sigma,
        uint32 tau
    ) public {
        if(sigma > RAY) return;
        if(scaleFactorRisky > WAD || scaleFactorStable > WAD) return;
        ReplicationMath.GetStableGivenRisky(invariantLast, scaleFactorRisky, scaleFactorStable, reserveRisky, strike, sigma, tau);
    }

    /// @notice Prove getStableGivenRisky
    function proveGetStableGivenRisky(
        int128 invariantLast,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint128 reserveRisky,
        uint128 strike,
        uint64 sigma,
        uint32 tau
    ) public {
        uint256 stable = testGetStableGivenRisky(invariantLast, scaleFactorRisky, scaleFactorStable, reserveRisky, strike, sigma, tau);
        assertTrue(type(uint128).max > stable, "Stable is larger than uint128");
    }
}
