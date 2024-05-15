// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeChain} from "src/libraries/SafeChain.sol";

contract SafeChainUnitTest is Test {
	function test_isSepolia_returnsTrue() external {
		vm.chainId(11155111);

		assertTrue(SafeChain.isSepolia(block.chainid));
	}

	function test_isSepolia_returnsFalse() external {
		vm.chainId(1);

		assertFalse(SafeChain.isSepolia(block.chainid));
	}

	function test_isArbitrumSepolia_returnsTrue() external {
		vm.chainId(421614);

		assertTrue(SafeChain.isArbitrumSepolia(block.chainid));
	}

	function test_isArbitrumSepolia_returnsFalse() external {
		vm.chainId(11155111);

		assertFalse(SafeChain.isArbitrumSepolia(block.chainid));
	}

	function test_isBaseSepolia_returnsTrue() external {
		vm.chainId(84532);

		assertTrue(SafeChain.isBaseSepolia(block.chainid));
	}

	function test_isBaseSepolia_returnsFalse() external {
		vm.chainId(11155111);

		assertFalse(SafeChain.isBaseSepolia(block.chainid));
	}

	function test_isOptimismSepolia_returnsTrue() external {
		vm.chainId(11155420);

		assertTrue(SafeChain.isOptimismSepolia(block.chainid));
	}

	function test_isOptimismSepolia_returnsFalse() external {
		vm.chainId(11155111);

		assertFalse(SafeChain.isOptimismSepolia(block.chainid));
	}

	function test_isAnvil_returnsTrue() external {
		vm.chainId(31337);

		assertTrue(SafeChain.isAnvil(block.chainid));
	}

	function test_isAnvil_returnsFalse() external {
		vm.chainId(11155111);

		assertFalse(SafeChain.isAnvil(block.chainid));
	}
}
