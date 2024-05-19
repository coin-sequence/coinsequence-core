// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Arrays} from "src/libraries/Arrays.sol";
import {Test} from "forge-std/Test.sol";

contract ArraysFuzzTest is Test {
	function testFuzz_sum(uint8[] memory elements) external pure {
		uint256[] memory elementsAsUint256;

		vm.assume(elements.length < 10); // limit the input size to avoid slow down the test
		uint256 expectedResult;

		for (uint256 i = 0; i < elements.length; i++) {
			expectedResult += elements[i];
		}

		assembly {
			elementsAsUint256 := elements
		}

		assertEq(Arrays.sum(elementsAsUint256), expectedResult);
	}

	function testFuzz_sort(address[] memory elements) external pure {
		elements = Arrays.sort(elements);

		for (uint256 i = 1; i < elements.length; i++) {
			assert(elements[i - 1] <= elements[i]);
		}
	}
}
