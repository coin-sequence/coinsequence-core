// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {RequestReceipt} from "src/libraries/RequestReceipt.sol";

contract ReceiptFuzzTest is Test {
	function testFuzz_crossChainPoolCreatedReceipt_chainId(
		uint64 chainId,
		address poolAddress,
		bytes32 poolId,
		address[] calldata tokens,
		uint256[] calldata weights
	) external {
		vm.chainId(chainId);

		RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens, weights);

		assertEq(receipt.chainId, chainId, "Receipt Chain ID should match with the chain sent");
	}

	function testFezz__crossChainGenericFailedReceipt_chainId(uint64 chainId) external {
		vm.chainId(chainId);

		RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainGenericFailedReceipt(
			RequestReceipt.CrossChainFailureReceiptType.POOL_CREATION_FAILED
		);

		assertEq(receipt.chainId, chainId, "Receipt Chain ID should match with the chain sent");
	}

	function testFuzz_crossChainPoolCreatedReceipt_receiptType(
		address poolAddress,
		bytes32 poolId,
		address[] calldata tokens,
		uint256[] calldata weights
	) external view {
		RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens, weights);

		assertTrue(receipt.receiptType == RequestReceipt.CrossChainReceiptType.SUCCESS, "Receipt type should be success");
	}

	function testFuzz_crossChainPoolCreatedReceipt_successReceiptType(
		address poolAddress,
		bytes32 poolId,
		address[] calldata tokens,
		uint256[] calldata weights
	) external view {
		RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens, weights);

		RequestReceipt.CrossChainSuccessReceiptType successReceiptType = abi.decode(
			receipt.data,
			(RequestReceipt.CrossChainSuccessReceiptType)
		);

		assertTrue(
			successReceiptType == RequestReceipt.CrossChainSuccessReceiptType.POOL_CREATED,
			"The receipt success type should be `POOL_CREATED`"
		);
	}

	function testFuzz_crossChainPoolCreatedReceipt_data(
		address poolAddress,
		bytes32 poolId,
		address[] calldata tokens,
		uint256[] calldata weights
	) external view {
		RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, tokens, weights);

		(, RequestReceipt.CrossChainPoolCreatedReceipt memory receiptData) = abi.decode(
			receipt.data,
			(RequestReceipt.CrossChainSuccessReceiptType, RequestReceipt.CrossChainPoolCreatedReceipt)
		);

		assertEq(receiptData.poolAddress, poolAddress, "Pool address of the receipt doesn't match with the input");
		assertEq(receiptData.poolId, poolId, "Pool id of the receipt doesn't match with the input");
		assertEq(receiptData.tokens, tokens, "Tokens of the receipt doesn't match with the input");
		assertEq(receiptData.weights, weights, "Weights of the receipt doesn't match with the input");
	}

	function testFuzz_crossChainGenericFailedReceipt_receiptType() external view {
		RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainGenericFailedReceipt(
			RequestReceipt.CrossChainFailureReceiptType.POOL_CREATION_FAILED
		);

		assertTrue(receipt.receiptType == RequestReceipt.CrossChainReceiptType.FAILURE, "Receipt type should be failure");
	}

	function testFuzz_crossChainGenericFailedReceipt_data(uint8 failureReceiptType) external view {
		vm.assume(failureReceiptType <= uint8(type(RequestReceipt.CrossChainFailureReceiptType).max));

		RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainGenericFailedReceipt(
			RequestReceipt.CrossChainFailureReceiptType(failureReceiptType)
		);

		RequestReceipt.CrossChainFailureReceiptType receiptData = abi.decode(receipt.data, (RequestReceipt.CrossChainFailureReceiptType));

		assertTrue(
			receiptData == RequestReceipt.CrossChainFailureReceiptType(failureReceiptType),
			"The receipt failure type should be of the same type as the input"
		);
	}
}
