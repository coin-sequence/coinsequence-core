// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeChain} from "src/libraries/SafeChain.sol";

library NetworkHelper {
	using SafeChain for uint256;

	//solhint-disable-next-line gas-struct-packing
	struct NetworkConfig {
		uint256 chainId;
		uint64 ccipChainSelector;
		address balancerManagedPoolFactory;
		address balancerVault;
		address ccipRouter;
		address ctfAdmin;
		address usdcAddress;
	}

	/// @notice thrown when the current block.chainid config is not defined yet
	error UnknownChainConfig(uint256 chainId);

	function _getNetworkConfig() internal view returns (NetworkConfig memory) {
		return
			NetworkConfig(
				block.chainid,
				_getCCIPChainSelector(block.chainid),
				_getBalancerManagedPoolFactory(),
				_getBalancerVault(),
				_getCCIPRouter(),
				_getCTFAdmin(),
				_getUSDC()
			);
	}

	function _getBalancerManagedPoolFactory() internal view returns (address balancerManagedPoolFactory) {
		if (block.chainid.isSepolia()) return 0x63e179C5b6d54B2c2e36b9cE4085EF5A8C86D50c;
		if (block.chainid.isArbitrumSepolia()) return 0x63aC8774e758e71cdE1CE9E14EEB3bcD1B9D09c3;
		if (block.chainid.isBaseSepolia()) return 0xfB91Ffbc39344560c46EE1e214B367887F0bE754;
		if (block.chainid.isOptimismSepolia()) return 0x63aC8774e758e71cdE1CE9E14EEB3bcD1B9D09c3;
		if (block.chainid.isAnvil()) return address(0);

		revert UnknownChainConfig(block.chainid);
	}

	function _getBalancerVault() internal view returns (address balancerVault) {
		if (block.chainid.isSepolia()) return 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
		if (block.chainid.isArbitrumSepolia()) return 0x75DFc9064614498EDD9FAd00857d4917CAaDdeE5;
		if (block.chainid.isBaseSepolia()) return 0x5cc729e3099e6372E0e9406613E043e609d789be;
		if (block.chainid.isOptimismSepolia()) return 0x75DFc9064614498EDD9FAd00857d4917CAaDdeE5;
		if (block.chainid.isAnvil()) return address(0);

		revert UnknownChainConfig(block.chainid);
	}

	function _getCCIPRouter() internal view returns (address ccipRouter) {
		if (block.chainid.isSepolia()) return 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
		if (block.chainid.isArbitrumSepolia()) return 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;
		if (block.chainid.isBaseSepolia()) return 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
		if (block.chainid.isOptimismSepolia()) return 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57;
		if (block.chainid.isAnvil()) return address(0);
	}

	function _getUSDC() internal view returns (address usdc) {
		if (block.chainid.isSepolia()) return 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
		if (block.chainid.isArbitrumSepolia()) return 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d;
		if (block.chainid.isBaseSepolia()) return 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
		if (block.chainid.isOptimismSepolia()) return 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;
		if (block.chainid.isAnvil()) return address(0);
	}

	function _getCCIPChainSelector(uint256 chainid) internal pure returns (uint64 ccipChainSelector) {
		if (chainid.isSepolia()) return 16015286601757825753;
		if (chainid.isArbitrumSepolia()) return 3478487238524512106;
		if (chainid.isBaseSepolia()) return 10344971235874465080;
		if (chainid.isOptimismSepolia()) return 5224473277236331295;
		if (chainid.isAnvil()) return 0;

		revert UnknownChainConfig(chainid);
	}

	function _getCTFAdmin() internal pure returns (address ctfAdmin) {
		return 0x36591DeBffCf727D5EEA2Cb6A745ee905Fae91C8; // TODO: Replace with a multisig
	}

	function _getLockerAdmin() internal pure returns (address lockerAdmin) {
		return 0x36591DeBffCf727D5EEA2Cb6A745ee905Fae91C8; // TODO: Replace with a multisig and different address from the CTF
	}
}
