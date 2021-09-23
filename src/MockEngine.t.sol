// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "./MockEngine.sol";
import "./utils/Base.sol";
import "./TestToken.sol";
import {Args} from "./MockFactory.sol";


contract MockEngineTest is Base {

    TestToken public risky;
    TestToken public stable;
    MockEngine public engine;

    Args public args;

    function setUp() public override {
        risky = new TestToken("Test Risky", "Risky", 18);
        stable = new TestToken("Test Stable", "Stable", 18);

        args = Args({
            factory: address(this),
            risky: address(risky),
            stable: address(stable),
            scaleFactorRisky: 1,
            scaleFactorStable: 1,
            minLiquidity: 1e3
        });

        engine = address(new MockEngine{salt: keccak256(abi.encode(risky, stable))}());

        risky.approve(address(engine), type(uint256).max);
        stable.approve(address(engine), type(uint256).max);

        risky.mint(address(this), WAD * 1e5);
        stable.mint(address(this), WAD * 1e5);
    }
}