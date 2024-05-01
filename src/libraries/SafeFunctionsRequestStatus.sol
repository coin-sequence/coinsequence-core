// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FunctionsRequestStatus} from "src/types/FunctionsRequestStatus.sol";

// solhint-disable chainlink-solidity/prefix-internal-functions-with-underscore
library SafeFunctionsRequestStatus {
	function isUnknown(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.UNKNOWN;
	}

	function isRequested(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.REQUESTED;
	}

	function isSucceeded(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.SUCCEEDED;
	}

	function isFailed(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.FAILED;
	}
}
