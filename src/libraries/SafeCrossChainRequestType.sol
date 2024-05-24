// SPDX-License-Identifier: MIT
// solhint-disable chainlink-solidity/prefix-internal-functions-with-underscore
pragma solidity 0.8.25;

import {CrossChainRequest} from "src/libraries/CrossChainRequest.sol";

library SafeCrossChainRequestType {
	function isCreatePool(CrossChainRequest.CrossChainRequestType requestType) internal pure returns (bool) {
		return requestType == CrossChainRequest.CrossChainRequestType.CREATE_POOL;
	}

	function isDeposit(CrossChainRequest.CrossChainRequestType requestType) internal pure returns (bool) {
		return requestType == CrossChainRequest.CrossChainRequestType.DEPOSIT;
	}

	function isWithdraw(CrossChainRequest.CrossChainRequestType requestType) internal pure returns (bool) {
		return requestType == CrossChainRequest.CrossChainRequestType.WITHDRAW;
	}
}
