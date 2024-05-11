// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeChain} from "src/libraries/SafeChain.sol";

contract SafeChainTest is Test {
	function testFuzz_isCurrent(uint64 chainId) external {
		vm.chainId(chainId);

		assertTrue(SafeChain.isCurrent(chainId));
	}
}
