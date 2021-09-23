// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   Test Get Risky Given Stable
/// @author  Primitive
/// @dev     Tests each step in ReplicationMath.getRiskyGivenStable. For testing ONLY
contract TestGetRiskyGivenStable is Base {
    using ABDKMath64x64 for *; // stores numerators as int128, denominator is 2^64.
    using CumulativeNormalDistribution for int128;
    using Units for int128;
    using Units for uint256;

    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 public scaleFactorRisky;
    uint256 public scaleFactorStable;

    function set(uint256 prec0, uint256 prec1) public {
        scaleFactorRisky = prec0;
        scaleFactorStable = prec1;
    }

    function testStep0(uint256 strike) public view returns (int128 K) {
        K = strike.scaleToX64(scaleFactorStable);
    }

    function testStep1(uint64 sigma, uint64 tau) public pure returns (int128 vol) {
        vol = ReplicationMath.getProportionalVolatility(sigma, tau);
    }

    function testStep2(uint256 reserveStable) public view returns (int128 reserve) {
        reserve = reserveStable.scaleToX64(scaleFactorStable);
    }

    function testStep3(
        int128 reserve,
        int128 invariantLast,
        int128 K
    ) public pure returns (int128 phi) {
        if(reserve > MAX_64x64) return int128(0);
        if(invariantLast > MAX_64x64) return int128(0);
        if(K > MAX_64x64) return int128(0);
        phi = reserve.sub(invariantLast).div(K).getInverseCDF(); // CDF^-1((reserveStable - invariantLast)/K)
    }

    function testStep4(int128 phi, int128 vol) public pure returns (int128 input) {
        input = phi.add(vol); // phi + vol
    }

    function testStep5(int128 input) public pure returns (int128 reserveRisky) {
        reserveRisky = ReplicationMath.ONE_INT.sub(input.getCDF());
    }

    /// @return reserveRisky The calculated risky reserve, using the stable reserve
    function testGetRiskyGivenStable(
        int128 invariantLast,
        uint256 scaleFactor0,
        uint256 scaleFactor1,
        uint128 reserveStable,
        uint128 strike,
        uint64 sigma,
        uint64 tau
    ) public pure returns (uint reserveRisky) {
        reserveRisky = ReplicationMath.getRiskyGivenStable(invariantLast, scaleFactor0, scaleFactor1, reserveStable, strike, sigma, tau);
    }
}
