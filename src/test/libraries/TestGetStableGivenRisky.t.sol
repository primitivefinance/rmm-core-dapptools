// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   Test Get Stable Given Risky
/// @author  Primitive
/// @dev     Tests each step in ReplicationMath.getStableGivenRisky. For testing ONLY
contract TestGetStableGivenRisky is Base {
    using ABDKMath64x64 for *; // stores numerators as int128, denominator is 2^64.
    using CumulativeNormalDistribution for int128;
    using Units for int128;
    using Units for uint256;

    uint256 public scaleFactorRisky;
    uint256 public scaleFactorStable;

    function set(uint256 prec0, uint256 prec1) public {
        scaleFactorRisky = prec0;
        scaleFactorStable = prec1;
    }

    function PRECISION() public pure returns (uint256) {
        return Units.PRECISION;
    }

    function step0(uint256 strike) public view returns (int128 K) {
        K = strike.scaleToX64(scaleFactorStable);
    }

    function step1(uint256 sigma, uint256 tau) public pure returns (int128 vol) {
        vol = ReplicationMath.getProportionalVolatility(sigma, tau);
    }

    function step2(uint256 reserveRisky) public view returns (int128 reserve) {
        reserve = reserveRisky.scaleToX64(scaleFactorRisky);
    }

    function step3(int128 reserve) public pure returns (int128 phi) {
        phi = ReplicationMath.ONE_INT.sub(reserve).getInverseCDF(); // CDF^-1(1-x)
    }

    function step4(int128 phi, int128 vol) public pure returns (int128 input) {
        input = phi.sub(vol); // phi - vol
    }

    function step5(
        int128 K,
        int128 input,
        int128 invariantLast
    ) public pure returns (int128 reserveStable) {
        reserveStable = K.mul(input.getCDF()).add(invariantLast);
    }

    function testStep3(uint256 reserve) public view returns (int128 phi) {
        phi = ReplicationMath.ONE_INT.sub(reserve.scaleToX64(scaleFactorRisky)).getInverseCDF();
    }

    function testStep4(
        uint256 reserve,
        uint64 sigma,
        uint64 tau
    ) public view returns (int128 input) {
        int128 phi = testStep3(reserve);
        int128 vol = step1(sigma, tau);
        input = phi.sub(vol);
    }

    function testStep5(
        uint256 reserve,
        uint256 strike,
        uint64 sigma,
        uint64 tau
    ) public view returns (int128 reserveStable) {
        int128 input = testStep4(reserve, sigma, tau);
        reserveStable = strike.scaleToX64(scaleFactorStable).mul(input.getCDF());
    }

    /// @return reserveStable The calculated stable reserve, using the risky reserve
    function testGetStableGivenRisky(
        int128 invariantLast,
        uint256 scaleFactor0,
        uint256 scaleFactor1,
        uint256 reserveRisky,
        uint256 strike,
        uint64 sigma,
        uint64 tau
    ) public pure returns (uint reserveStable) {
        reserveStable = ReplicationMath.getStableGivenRisky(invariantLast, scaleFactor0, scaleFactor1, reserveRisky, strike, sigma, tau);
    }
}
