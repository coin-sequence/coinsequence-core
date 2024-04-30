// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FunctionsRequestStatus} from "src/types/FunctionsRequestStatus.sol";

library SafeFunctionsRequestStatus {
	function _isUnknown(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.UNKNOWN;
	}

	function _isRequested(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.REQUESTED;
	}

	function _isSucceeded(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.SUCCEEDED;
	}

	function _isFailed(FunctionsRequestStatus status) internal pure returns (bool) {
		return status == FunctionsRequestStatus.FAILED;
	}
}
