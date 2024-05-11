// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {Receipt as CCIPReceipt} from "src/libraries/Receipt.sol";

contract ReceiptFuzzTest is Test {
	function testFuzz_crossChainPoolCreatedReceipt_chainId(
		uint64 chainId,
		address poolAddress,
		bytes32 poolId,
		address[] calldata tokens
	) external {
		vm.chainId(chainId);

		CCIPReceipt.CrossChainReceipt memory receipt = CCIPReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens);

		assertEq(receipt.chainId, chainId, "Receipt Chain ID should match with the chain sent");
	}

	function testFezz__crossChainGenericFailedReceipt_chainId(uint64 chainId) external {
		vm.chainId(chainId);

		CCIPReceipt.CrossChainReceipt memory receipt = CCIPReceipt.crossChainGenericFailedReceipt(
			CCIPReceipt.CrossChainFailureReceiptType.POOL_CREATION_FAILED
		);

		assertEq(receipt.chainId, chainId, "Receipt Chain ID should match with the chain sent");
	}

	function testFuzz_crossChainPoolCreatedReceipt_receiptType(address poolAddress, bytes32 poolId, address[] calldata tokens) external view {
		CCIPReceipt.CrossChainReceipt memory receipt = CCIPReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens);

		assertTrue(receipt.receiptType == CCIPReceipt.CrossChainReceiptType.SUCCESS, "Receipt type should be success");
	}

	function testFuzz_crossChainPoolCreatedReceipt_successReceiptType(
		address poolAddress,
		bytes32 poolId,
		address[] calldata tokens
	) external view {
		CCIPReceipt.CrossChainReceipt memory receipt = CCIPReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens);

		CCIPReceipt.CrossChainSuccessReceiptType successReceiptType = abi.decode(receipt.data, (CCIPReceipt.CrossChainSuccessReceiptType));

		assertTrue(
			successReceiptType == CCIPReceipt.CrossChainSuccessReceiptType.POOL_CREATED,
			"The receipt success type should be `POOL_CREATED`"
		);
	}

	function testFuzz_crossChainPoolCreatedReceipt_data(address poolAddress, bytes32 poolId, address[] calldata tokens) external view {
		CCIPReceipt.CrossChainReceipt memory receipt = CCIPReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens);

		(, CCIPReceipt.CrossChainPoolCreatedReceipt memory receiptData) = abi.decode(
			receipt.data,
			(CCIPReceipt.CrossChainSuccessReceiptType, CCIPReceipt.CrossChainPoolCreatedReceipt)
		);

		assertEq(receiptData.poolAddress, poolAddress, "Pool address of the receipt doesn't match with the input");
		assertEq(receiptData.poolId, poolId, "Pool id of the receipt doesn't match with the input");
		assertEq(receiptData.tokens, tokens, "Tokens of the receipt doesn't match with the input");
	}

	function testFuzz_crossChainGenericFailedReceipt_receiptType() external view {
		CCIPReceipt.CrossChainReceipt memory receipt = CCIPReceipt.crossChainGenericFailedReceipt(
			CCIPReceipt.CrossChainFailureReceiptType.POOL_CREATION_FAILED
		);

		assertTrue(receipt.receiptType == CCIPReceipt.CrossChainReceiptType.FAILURE, "Receipt type should be failure");
	}

	function testFuzz_crossChainGenericFailedReceipt_data(uint8 failureReceiptType) external view {
		vm.assume(failureReceiptType <= uint8(type(CCIPReceipt.CrossChainFailureReceiptType).max));

		CCIPReceipt.CrossChainReceipt memory receipt = CCIPReceipt.crossChainGenericFailedReceipt(
			CCIPReceipt.CrossChainFailureReceiptType(failureReceiptType)
		);

		CCIPReceipt.CrossChainFailureReceiptType receiptData = abi.decode(receipt.data, (CCIPReceipt.CrossChainFailureReceiptType));

		assertTrue(
			receiptData == CCIPReceipt.CrossChainFailureReceiptType(failureReceiptType),
			"The receipt failure type should be of the same type as the input"
		);
	}
}
