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

    int128 public constant zero = int128(0);

    /// 0. Scale strike to respective decimals
    /// 1. Calculate { sigma * sqrt( tau ) }
    /// 2. Scale reserveRisky to respective decimals
    /// 3. Calculate { getInverseCDF( 1 - reserveRiskyScaled ) }
    /// 4. Calculate { Step 3. + Step 1. }
    /// 5. Calculate { Step 0. * getCDF( Step 4. ) + Invariant }

    /// @notice Fuzz scaling of strike to its respective decimal places
    function testStep0(uint128 strike, uint scaleFactorStable) public returns (int128) {
        if(scaleFactorStable > WAD) return zero;
        int128 K = uint(strike).scaleToX64(scaleFactorStable);
        uint256 X = K.scalefromX64(scaleFactorStable);
        assertEq(strike, uint128(X));
        return K;
    }

    /// @notice Prove scaling of strike to its respective decimal places
    function proveStep0(uint128 strike, uint scaleFactorStable) public {
        testStep0(strike, scaleFactorStable);
    }

    /// @notice Fuzz { sigma * sqrt( tau ) }
    function testStep1(uint64 sigma, uint32 tau) public returns (int128) {
        if(sigma > RAY) return zero;
        return ReplicationMath.getProportionalVolatility(sigma, tau);
    }

    /// @notice Fuzz scaling of reserveRisky to its respective decimals
    function testStep2(uint128 reserveRisky, uint scaleFactorRisky) public {
        if(scaleFactorRisky > WAD) return;
        int128 reserve = uint(reserveRisky).scaleToX64(scaleFactorRisky);
        uint256 scaled = reserve.scalefromX64(scaleFactorRisky);
        assertEq(reserveRisky, uint128(scaled));
    }

    /// @notice Prove scaling of reserveRisky to its respective decimal places
    function proveStep2(uint128 reserveRisky, uint scaleFactorRisky) public {
        testStep2(reserveRisky, scaleFactorRisky);
    }

    /// @notice Fuzz { getInverseCDF( 1 - reserveRiskyScaled ) }
    function testStep3(int128 reserveRiskyScaled) public returns (int128) {
        if(reserveRiskyScaled > ReplicationMath.ONE_INT) return zero;
        return ReplicationMath.ONE_INT.sub(reserveRiskyScaled).getInverseCDF();
    }

    /// @notice Fuzz { Step 3. + Step 1. }
    function testStep4(
        int128 reserve,
        uint64 sigma,
        uint32 tau
    ) public returns (int128) {
        return testStep3(reserve).add(testStep1(sigma, tau));
    }

    /// @notice Fuzz { Step 0. * getCDF( Step 4. ) + Invariant }
    function testStep5(
        uint128 strike,
        uint scaleFactorStable,
        int128 reserve,
        uint64 sigma,
        uint32 tau,
        int128 invariantLast
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
    ) public returns(uint) {
        if(sigma > RAY) return 0;
        if(scaleFactorRisky > WAD || scaleFactorStable > WAD) return 0;
        return ReplicationMath.getStableGivenRisky(invariantLast, scaleFactorRisky, scaleFactorStable, reserveRisky, strike, sigma, tau);
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
