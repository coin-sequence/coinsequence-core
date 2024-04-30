// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeFunctionsRequestStatus, FunctionsRequestStatus} from "src/libraries/SafeFunctionsRequestStatus.sol";

contract SafeFunctionsRequestUnitTest is Test {
	function test_isUnknown__returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.UNKNOWN;

		assertTrue(SafeFunctionsRequestStatus._isUnknown(status));
	}

	function test_isRequested__returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.REQUESTED;

		assertTrue(SafeFunctionsRequestStatus._isRequested(status));
	}

	function test_isSucceeded__returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.SUCCEEDED;

		assertTrue(SafeFunctionsRequestStatus._isSucceeded(status));
	}

	function test_isFailed__returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.FAILED;

		assertTrue(SafeFunctionsRequestStatus._isFailed(status));
	}

	function test_isUnknown__returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.SUCCEEDED;

		assertFalse(SafeFunctionsRequestStatus._isUnknown(status));
	}

	function test_isRequested__returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.UNKNOWN;

		assertFalse(SafeFunctionsRequestStatus._isRequested(status));
	}

	function test_isSucceeded__returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.FAILED;

		assertFalse(SafeFunctionsRequestStatus._isSucceeded(status));
	}

	function test_isFailed__returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.REQUESTED;

		assertFalse(SafeFunctionsRequestStatus._isFailed(status));
	}
}
