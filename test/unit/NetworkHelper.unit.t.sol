// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {NetworkHelper, SafeChain} from "src/libraries/NetworkHelper.sol";

contract NetworkHelperUnitTest is Test {
	function test__getNetworkConfig_forSepolia() external {
		vm.chainId(SafeChain.SEPOLIA_ID);

		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper._getNetworkConfig();

		assertEq(networkConfig.chainId, SafeChain.SEPOLIA_ID, "Chain ID does not match");
		assertEq(
			networkConfig.balancerManagedPoolFactory,
			0x63e179C5b6d54B2c2e36b9cE4085EF5A8C86D50c,
			"Balancer managed pool factory address does not match"
		);
		assertEq(networkConfig.balancerVault, 0xBA12222222228d8Ba445958a75a0704d566BF2C8, "Balancer vault address does not match");
		assertEq(networkConfig.ccipChainSelector, 16015286601757825753, "CCIP chain selector does not match");
		assertEq(networkConfig.ccipRouter, 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59, "CCIP router address does not match");
		assertEq(networkConfig.usdcAddress, 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238, "USDC address does not match");
	}

	function test__getNetworkConfig_forArbitrumSepolia() external {
		vm.chainId(SafeChain.ARBITRUM_SEPOLIA_ID);

		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper._getNetworkConfig();

		assertEq(networkConfig.chainId, SafeChain.ARBITRUM_SEPOLIA_ID, "Chain ID does not match");
		assertEq(
			networkConfig.balancerManagedPoolFactory,
			0x63aC8774e758e71cdE1CE9E14EEB3bcD1B9D09c3,
			"Balancer managed pool factory address does not match"
		);
		assertEq(networkConfig.balancerVault, 0x75DFc9064614498EDD9FAd00857d4917CAaDdeE5, "Balancer vault address does not match");
		assertEq(networkConfig.ccipChainSelector, 3478487238524512106, "CCIP chain selector does not match");
		assertEq(networkConfig.ccipRouter, 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165, "CCIP router address does not match");
		assertEq(networkConfig.usdcAddress, 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d, "USDC address does not match");
	}

	function test__getNetworkConfig_forBaseSepolia() external {
		vm.chainId(SafeChain.BASE_SEPOLIA_ID);

		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper._getNetworkConfig();

		assertEq(networkConfig.chainId, SafeChain.BASE_SEPOLIA_ID, "Chain ID does not match");
		assertEq(
			networkConfig.balancerManagedPoolFactory,
			0xfB91Ffbc39344560c46EE1e214B367887F0bE754,
			"Balancer managed pool factory address does not match"
		);
		assertEq(networkConfig.balancerVault, 0x5cc729e3099e6372E0e9406613E043e609d789be, "Balancer vault address does not match");
		assertEq(networkConfig.ccipChainSelector, 10344971235874465080, "CCIP chain selector does not match");
		assertEq(networkConfig.ccipRouter, 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93, "CCIP router address does not match");
		assertEq(networkConfig.usdcAddress, 0x036CbD53842c5426634e7929541eC2318f3dCF7e, "USDC address does not match");
	}

	function test__getNetworkConfig_forOptimismSepolia() external {
		vm.chainId(SafeChain.OPTIMISM_SEPOLIA_ID);

		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper._getNetworkConfig();

		assertEq(networkConfig.chainId, SafeChain.OPTIMISM_SEPOLIA_ID, "Chain ID does not match");
		assertEq(
			networkConfig.balancerManagedPoolFactory,
			0x63aC8774e758e71cdE1CE9E14EEB3bcD1B9D09c3,
			"Balancer managed pool factory address does not match"
		);
		assertEq(networkConfig.balancerVault, 0x75DFc9064614498EDD9FAd00857d4917CAaDdeE5, "Balancer vault address does not match");
		assertEq(networkConfig.ccipChainSelector, 5224473277236331295, "CCIP chain selector does not match");
		assertEq(networkConfig.ccipRouter, 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57, "CCIP router address does not match");
		assertEq(networkConfig.usdcAddress, 0x5fd84259d66Cd46123540766Be93DFE6D43130D7, "USDC address does not match");
	}

	function test__getNetworkConfig_forAnvil() external {
		vm.chainId(SafeChain.ANVIL_ID);

		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper._getNetworkConfig();

		assertEq(networkConfig.chainId, SafeChain.ANVIL_ID, "Chain ID does not match");
		assertEq(networkConfig.balancerManagedPoolFactory, address(0), "Balancer managed pool factory address does not match");
		assertEq(networkConfig.balancerVault, address(0), "Balancer vault address does not match");
		assertEq(networkConfig.ccipChainSelector, 0, "CCIP chain selector does not match");
		assertEq(networkConfig.ccipRouter, address(0), "CCIP router address does not match");
		assertEq(networkConfig.usdcAddress, address(0), "USDC address does not match");
	}
}
