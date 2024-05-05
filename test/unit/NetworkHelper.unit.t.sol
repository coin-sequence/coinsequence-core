// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {NetworkHelper, SafeChain} from "script/helpers/NetworkHelper.sol";

contract NetworkHelperUnitTest is Test {
	function test_getNetworkConfig_forSepolia() external {
		vm.chainId(SafeChain.SEPOLIA_ID);

		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper.getNetworkConfig();

		assertEq(networkConfig.chainId, SafeChain.SEPOLIA_ID, "Chain ID does not match");
		assertEq(
			networkConfig.functionsRouter,
			0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
			"Functions router address does not match"
		);
		assertEq(networkConfig.functionsSubscriptionId, 2413, "Functions subscription ID does not match");
		assertEq(networkConfig.functionsCallbackGasLimit, 200_000, "Functions callback gas limit does not match");
		assertEq(networkConfig.functionsDonId, "fun-ethereum-sepolia-1", "Functions DON ID does not match");
	}

	function test_getNetworkConfig_forAnvil() external {
		vm.chainId(SafeChain.ANVIL_ID);

		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper.getNetworkConfig();

		assertEq(networkConfig.chainId, SafeChain.ANVIL_ID, "Chain ID does not match");
		assertEq(networkConfig.functionsRouter, address(0), "Functions router address does not match");
		assertEq(networkConfig.functionsSubscriptionId, 0, "Functions subscription ID does not match");
		assertEq(networkConfig.functionsCallbackGasLimit, 200_000, "Functions callback gas limit does not match");
		assertEq(networkConfig.functionsDonId, "fun-anvil-foundry-1", "Functions DON ID does not match");
	}

	function test_getNetworkConfig_revertsIfChainIsNotConfigured() external {
		uint256 notConfiguredChain = 12345678;
		vm.chainId(notConfiguredChain);

		vm.expectRevert(abi.encodeWithSelector(NetworkHelper.UnknownChainConfig.selector, notConfiguredChain));
		NetworkHelper.getNetworkConfig();
	}
}
