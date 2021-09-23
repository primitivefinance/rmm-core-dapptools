// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "../utils/Hevm.sol";

contract Base is DSTest {
   Hevm internal constant hevm = Hevm(HEVM_ADDRESS);
   uint public constant WAD = 1e18;
   uint public constant RAY = 1e9;
   int128 public constant MIN_64x64 = -0x80000000000000000000000000000000;
   int128 public constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
   function setUp() public virtual {}
}