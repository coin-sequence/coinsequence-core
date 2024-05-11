// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Receipt} from "src/libraries/Receipt.sol";

library SafeCrossChainReceipt {
	function isSuccess(Receipt.CrossChainReceiptType receiptType) internal pure returns (bool) {
		return receiptType == Receipt.CrossChainReceiptType.SUCCESS;
	}

	function isFailure(Receipt.CrossChainReceiptType receiptType) internal pure returns (bool) {
		return receiptType == Receipt.CrossChainReceiptType.FAILURE;
	}

	function isPoolCreated(Receipt.CrossChainSuccessReceiptType successReceiptType) internal pure returns (bool) {
		return successReceiptType == Receipt.CrossChainSuccessReceiptType.POOL_CREATED;
	}
}
