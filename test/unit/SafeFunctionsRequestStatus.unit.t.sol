// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {SafeFunctionsRequestStatus, FunctionsRequestStatus} from "src/libraries/SafeFunctionsRequestStatus.sol";

contract SafeFunctionsRequestUnitTest is Test {
	function test_isUnknown_returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.UNKNOWN;

		assertTrue(SafeFunctionsRequestStatus.isUnknown(status));
	}

	function test_isRequested_returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.REQUESTED;

		assertTrue(SafeFunctionsRequestStatus.isRequested(status));
	}

	function test_isSucceeded_returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.SUCCEEDED;

		assertTrue(SafeFunctionsRequestStatus.isSucceeded(status));
	}

	function test_isFailed_returnsTrue() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.FAILED;

		assertTrue(SafeFunctionsRequestStatus.isFailed(status));
	}

	function test_isUnknown_returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.SUCCEEDED;

		assertFalse(SafeFunctionsRequestStatus.isUnknown(status));
	}

	function test_isRequested_returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.UNKNOWN;

		assertFalse(SafeFunctionsRequestStatus.isRequested(status));
	}

	function test_isSucceeded_returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.FAILED;

		assertFalse(SafeFunctionsRequestStatus.isSucceeded(status));
	}

	function test_isFailed_returnsFalse() external pure {
		FunctionsRequestStatus status = FunctionsRequestStatus.REQUESTED;

		assertFalse(SafeFunctionsRequestStatus.isFailed(status));
	}
}
