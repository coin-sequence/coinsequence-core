// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeChainId} from "src/libraries/SafeChainId.sol";

library NetworkHelper {
	using SafeChainId for uint256;
	struct NetworkConfig {
		uint256 chainId;
		address functionsRouter;
		uint32 functionsSubscriptionId;
		uint32 functionsCallbackGasLimit;
		bytes32 functionsDonId;
	}

	/// @notice thrown when the current block.chainid config is not defined yet
	error UnknownChainConfig(uint256 chainId);

	function getNetworkConfig() internal view returns (NetworkConfig memory) {
		return
			NetworkConfig(
				block.chainid,
				_getFunctionsRouter(),
				_getFunctionsSubscriptionId(),
				_getFunctionsCallbackLimit(),
				_getFunctionsDonId()
			);
	}

	function _getFunctionsRouter() private view returns (address functionsRouter) {
		if (block.chainid.isSepolia()) return 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
		if (block.chainid.isAnvil()) return address(0);

		revert UnknownChainConfig(block.chainid);
	}

	function _getFunctionsSubscriptionId() private view returns (uint32 functionsSubscriptionId) {
		if (block.chainid.isSepolia()) return 2413;
		if (block.chainid.isAnvil()) return 0;

		revert UnknownChainConfig(block.chainid);
	}

	function _getFunctionsCallbackLimit() private view returns (uint32 functionsCallbackGasLimit) {
		if (block.chainid.isSepolia()) return 200_000;
		if (block.chainid.isAnvil()) return 200_000;

		revert UnknownChainConfig(block.chainid);
	}

	function _getFunctionsDonId() private view returns (bytes32 functionsDonId) {
		if (block.chainid.isSepolia()) return "fun-ethereum-sepolia-1";
		if (block.chainid.isAnvil()) return "fun-anvil-foundry-1";

		revert UnknownChainConfig(block.chainid);
	}
}
