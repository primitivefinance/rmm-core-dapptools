// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/Reserve.sol";
import "../utils/Base.sol";

/// @title update(), allocate(), remove(), swap(), getAmounts()
contract TestReserveLib is Base {
    using Reserve for Reserve.Data;
    using Reserve for mapping(bytes32 => Reserve.Data);

    bytes32 public constant resId = keccak256(abi.encodePacked("res"));

    /// @notice All the reserve data structs to use for testing
    mapping(bytes32 => Reserve.Data) public reserves;

    /// @notice Initializes reserves with `resId` for use in each test
    function setReserves(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity) public {
        reserves[resId] = Reserve.Data({
            reserveRisky: (reserveRisky), // risky token balance
            reserveStable: (reserveStable), // stable token balance
            liquidity: (liquidity),
            blockTimestamp: 1,
            cumulativeRisky: 0,
            cumulativeStable: 0,
            cumulativeLiquidity: 0
        });
    }

    /// @notice Fuzz update
    function testUpdate(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity, uint32 blockTimestamp) public {
        if(blockTimestamp == 0) return;
        if(liquidity == 0) return;
        setReserves(reserveRisky, reserveStable, liquidity);
        reserves[resId].update(blockTimestamp);
    }

    /// @notice Fuzz swap
    function testSwap(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        bool addXRemoveY,
        uint128 deltaIn,
        uint128 deltaOut,
        uint32 blockTimestamp
    ) public {
        if(blockTimestamp == 0) return;
        if(liquidity == 0) return;
        setReserves(reserveRisky, reserveStable, liquidity);

        if(addXRemoveY) {
            if(deltaOut > reserveStable) return;
            if(uint(reserveRisky) + uint(deltaIn) > type(uint128).max) return;
        } else {
            if(deltaOut > reserveRisky) return;
            if(uint(reserveStable) + uint(deltaIn) > type(uint128).max) return;
        }


        reserves[resId].swap(addXRemoveY, deltaIn, deltaOut, blockTimestamp);
    }

    /// @notice Fuzz allocate
    function testAllocate(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        uint128 delRisky,
        uint128 delStable,
        uint128 delLiquidity,
        uint32 blockTimestamp
    ) public {
        if(blockTimestamp == 0) return;
        if(liquidity == 0) return;
        setReserves(reserveRisky, reserveStable, liquidity);
        if(uint(reserveRisky) + uint(delRisky) > type(uint128).max) return;
        if(uint(reserveStable) + uint(delStable) > type(uint128).max) return;
        if(uint(liquidity) + uint(delLiquidity) > type(uint128).max) return;
        reserves[resId].allocate(delRisky, delStable, delLiquidity, blockTimestamp);
    }

    /// @notice Fuzz remove
    function testRemove(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        uint128 delRisky,
        uint128 delStable,
        uint128 delLiquidity,
        uint32 blockTimestamp
    ) public {
        if(blockTimestamp == 0) return;
        if(liquidity == 0) return;
        setReserves(reserveRisky, reserveStable, liquidity);
        if(delRisky > reserveRisky) return;
        if(delStable > reserveStable) return;
        if(delLiquidity > liquidity) return;
        reserves[resId].remove(delRisky, delStable, delLiquidity, blockTimestamp);
    }

    /// @notice Fuzz getAmounts
    function testGetAmounts(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        uint128 delLiquidity
    ) public {
        if(liquidity == 0) return;
        setReserves(reserveRisky, reserveStable, liquidity);
        if(delLiquidity > liquidity) return;
        reserves[resId].getAmounts(delLiquidity);
    }
}
