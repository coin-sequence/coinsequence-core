// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ICTF {
	/// @param poolId the balancer pool id for the given network
	/// @param pool the balancer pool address for the given network
	/// @param chainSelector the CCIP chain selector for the given network
	struct NetworkInfo {
		bytes32 poolId;
		address pool;
		uint64 chainSelector;
	}

	/**
	 * @notice mint CTF Tokens to the user immediaely if the CTF is not Cross-Chain.
	 * In the case of the CTF Being Cross-Chain, the CTF will wait for all the chains confirmation
	 * Before releasing the tokens for the user
	 * @param to the address to mint to
	 * @param amount the amount to mint(with decimals)
	 *  */
	function mint(address to, uint256 amount) external;

	/// @notice get the balancer pool id for a given chain
	/// @param chainId the id of the chain to get the info
	/// @return networkInfo the network info for the given chain
	function getNetworkInfo(uint256 chainId) external view returns (NetworkInfo memory networkInfo);

	/**
	 * @notice get the list of chain ids for the CTF underlying tokens
	 *
	 * e.g: Let's say we have 3 Underlying Tokens, 2 on OP and the other on Polygon
	 * this will return 2 chain ids, 1 for OP and 1 for Polygon, as all tokens are
	 * distributed in 2 chains
	 * */
	function underlyingTokensChains() external view returns (uint256[] memory);
}
