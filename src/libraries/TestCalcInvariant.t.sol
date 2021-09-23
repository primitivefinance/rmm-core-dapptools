// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   calcInvariant()
contract TestCalcInvariant is Base {
    /// @notice Fuzz calcInvariant
    function testCalcInvariant(
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint128 riskyPerLiquidity,
        uint128 stablePerLiquidity,
        uint128 strike,
        uint32 sigma,
        uint32 tau
    ) public {
        if(sigma > RAY) return;
        if(scaleFactorRisky > WAD || scaleFactorStable > WAD) return;
        ReplicationMath.calcInvariant(scaleFactorRisky, scaleFactorStable, riskyPerLiquidity, stablePerLiquidity, strike, sigma, tau);
    }

    /// @notice Prove calcInvariant
    function proveCalcInvariant(
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint128 riskyPerLiquidity,
        uint128 stablePerLiquidity,
        uint128 strike,
        uint32 sigma,
        uint32 tau
    ) public {
        if(sigma > RAY) return;
        if(scaleFactorRisky > WAD || scaleFactorStable > WAD) return;
        ReplicationMath.calcInvariant(scaleFactorRisky, scaleFactorStable, riskyPerLiquidity, stablePerLiquidity, strike, sigma, tau);
    }
}
