// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CustomCast} from "src/libraries/CustomCast.sol";
import {Test} from "forge-std/Test.sol";

contract CustomCastFuzzTest is Test {
	function testFuzz_toIERC20List_doesNotRevert(address[] memory tokens) external pure {
		CustomCast.toIERC20List(tokens);
	}

	function testFuzz_toIAssetList_doesNotRevert(address[] memory tokens) external pure {
		CustomCast.toIAssetList(tokens);
	}
}
