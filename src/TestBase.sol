// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "./callbacks/TestAllocateCallback.sol";
import "./callbacks/TestCreateCallback.sol";
import "./callbacks/TestDepositCallback.sol";
import "./callbacks/TestSwapCallback.sol";
import "./MockEngine.sol";
import "./utils/Base.sol";

contract TestBase is Base, TestAllocateCallback, TestCreateCallback, TestDepositCallback, TestSwapCallback {
    MockEngine public engine;
    address public caller;

    function risky() public view override(Scenarios) returns (address) {
        return engine.risky();
    }

    function stable() public view override(Scenarios) returns (address) {
        return engine.stable();
    }

    function getCaller() public view override(Scenarios) returns (address) {
        return caller;
    }
}
