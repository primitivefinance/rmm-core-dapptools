// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/Reserve.sol";
import "../utils/Base.sol";

/// @title update(), allocate(), remove(), swap(), getAmounts()
contract TestReserve is Base {
    using Reserve for Reserve.Data;
    using Reserve for mapping(bytes32 => Reserve.Data);

    bytes32 public constant resId = keccak256(abi.encodePacked("res"));

    /// @notice All the reserve data structs to use for testing
    mapping(bytes32 => Reserve.Data) public reserves;

    /// @notice Initializes reserves with `resId` for use in each test
    function setReserves(uint reserveRisky, uint reserveStable, uint liquidity) public {
        reserves[resId] = Reserve.Data({
            reserveRisky: uint128(reserveRisky), // risky token balance
            reserveStable: uint128(reserveStable), // stable token balance
            liquidity: uint128(liquidity),
            blockTimestamp: 1,
            cumulativeRisky: 0,
            cumulativeStable: 0,
            cumulativeLiquidity: 0
        });
    }

    /// @notice Used for testing
    function res() public view returns (Reserve.Data storage) {
        return reserves[resId];
    }

    /// @notice Fuzz update
    function testUpdate(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity, uint32 blockTimestamp) public {
        setReserves(reserveRisky, reserveStable, liquidity);
        res().update(blockTimestamp);
    }

    /// @notice Prove update
    function proveUpdate(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity, uint32 blockTimestamp) public {
        testUpdate(reserveRisky, reserveStable, liquidity, blockTimestamp);
    }

    /// @notice Fuzz swap
    function testSwap(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        bool addXRemoveY,
        uint128 deltaIn,
        uint128 deltaOut,
        uint32 blockTimestamp
    ) public {
        setReserves(reserveRisky, reserveStable, liquidity);

        if(addXRemoveY) {
            if(deltaOut > reserveStable) return;
        } else {
            if(deltaOut > reserveRisky) return;
        }

        res().swap(addXRemoveY, deltaIn, deltaOut, blockTimestamp);
    }

    /// @notice Fuzz allocate
    function testAllocate(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        uint128 delRisky,
        uint128 delStable,
        uint128 delLiquidity,
        uint32 blockTimestamp
    ) public {
        setReserves(reserveRisky, reserveStable, liquidity);
        res().allocate(delRisky, delStable, delLiquidity, blockTimestamp);
    }

    /// @notice Fuzz remove
    function testRemove(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        uint128 delRisky,
        uint128 delStable,
        uint128 delLiquidity,
        uint32 blockTimestamp
    ) public {
        setReserves(reserveRisky, reserveStable, liquidity);
        if(delRisky > reserveRisky) return;
        if(delStable > reserveStable) return;
        if(delLiquidity > liquidity) return;
        res().remove(delRisky, delStable, delLiquidity, blockTimestamp);
    }

    /// @notice Fuzz getAmounts
    function testGetAmounts(uint128 reserveRisky, uint128 reserveStable, uint128 liquidity,
        uint128 delLiquidity
    ) public {
        setReserves(reserveRisky, reserveStable, liquidity);
        if(delLiquidity > liquidity) return;
        res().getAmounts(delLiquidity);
    }
}
