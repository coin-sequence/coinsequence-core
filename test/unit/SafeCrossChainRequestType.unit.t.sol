// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeCrossChainRequestType, CrossChainRequest} from "src/libraries/SafeCrossChainRequestType.sol";

contract SafeCrossChainRequestTypeUnitTest is Test {
	function test_isCreatePool() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.CREATE_POOL;

		assertTrue(SafeCrossChainRequestType.isCreatePool(requestType));
	}

	function test_isAddToken() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.ADD_TOKEN;

		assertTrue(SafeCrossChainRequestType.isAddToken(requestType));
	}

	function test_isNotCreatePool() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.ADD_TOKEN;

		assertFalse(SafeCrossChainRequestType.isCreatePool(requestType));
	}

	function test_isNotAddToken() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.CREATE_POOL;

		assertFalse(SafeCrossChainRequestType.isAddToken(requestType));
	}
}
