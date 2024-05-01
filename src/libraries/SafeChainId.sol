// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// solhint-disable chainlink-solidity/prefix-internal-functions-with-underscore
library SafeChainId {
	uint256 internal constant SEPOLIA_ID = 11155111;
	uint256 internal constant ANVIL_ID = 31337;

	function isSepolia(uint256 chainId) internal pure returns (bool) {
		return chainId == SEPOLIA_ID;
	}

	function isAnvil(uint256 chainId) internal pure returns (bool) {
		return chainId == ANVIL_ID;
	}
}
