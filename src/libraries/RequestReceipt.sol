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
		TOKEN_ADDED,
		DEPOSITED
	}

	enum CrossChainFailureReceiptType {
		POOL_CREATION_FAILED,
		TOKEN_ADDITION_FAILED,
		DEPOSIT_FAILED
	}

	struct CrossChainPoolCreatedReceipt {
		address poolAddress;
		bytes32 poolId;
		address[] tokens;
	}

	struct CrossChainDepositedReceipt {
		bytes32 depositId;
		uint256 receivedBPT;
	}

	struct CrossChainDepositFailedReceipt {
		bytes32 depositId;
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
			_successReceipt(
				abi.encode(
					CrossChainSuccessReceiptType.POOL_CREATED,
					CrossChainPoolCreatedReceipt({poolAddress: poolAddress, poolId: poolId, tokens: tokens})
				)
			);
	}

	function crossChainDepositedReceipt(bytes32 depositId, uint256 bptReceived) internal view returns (CrossChainReceipt memory) {
		return _successReceipt(abi.encode(CrossChainSuccessReceiptType.DEPOSITED, CrossChainDepositedReceipt(depositId, bptReceived)));
	}

	function crossChainDepositFailedReceipt(bytes32 depositId) internal view returns (CrossChainReceipt memory) {
		return _failureReceipt(abi.encode(CrossChainFailureReceiptType.DEPOSIT_FAILED, CrossChainDepositFailedReceipt(depositId)));
	}

	function crossChainGenericFailedReceipt(
		CrossChainFailureReceiptType failureReceiptType
	) internal view returns (CrossChainReceipt memory) {
		return _failureReceipt(abi.encode(failureReceiptType));
	}

	function _successReceipt(bytes memory data) private view returns (CrossChainReceipt memory) {
		return CrossChainReceipt({receiptType: CrossChainReceiptType.SUCCESS, chainId: block.chainid, data: data});
	}

	function _failureReceipt(bytes memory data) private view returns (CrossChainReceipt memory) {
		return CrossChainReceipt({receiptType: CrossChainReceiptType.FAILURE, chainId: block.chainid, data: data});
	}
}
