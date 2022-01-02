// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "../utils/Hevm.sol";

contract Base is DSTest {
   Hevm internal constant hevm = Hevm(HEVM_ADDRESS);
   uint public constant WAD = 1e18;
   uint public constant MAX_WAD = 1e36;
   uint public constant RAY = 1e9;
   uint public constant MAX_SCALE_FACTOR = 1e12;
   int128 public constant MIN_64x64 = -0x80000000000000000000000000000000;
   int128 public constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
   uint256 public constant MAX_DIV = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
   uint public constant MAX_SIGMA = 1e7;
   uint public constant MIN_SIGMA = 100;
   uint public constant MAX_TAU = 10 * 365 * 24 * 60 * 60;
   function setUp() public virtual {}
}