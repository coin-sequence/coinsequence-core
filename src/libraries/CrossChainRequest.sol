// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IAsset} from "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";

library CrossChainRequest {
	enum CrossChainRequestType {
		CREATE_POOL,
		ADD_TOKEN,
		DEPOSIT
	}

	struct CrossChainCreatePoolRequest {
		address[] tokens;
		string poolName;
	}

	struct CrossChainDepositRequest {
		bytes32 depositId;
		IAsset[] joinTokens;
		bytes32 poolId;
		uint256 minBPTOut;
		address swapProvider;
		bytes[] swapsCalldata;
	}
}
