// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ICTF {
	/// @notice Mint new CTF Tokens. Only the Engine can perform this call
	/// @param mintAmount The amount of CTF Tokens to mint
	/// @param to The address of the CTF Tokens recipient
	function mint(uint256 mintAmount, address to) external;

	/// @notice get the all tokens handled by the CTF
	/// @return underlyingTokens list of the underlying tokens that the CTF handles
	function getUnderlyingTokens() external view returns (address[] memory underlyingTokens);
}
