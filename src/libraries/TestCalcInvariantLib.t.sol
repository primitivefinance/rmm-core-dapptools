// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/ReplicationMath.sol";
import "../utils/Base.sol";

/// @title   calcInvariant()
contract TestCalcInvariantLib is Base {
    /// @notice Fuzz calcInvariant
    function testCalcInvariant(
        uint8 riskyDecimals,
        uint8 stableDecimals,
        uint128 riskyPerLiquidity,
        uint128 stablePerLiquidity,
        uint128 strike,
        uint32 sigma,
        uint32 tau
    ) public pure {
        if(tau > MAX_TAU) return;
        if(sigma > MAX_SIGMA || sigma < MIN_SIGMA) return;
        if(stableDecimals > 18 || stableDecimals < 6) return;
        if(riskyDecimals > 18 || riskyDecimals < 6) return;
        if(riskyPerLiquidity > WAD || stablePerLiquidity > strike) return;
        uint scaleFactorStable = 10**(18 - stableDecimals);
        uint scaleFactorRisky = 10**(18 - riskyDecimals);
        ReplicationMath.calcInvariant(scaleFactorRisky, scaleFactorStable, riskyPerLiquidity, stablePerLiquidity, strike, sigma, tau);
    }
}
