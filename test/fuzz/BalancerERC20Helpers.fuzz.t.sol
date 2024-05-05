// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {BalancerERC20Helpers, IERC20} from "src/libraries/BalancerERC20Helpers.sol";

contract BalancerERC20HelpersTest is Test {
	function test_asIAsset_doesNotRevert(IERC20[] memory tokens) external pure {
		BalancerERC20Helpers.asIAsset(tokens);
	}
}
