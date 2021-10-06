// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   getStableGivenRisky()
contract TestGetStableGivenRiskyLib is Base {
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
    function testStep0(uint128 strike, uint8 stableDecimals) public returns (int128) {
        if(stableDecimals > 18 || stableDecimals < 6) return zero;
        uint scaleFactorStable = 10**(18 - stableDecimals);
        if(int256(uint(strike)) > MAX_64x64 || strike > MAX_WAD) return zero;
        int128 K = uint(strike).scaleToX64(scaleFactorStable);
        uint256 X = K.scalefromX64(scaleFactorStable);
        assertTrue(strike >= uint128(X));
        return K;
    }

    /// @notice Fuzz { sigma * sqrt( tau ) }
    function testStep1(uint64 sigma, uint32 tau) public pure returns (int128) {
        if(tau > MAX_TAU) return zero;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return zero;
        return ReplicationMath.getProportionalVolatility(sigma, tau);
    }

    /// @notice Fuzz scaling of reserveRisky to its respective decimals
    function testStep2(uint128 reserveRisky, uint8 riskyDecimals) public {
        if(riskyDecimals > 18 || riskyDecimals < 6) return;
        uint scaleFactorRisky = 10**(18 - riskyDecimals);
        if(int256(uint(reserveRisky)) > MAX_64x64 || reserveRisky > MAX_WAD) return;
        if(uint(reserveRisky) / (WAD / scaleFactorRisky) > MAX_DIV) return;
        int128 reserve = uint(reserveRisky).scaleToX64(scaleFactorRisky);
        uint256 scaled = reserve.scalefromX64(scaleFactorRisky);
        assertTrue(reserveRisky >= uint128(scaled));
    }

    /// @notice Fuzz { getInverseCDF( 1 - reserveRiskyScaled ) }
    function testStep3(int128 reserveRiskyScaled) public pure returns (int128) {
        if(reserveRiskyScaled > ReplicationMath.ONE_INT || reserveRiskyScaled < 0) return zero;
        int128 input = ReplicationMath.ONE_INT.sub(reserveRiskyScaled);
        if (input <= 0 || input >= ReplicationMath.ONE_INT) return zero;
        return input.getInverseCDF();
    }

    /// @notice Fuzz { Step 3. + Step 1. }
    function testStep4(
        int128 reserve,
        uint64 sigma,
        uint32 tau
    ) public pure returns (int128) {
        if(tau > MAX_TAU) return zero;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return zero;
        if(reserve < 0) return zero;
        return testStep3(reserve).add(testStep1(sigma, tau));
    }

    /// @notice Fuzz { Step 0. * getCDF( Step 4. ) + Invariant }
    function testStep5(
        uint128 strike,
        uint8 stableDecimals,
        int128 reserve,
        uint64 sigma,
        uint32 tau,
        int128 invariantLast
    ) public {
        if(tau > MAX_TAU) return;
        if(invariantLast > MAX_64x64) return;
        if(reserve > MAX_64x64 || reserve < 0) return;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return;
        if(stableDecimals > 18 || stableDecimals < 6) return;
        testStep0(strike, stableDecimals).mul(testStep4(reserve, sigma, tau).getCDF()).add(invariantLast);
    }

    /// @notice Fuzz getStableGivenRisky
    function testGetStableGivenRisky(
        int128 invariantLast,
        uint8 riskyDecimals,
        uint8 stableDecimals,
        uint128 reserveRisky,
        uint128 strike,
        uint64 sigma,
        uint32 tau
    ) public pure returns(uint) {
        if(tau > MAX_TAU) return 0;
        if(invariantLast > MAX_64x64) return 0;
        if(reserveRisky < 0) return 0;
        if(strike < 0) return 0;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return 0;
        if(stableDecimals > 18 || stableDecimals < 6) return 0;
        if(riskyDecimals > 18 || riskyDecimals < 6) return 0;
        uint scaleFactorStable = 10**(18 - stableDecimals);
        uint scaleFactorRisky = 10**(18 - riskyDecimals);
        return ReplicationMath.getStableGivenRisky(invariantLast, scaleFactorRisky, scaleFactorStable, reserveRisky, strike, sigma, tau);
    }
}
