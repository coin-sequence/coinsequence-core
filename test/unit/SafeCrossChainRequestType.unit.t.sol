// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeCrossChainRequestType, CrossChainRequest} from "src/libraries/SafeCrossChainRequestType.sol";

contract SafeCrossChainRequestTypeUnitTest is Test {
	function test_isCreatePool() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.CREATE_POOL;

		assertTrue(SafeCrossChainRequestType.isCreatePool(requestType));
	}

	function test_isNotCreatePool() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.DEPOSIT;

		assertFalse(SafeCrossChainRequestType.isCreatePool(requestType));
	}

	function test_isDeposit() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.DEPOSIT;

		assertTrue(SafeCrossChainRequestType.isDeposit(requestType));
	}

	function test_isNotDeposit() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.CREATE_POOL;

		assertFalse(SafeCrossChainRequestType.isDeposit(requestType));
	}

	function test_isWithdraw() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.WITHDRAW;

		assertTrue(SafeCrossChainRequestType.isWithdraw(requestType));
	}

	function test_isNotWithdraw() external pure {
		CrossChainRequest.CrossChainRequestType requestType = CrossChainRequest.CrossChainRequestType.DEPOSIT;

		assertFalse(SafeCrossChainRequestType.isWithdraw(requestType));
	}
}
