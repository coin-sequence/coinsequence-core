//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Arrays} from "src/libraries/Arrays.sol";

import {Test} from "forge-std/Test.sol";

contract ArraysUnitTest is Test {
	function test_sum() external pure {
		uint256[] memory elements = new uint256[](3);
		elements[0] = 1;
		elements[1] = 5;
		elements[2] = 10;

		assertEq(Arrays.sum(elements), 16);
	}

	function test_sort() external pure {
		address[] memory elements = new address[](3);
		elements[0] = address(10);
		elements[1] = address(1);
		elements[2] = address(5);

		elements = Arrays.sort(elements);

		assertEq(elements[0], address(1));
		assertEq(elements[1], address(5));
		assertEq(elements[2], address(10));
	}
}
