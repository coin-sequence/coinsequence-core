// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// solhint-disable chainlink-solidity/prefix-internal-functions-with-underscore
library SafeChain {
	uint256 internal constant SEPOLIA_ID = 11155111;
	uint256 internal constant ARBITRUM_SEPOLIA_ID = 421614;
	uint256 internal constant BASE_SEPOLIA_ID = 84532;
	uint256 internal constant OPTIMISM_SEPOLIA_ID = 11155420;
	uint256 internal constant ANVIL_ID = 31337;

	function isCurrent(uint256 chainId) internal view returns (bool) {
		return chainId == block.chainid;
	}

	function isSepolia(uint256 chainId) internal pure returns (bool) {
		return chainId == SEPOLIA_ID;
	}

	function isArbitrumSepolia(uint256 chainId) internal pure returns (bool) {
		return chainId == ARBITRUM_SEPOLIA_ID;
	}

	function isBaseSepolia(uint256 chainId) internal pure returns (bool) {
		return chainId == BASE_SEPOLIA_ID;
	}

	function isOptimismSepolia(uint256 chainId) internal pure returns (bool) {
		return chainId == OPTIMISM_SEPOLIA_ID;
	}

	function isAnvil(uint256 chainId) internal pure returns (bool) {
		return chainId == ANVIL_ID;
	}
}
