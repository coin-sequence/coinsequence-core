// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {RequestReceipt} from "src/libraries/RequestReceipt.sol";
import {SafeCrossChainReceipt} from "src/libraries/SafeCrossChainReceipt.sol";

contract SafeCrossChainReceiptUnitTest is Test {
	function test_isSuccess() external pure {
		assertTrue(SafeCrossChainReceipt.isSuccess(RequestReceipt.CrossChainReceiptType.SUCCESS));
	}

	function test_isFailure() external pure {
		assertTrue(SafeCrossChainReceipt.isFailure(RequestReceipt.CrossChainReceiptType.FAILURE));
	}

	function test_isNotSuccess() external pure {
		assertFalse(SafeCrossChainReceipt.isSuccess(RequestReceipt.CrossChainReceiptType.FAILURE));
	}

	function test_isNotFailure() external pure {
		assertFalse(SafeCrossChainReceipt.isFailure(RequestReceipt.CrossChainReceiptType.SUCCESS));
	}

	function test_isPoolCreated() external pure {
		assertTrue(SafeCrossChainReceipt.isPoolCreated(RequestReceipt.CrossChainSuccessReceiptType.POOL_CREATED));
	}

	function test_isNotPoolCreated() external pure {
		assertFalse(SafeCrossChainReceipt.isPoolCreated(RequestReceipt.CrossChainSuccessReceiptType.DEPOSITED));
	}

	function test_isDeposited() external pure {
		assertTrue(SafeCrossChainReceipt.isDeposited(RequestReceipt.CrossChainSuccessReceiptType.DEPOSITED));
	}

	function test_isNotDeposited() external pure {
		assertFalse(SafeCrossChainReceipt.isDeposited(RequestReceipt.CrossChainSuccessReceiptType.POOL_CREATED));
	}

	function test_isWithdrawn() external pure {
		assertTrue(SafeCrossChainReceipt.isWithdrawn(RequestReceipt.CrossChainSuccessReceiptType.WITHDRAW));
	}

	function test_isNotWithdrawn() external pure {
		assertFalse(SafeCrossChainReceipt.isWithdrawn(RequestReceipt.CrossChainSuccessReceiptType.DEPOSITED));
	}
}
