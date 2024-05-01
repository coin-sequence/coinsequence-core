// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeChainId} from "src/libraries/SafeChainId.sol";

contract SafeChainIdUnitTest is Test {
	function test_isSepolia_returnsTrue() external {
		vm.chainId(11155111);

		assertTrue(SafeChainId.isSepolia(block.chainid));
	}

	function test_isSepolia_returnsFalse() external {
		vm.chainId(1);

		assertFalse(SafeChainId.isSepolia(block.chainid));
	}

	function test_isAnvil_returnsTrue() external {
		vm.chainId(31337);

		assertTrue(SafeChainId.isAnvil(block.chainid));
	}

	function test_isAnvil_returnsFalse() external {
		vm.chainId(11155111);

		assertFalse(SafeChainId.isAnvil(block.chainid));
	}
}
