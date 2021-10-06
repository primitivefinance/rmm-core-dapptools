// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   getRiskyGivenStable()
contract TestGetRiskyGivenStableLib is Base {
    using ABDKMath64x64 for *;
    using CumulativeNormalDistribution for int128;
    using Units for int128;
    using Units for uint256;

    int128 public constant zero = int128(0);

    /// 0. Scale strike to respective decimals
    /// 1. Calculate { sigma * sqrt( tau ) }
    /// 2. Scale reserveStable to respective decimals
    /// 3. Calculate { getInverseCDF( ( reserveStableScaled - invariantLast ) / K ) }
    /// 4. Calculate { Step 3. + Step 1. }
    /// 5. Calculate { 1 - getCDF( Step 4. ) }

    /// @notice Fuzz scaling of strike to its respective decimal places
    function testStep0(uint128 strike, uint8 stableDecimals) public returns (int128) {
        if(stableDecimals > 18 || stableDecimals < 6) return zero;
        uint scaleFactorStable = 10**(18 - stableDecimals);
        if(int256(uint(strike)) > MAX_64x64 || strike > MAX_WAD) return zero;
        if(int256(uint(strike) / scaleFactorStable) > MAX_64x64) return zero;
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

    /// @notice Fuzz scaling of reserveStable to its respective decimals
    function testStep2(uint128 reserveStable, uint8 stableDecimals) public {
        if(stableDecimals > 18) return;
        if(stableDecimals < 6) return;
        uint scaleFactorStable = 10**(18 - stableDecimals);
        if(int256(uint(reserveStable)) > MAX_64x64 || reserveStable > MAX_WAD) return;
        if(uint(reserveStable) / (WAD / scaleFactorStable) > MAX_DIV) return;
        int128 reserve = uint(reserveStable).scaleToX64(scaleFactorStable);
        uint256 scaled = reserve.scalefromX64(scaleFactorStable);
        assertTrue(reserveStable >= uint128(scaled));
    }

    /// @notice Fuzz { getInverseCDF( ( reserveStableScaled - invariantLast ) / K ) }
    function testStep3(
        int128 reserve,
        int128 invariantLast,
        int128 K
    ) public pure returns (int128) {
        if(K > MAX_64x64 || K <= 0) return zero;
        if(reserve > MAX_64x64 || reserve < 0) return zero;
        if(invariantLast > MAX_64x64) return zero;
        int256 expected = int256(reserve) - invariantLast;
        if(expected < MIN_64x64 || expected > MAX_64x64) return zero;
        int128 numerator = reserve.sub(invariantLast);
        if(numerator <= K) return zero;
        int128 input = numerator.div(K);
        if (input <= 0 || input >= ReplicationMath.ONE_INT) return zero;
        return input.getInverseCDF();
    }

    /// @notice Fuzz { Step 3. + Step 1. }
    function testStep4(
        int128 reserve,
        int128 invariantLast,
        int128 K,
        uint64 sigma,
        uint32 tau
    ) public pure returns (int128) {
        if(tau > MAX_TAU) return zero;
        if(K > MAX_64x64 || K <= 0) return zero;
        if(invariantLast > MAX_64x64) return zero;
        if(reserve > MAX_64x64 ||reserve < 0) return zero;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return zero;
        return testStep3(reserve, invariantLast, K).add(testStep1(sigma, tau));
    }

    /// @notice Fuzz { 1 - getCDF( Step 4. ) }
    function testStep5(
        int128 reserve,
        int128 invariantLast,
        int128 K,
        uint64 sigma,
        uint32 tau
    ) public pure {
        if(tau > MAX_TAU) return;
        if(K > MAX_64x64 || K <= 0) return;
        if(reserve > MAX_64x64 || reserve < 0) return;
        if(invariantLast > MAX_64x64) return;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return;
        int256 expected = int256(reserve) - invariantLast;
        if(expected < MIN_64x64 || expected > MAX_64x64) return;
        int128 numerator = reserve.sub(invariantLast);
        int128 input = numerator.div(K);
        if (input <= 0 || input >= ReplicationMath.ONE_INT || input == 1) return;
        ReplicationMath.ONE_INT.sub(testStep4(reserve, invariantLast, K, sigma, tau).getCDF());
    }

    /// @notice Fuzz getRiskyGivenStable
    function testGetRiskyGivenStable(
        int128 invariantLast,
        uint8 riskyDecimals,
        uint8 stableDecimals,
        uint128 reserveStable,
        uint128 strike,
        uint64 sigma,
        uint32 tau
    ) public pure returns (uint) {
        if(tau > MAX_TAU) return 0;
        if(invariantLast > MAX_64x64) return 0;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return 0;
        if(stableDecimals > 18 || stableDecimals < 6) return 0;
        if(riskyDecimals > 18 || riskyDecimals < 6) return 0;
        uint scaleFactorStable = 10**(18 - stableDecimals);
        uint scaleFactorRisky = 10**(18 - riskyDecimals);
        return ReplicationMath.getRiskyGivenStable(invariantLast, scaleFactorRisky, scaleFactorStable, reserveStable, strike, sigma, tau);
    }
}
