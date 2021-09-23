// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefinance/v2-core/contracts/libraries/Margin.sol";
import "../utils/Base.sol";

/// @title   deposit(), withdraw()
contract TestMargin is Base {
    using Margin for Margin.Data;
    using Margin for mapping(address => Margin.Data);

    /// @notice Mapping used for testing
    mapping(address => Margin.Data) public margins;

    /// @notice Fuzz deposit
    function testDeposit(uint128 delRisky, uint128 delStable) public {
        uint128 preX = margins[msg.sender].balanceRisky;
        uint128 preY = margins[msg.sender].balanceStable;
        margins[msg.sender].deposit(delRisky, delStable);
        assertTrue(preX + delRisky >= margins[msg.sender].balanceRisky, "Risky did not increase");
        assertTrue(preY + delStable >= margins[msg.sender].balanceStable, "Stable did not increase");
    }

    /// @notice Fuzz withdraw
    function testWithdraw(uint128 delRisky, uint128 delStable) public {
        testDeposit(delRisky, delStable);
        uint128 preX = margins[msg.sender].balanceRisky;
        uint128 preY = margins[msg.sender].balanceStable;
        margins[msg.sender] = margins.withdraw(delRisky, delStable);
        assertTrue(preX - delRisky >= margins[msg.sender].balanceRisky, "Risky did not decrease");
        assertTrue(preY - delStable >= margins[msg.sender].balanceStable, "Stable did not decrease");
        assertEq(margins[msg.sender].balanceRisky, 0);
        assertEq(margins[msg.sender].balanceStable, 0);
    }
}
