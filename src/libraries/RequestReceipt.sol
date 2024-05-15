// SPDX-License-Identifier: MIT
// solhint-disable chainlink-solidity/prefix-internal-functions-with-underscore
pragma solidity 0.8.25;

library RequestReceipt {
	enum CrossChainReceiptType {
		SUCCESS,
		FAILURE
	}

	enum CrossChainSuccessReceiptType {
		POOL_CREATED,
		TOKEN_ADDED
	}

	enum CrossChainFailureReceiptType {
		POOL_CREATION_FAILED,
		TOKEN_ADDITION_FAILED
	}

	struct CrossChainPoolCreatedReceipt {
		address poolAddress;
		bytes32 poolId;
		address[] tokens;
	}

	struct CrossChainReceipt {
		CrossChainReceiptType receiptType;
		uint256 chainId;
		bytes data;
	}

	function crossChainPoolCreatedReceipt(
		address poolAddress,
		bytes32 poolId,
		address[] memory tokens
	) internal view returns (CrossChainReceipt memory) {
		return
			CrossChainReceipt({
				receiptType: CrossChainReceiptType.SUCCESS,
				chainId: block.chainid,
				data: abi.encode(
					CrossChainSuccessReceiptType.POOL_CREATED,
					CrossChainPoolCreatedReceipt({poolAddress: poolAddress, poolId: poolId, tokens: tokens})
				)
			});
	}

	function crossChainGenericFailedReceipt(
		CrossChainFailureReceiptType failureReceiptType
	) internal view returns (CrossChainReceipt memory) {
		return CrossChainReceipt({receiptType: CrossChainReceiptType.FAILURE, chainId: block.chainid, data: abi.encode(failureReceiptType)});
	}
}
