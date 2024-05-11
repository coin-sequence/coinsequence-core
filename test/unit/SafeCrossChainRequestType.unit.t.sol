// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeCrossChainRequestType, CrossChainRequestType} from "src/libraries/SafeCrossChainRequestType.sol";

contract SafeCrossChainRequestTypeUnitTest is Test {
	function test_isCreatePool() external pure {
		CrossChainRequestType requestType = CrossChainRequestType.CREATE_POOL;

		assertTrue(SafeCrossChainRequestType.isCreatePool(requestType));
	}

	function test_isAddToken() external pure {
		CrossChainRequestType requestType = CrossChainRequestType.ADD_TOKEN;

		assertTrue(SafeCrossChainRequestType.isAddToken(requestType));
	}

	function test_isNotCreatePool() external pure {
		CrossChainRequestType requestType = CrossChainRequestType.ADD_TOKEN;

		assertFalse(SafeCrossChainRequestType.isCreatePool(requestType));
	}

	function test_isNotAddToken() external pure {
		CrossChainRequestType requestType = CrossChainRequestType.CREATE_POOL;

		assertFalse(SafeCrossChainRequestType.isAddToken(requestType));
	}
}
