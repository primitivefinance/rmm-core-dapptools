// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "./MockFactory.sol";
import "./TestToken.sol";
import "./TestBase.sol";

/// @notice updateLastTimestamp(), create(), deposit(), withdraw(), allocate(), remove(), swap(), invariantOf()
contract MockEngineTest is TestBase {
    uint public constant DEFAULT_STRIKE = 10 * WAD;
    uint64 public constant DEFAULT_SIGMA = 100 * 1e4;
    uint32 public DEFAULT_MATURITY = uint32(Units.YEAR + 1);
    uint public constant DEFAULT_DELTA = WAD * 69 / 100;
    bytes public constant data = new bytes(0);

    TestToken public riskyToken;
    TestToken public stableToken;

    MockFactory.Args public args;

    bytes32 public poolId;

    function setUp() public override {
        scenario == Scenario.SUCCESS;
        caller = address(this);

        riskyToken = new TestToken("Test Risky", "Risky", 18);
        stableToken = new TestToken("Test Stable", "Stable", 18);

        args = MockFactory.Args({
            factory: address(this),
            risky: address(riskyToken),
            stable: address(stableToken),
            scaleFactorRisky: 10**(18 - 18),
            scaleFactorStable: 10**(18 - 18),
            minLiquidity: 1e3
        });

        engine = new MockEngine{salt: keccak256(abi.encode(address(riskyToken), address(stableToken)))}();

        assertEq(engine.risky(), address(riskyToken), "Risky does not match");
        assertEq(engine.stable(), address(stableToken), "Stable does not match");

        riskyToken.approve(address(engine), type(uint256).max);
        stableToken.approve(address(engine), type(uint256).max);
        riskyToken.approve(address(this), type(uint256).max);
        stableToken.approve(address(this), type(uint256).max);

        riskyToken.mint(address(this), type(uint128).max);
        stableToken.mint(address(this), type(uint128).max);

        engine.deposit(address(this), WAD * 1e5, WAD * 1e5, data);

        uint expectedStable = ReplicationMath.getStableGivenRisky(0, 1, 1, WAD - DEFAULT_DELTA, DEFAULT_STRIKE, 1e4, DEFAULT_MATURITY - 1);
        assertTrue(expectedStable > 0, "Stable is zero");

        (poolId,,) = engine.create(DEFAULT_STRIKE, 1e4, DEFAULT_MATURITY, DEFAULT_DELTA, WAD, data);
    }

    modifier post() {
        _;
        scenario = Scenario.SUCCESS;
    }

    // ===== Create =====

    /// @notice Fuzz create
    function testCreate(
        uint128 strike,
        uint64 sigma,
        uint32 maturity,
        uint128 delta,
        uint128 delLiquidity
    ) public {
        if(delLiquidity == 0 || strike == 0 || sigma == 0 || maturity == 0 || delta == 0) return;
        if(WAD - delta > riskyToken.balanceOf(address(this))) return;
        caller = address(this);
        engine.create(strike, sigma, maturity, delta, delLiquidity, data);
    }

    // ===== Margin =====

    /// @notice Fuzz deposit
    function testDeposit(
        address owner,
        uint128 delRisky,
        uint128 delStable
    ) public {
        if(delRisky == 0 && delStable == 0) return;
        if(delRisky > riskyToken.balanceOf(address(this))) return;
        if(delStable > stableToken.balanceOf(address(this))) return;
        caller = address(this);
        engine.deposit(owner, delRisky, delStable, data);
    }

    /// @notice Revert on failing to pay for deposit
    function testFailDeposit(
        address owner,
        uint128 delRisky,
        uint128 delStable
    ) public post {
        if(delRisky == 0 && delStable == 0) return;
        if(delRisky > riskyToken.balanceOf(address(this))) return;
        if(delStable > stableToken.balanceOf(address(this))) return;
        caller = address(this);
        scenario = Scenario.FAIL;
        engine.deposit(owner, delRisky, delStable, data);
    }

    /// @notice Fail on reentrancy
    function testFailDepositReentrancy(
        address owner,
        uint128 delRisky,
        uint128 delStable
    ) public {
        if(delRisky == 0 && delStable == 0) return;
        if(delRisky > riskyToken.balanceOf(address(this))) return;
        if(delStable > stableToken.balanceOf(address(this))) return;
        caller = address(this);
        scenario = Scenario.REENTRANCY;
        engine.deposit(owner, delRisky, delStable, data);
    }

    /// @notice Fail on depositng only risky token with both amounts > 0
    function testFailDepositOnlyRisky(
        address owner,
        uint128 delRisky,
        uint128 delStable
    ) public post {
        if(delRisky == 0 && delStable == 0) return;
        if(delRisky > riskyToken.balanceOf(address(this))) return;
        if(delStable > stableToken.balanceOf(address(this))) return;
        caller = address(this);
        scenario = Scenario.RISKY_ONLY;
        engine.deposit(owner, delRisky, delStable, data);
    }

    /// @notice Fail on depositng only stable token with both amounts > 0
    function testFailDepositOnlyStable(
        address owner,
        uint128 delRisky,
        uint128 delStable
    ) public post {
        if(delRisky == 0 && delStable == 0) return;
        if(delRisky > riskyToken.balanceOf(address(this))) return;
        if(delStable > stableToken.balanceOf(address(this))) return;
        caller = address(this);
        scenario = Scenario.STABLE_ONLY;
        engine.deposit(owner, delRisky, delStable, data);
    }

    /// @notice Fuzz withdraw
    function testWithdraw(uint128 delRisky, uint128 delStable) public {
        if(delRisky == 0 && delStable == 0) return;
        if(delRisky > riskyToken.balanceOf(address(this))) return;
        if(delStable > stableToken.balanceOf(address(this))) return;
        caller = address(this);
        engine.deposit(msg.sender, delRisky, delStable, data);
        engine.withdraw(msg.sender, delRisky, delStable);
    }

    /// @notice Fuzz withdrawing to recipient
    function testWithdrawToRecipient(
        address recipient,
        uint128 delRisky,
        uint128 delStable
    ) public {
        if(delRisky == 0 && delStable == 0) return;
        if(delRisky > riskyToken.balanceOf(address(this))) return;
        if(delStable > stableToken.balanceOf(address(this))) return;
        caller = address(this);
        engine.deposit(recipient, delRisky, delStable, data);
        engine.withdraw(recipient, delRisky, delStable);
    }

    // ===== Allocate =====

    /// @notice Fuzz allocate
    function testAllocate(
        address owner,
        uint128 delLiquidity
    ) public {
        if(delLiquidity == 0) return;
        engine.allocate(poolId, owner, delLiquidity, false, data);
    }

    /// @notice Fuzz allocating from margin account
    function testAllocateFromMargin(
        address owner,
        uint128 delLiquidity
    ) public {
        if(delLiquidity == 0) return;
        engine.allocate(poolId, owner, delLiquidity, true, data);
    }

    /// @notice Fuzz allocating from external account
    function testAllocateFromExternal(
        address owner,
        uint128 delLiquidity
    ) public {
        if(delLiquidity == 0) return;
        caller = address(this);
        engine.allocate(poolId, owner, delLiquidity, false, data);
    }

    /// @notice Revert on failing to pay for risky tokens on allocate
    function testFailAllocateFromExternalNoRisky(
        address owner,
        uint128 delLiquidity
    ) public post {
        caller = address(this);
        scenario = Scenario.STABLE_ONLY;
        engine.allocate(poolId, owner, delLiquidity, false, data);
    }

    /// @notice Revert on failing to pay for stable tokens on allocate
    function testFailAllocateFromExternalNoStable(
        address owner,
        uint128 delLiquidity
    ) public post {
        if(delLiquidity == 0) return;
        caller = address(this);
        scenario = Scenario.RISKY_ONLY;
        engine.allocate(poolId, owner, delLiquidity, false, data);
    }

    /// @notice Fail on reentrancy
    function testFailAllocateFromExternalReentrancy(
        address owner,
        uint128 delLiquidity
    ) public post {
        caller = address(this);
        scenario = Scenario.REENTRANCY;
        engine.allocate(poolId, owner, delLiquidity, false, data);
    }

    // ===== Remove =====

    /// @notice Fuzz remove
    function testRemove(
        uint128 delLiquidity
    ) public {
        if(delLiquidity == 0) return;
        engine.remove(poolId, delLiquidity);
    }

    // ===== Swaps =====

    /// @notice Fuzz swaps
    function testSwap(
        bool riskyForStable,
        uint128 deltaIn,
        bool toMargin
    ) public {
        if(deltaIn == 0) return;
        caller = address(this);
        engine.swap(poolId, riskyForStable, deltaIn, false, toMargin, data);
    }

    /// @notice Fuzz swaps after time has passed
    function testSwapMockTime(
        uint32 tau,
        bool riskyForStable,
        uint128 deltaIn,
        bool toMargin
    ) public {
        if(deltaIn == 0) return;
        caller = address(this);
        (,,uint32 maturity,) = engine.calibrations(poolId);
        if(tau > maturity + engine.BUFFER()) return;
        engine.advanceTime(tau);
        engine.swap(poolId, riskyForStable, deltaIn, false, toMargin, data);
    }
}