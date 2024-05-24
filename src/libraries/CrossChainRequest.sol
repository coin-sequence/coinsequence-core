// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

library CrossChainRequest {
	enum CrossChainRequestType {
		CREATE_POOL,
		DEPOSIT,
		WITHDRAW
	}

	struct CrossChainCreatePoolRequest {
		address[] tokens;
		string poolName;
	}

	struct CrossChainDepositRequest {
		bytes32 depositId;
		bytes32 poolId;
		uint256 minBPTOut;
		address swapProvider;
		bytes[] swapsCalldata;
	}

	struct CrossChainWithdrawRequest {
		bytes32 withdrawalId;
		bytes32 poolId;
		uint256 bptAmountIn;
		uint256 exitTokenIndex;
		uint256 exitTokenMinAmountOut;
		address swapProvider;
		bytes swapCalldata;
	}
}
