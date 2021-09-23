// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "../engine/MockEngine.sol";
import "./MockFactory.sol";
import "./utils/Base.sol";
import "./TestToken.sol";

/// @notice deploy()
contract MockFactoryTest is Base {

    MockFactory public factory;
    TestToken public default;

    function setUp() public override {
        factory = new MockFactory();
        default = new TestToken("Test Default Token", "TDT", 18);
    }

    /// @notice Fuzz deploy
    function testDeploy() public {
        TestToken risky = new TestToken("Test Token", "TT", 18);
        address engine = factory.deploy(address(risky), address(default));
        assertTrue(factory.getEngine(address(risky), address(default)), engine, "Engines not equal");
    }

    ///  @notice Prove deploy
    function proveDeploy() public {
        testDeploy();
    }

    /// @notice Fails on attempting to deploy an Engine for token with > 18 or < 6 decimals
    function testDeployDecimals(uint8 decimals) public {
        if(decimals > 18 || decimals < 6) return;
        TestToken risky = new TestToken("Test Decimals", "TD", decimals);
        address engine = factory.deploy(address(risky), address(default));
        if(decimals < 18) 
            assertTrue(MockEngine(engine).MIN_LIQUIDITY == 10**(decimals / 6), "Min liq not equal");
    }

    /// @notice Fails on attempting to deploy an Engine for token with > 18 or < 6 decimals
    function testFailDeployDecimals(uint8 decimals) public {
        if(decimals < 19 || decimals > 5) return;
        TestToken risky = new TestToken("Test Low Decimals", "TLD", decimals);
        factory.deploy(address(risky), address(default));
    }

    /// @notice Fails on attempting to deploy an Engine for token with > 18 or < 6 decimals
    function testFailDeployZeroAddress() public {
        factory.deploy(address(0x0), address(default));
        factory.deploy(address(default), address(0x0));
    }

    /// @notice Fails on attempting to deploy an Engine for token with > 18 or < 6 decimals
    function testFailDeploySameAddress() public {
        factory.deploy(address(default), address(default));
    }
}