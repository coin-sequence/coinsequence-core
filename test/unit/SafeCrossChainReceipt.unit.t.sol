// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {Receipt as CCIPReceipt} from "src/libraries/Receipt.sol";
import {SafeCrossChainReceipt} from "src/libraries/SafeCrossChainReceipt.sol";

contract SafeCrossChainReceiptUnitTest is Test {
	function test_isSuccess() external pure {
		assertTrue(SafeCrossChainReceipt.isSuccess(CCIPReceipt.CrossChainReceiptType.SUCCESS));
	}

	function test_isFailure() external pure {
		assertTrue(SafeCrossChainReceipt.isFailure(CCIPReceipt.CrossChainReceiptType.FAILURE));
	}

	function test_isNotSuccess() external pure {
		assertFalse(SafeCrossChainReceipt.isSuccess(CCIPReceipt.CrossChainReceiptType.FAILURE));
	}

	function test_isNotFailure() external pure {
		assertFalse(SafeCrossChainReceipt.isFailure(CCIPReceipt.CrossChainReceiptType.SUCCESS));
	}

	function test_isPoolCreated() external pure {
		assertTrue(SafeCrossChainReceipt.isPoolCreated(CCIPReceipt.CrossChainSuccessReceiptType.POOL_CREATED));
	}

	function test_isNotPoolCreated() external pure {
		assertFalse(SafeCrossChainReceipt.isPoolCreated(CCIPReceipt.CrossChainSuccessReceiptType.TOKEN_ADDED));
	}
}
