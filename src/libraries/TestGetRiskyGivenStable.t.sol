// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   getRiskyGivenStable()
contract TestGetRiskyGivenStable is Base {
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

    /// @notice Fuzz scaling of reserveStable to its respective decimals
    function testStep2(uint128 reserveStable, uint scaleFactorStable) public {
        if(scaleFactorStable > WAD) return;
        int128 reserve = uint(reserveStable).scaleToX64(scaleFactorStable);
        uint256 scaled = reserve.scalefromX64(scaleFactorStable);
        assertEq(reserveStable, uint128(scaled));
    }

    /// @notice Prove scaling of reserveStable to its respective decimal places
    function proveStep2(uint128 reserveStable, uint scaleFactorStable) public {
        testStep2(reserveStable, scaleFactorStable);
    }

    /// @notice Fuzz { getInverseCDF( ( reserveStableScaled - invariantLast ) / K ) }
    function testStep3(
        int128 reserve,
        int128 invariantLast,
        int128 K
    ) public returns (int128) {
        if(K > MAX_64x64 || K == 0) return zero;
        if(reserve > MAX_64x64) return zero;
        if(invariantLast > MAX_64x64) return zero;
        int128 input = reserve.sub(invariantLast).div(K);
        if (input == 0 || input >= ReplicationMath.ONE_INT) return zero;
        return input.getInverseCDF();
    }

    /// @notice Fuzz { Step 3. + Step 1. }
    function testStep4(
        int128 reserve,
        int128 invariantLast,
        int128 K,
        uint64 sigma,
        uint32 tau
    ) public returns (int128) {
        return testStep3(reserve, invariantLast, K).add(testStep1(sigma, tau));
    }

    /// @notice Fuzz { 1 - getCDF( Step 4. ) }
    function testStep5(
        int128 reserve,
        int128 invariantLast,
        int128 K,
        uint64 sigma,
        uint32 tau
    ) public {
        ReplicationMath.ONE_INT.sub(testStep4(reserve, invariantLast, K, sigma, tau).getCDF());
    }

    /// @notice Fuzz getRiskyGivenStable
    function testGetRiskyGivenStable(
        int128 invariantLast,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint128 reserveStable,
        uint128 strike,
        uint64 sigma,
        uint32 tau
    ) public returns (uint) {
        if(sigma > RAY) return 0;
        if(scaleFactorRisky > WAD || scaleFactorStable > WAD) return 0;
        return ReplicationMath.getRiskyGivenStable(invariantLast, scaleFactorRisky, scaleFactorStable, reserveStable, strike, sigma, tau);
    }

    /// @notice Prove getRiskyGivenStable
    function proveGetRiskyGivenStable(
        int128 invariantLast,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint128 reserveStable,
        uint128 strike,
        uint64 sigma,
        uint32 tau
    ) public {
        uint256 risky = testGetRiskyGivenStable(invariantLast, scaleFactorRisky, scaleFactorStable, reserveStable, strike, sigma, tau);
        assertTrue(type(uint128).max > risky, "Risky is larger than uint128");
    }
}
