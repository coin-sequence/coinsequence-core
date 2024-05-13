// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ICTF {
	/// @notice emitted when Cross-Chain underlying tokens are added to the CTF
	event CTF__RequestedToAddUnderlyingTokensCrossChain(address[] tokens, uint256[] chains);

	/// @notice emitted when Same-Chain underlying tokens are added to the CTF
	event CTF__AddedUnderlyingTokensSameChain(address[] tokens);

	/// @notice thrown if the underlying tokens array and chains array have different lengths
	error CTF__TokensAndChainsMismatch(uint256 tokens, uint256 chains);

	/// @notice thrown when try to add a new underlying token, but the token is already added
	error CTF__TokenAlreadyAdded(address token);

	/// @notice thrown when try to add a token to a pool, but the pool is not created
	error CTF_PoolNotCreated();
}
