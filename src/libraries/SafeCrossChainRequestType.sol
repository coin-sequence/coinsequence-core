// SPDX-License-Identifier: MIT
// solhint-disable chainlink-solidity/prefix-internal-functions-with-underscore
pragma solidity 0.8.25;

import {CrossChainRequestType} from "src/types/CrossChainRequestType.sol";

library SafeCrossChainRequestType {
	function isCreatePool(CrossChainRequestType requestType) internal pure returns (bool) {
		return requestType == CrossChainRequestType.CREATE_POOL;
	}

	function isAddToken(CrossChainRequestType requestType) internal pure returns (bool) {
		return requestType == CrossChainRequestType.ADD_TOKEN;
	}
}
