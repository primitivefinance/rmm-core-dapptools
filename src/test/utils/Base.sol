// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "ds-test/test.sol";
import "../utils/Hevm.sol";

contract Base is DSTest {
   Hevm internal constant hevm = Hevm(HEVM_ADDRESS);
   function setUp() public virtual {}
}