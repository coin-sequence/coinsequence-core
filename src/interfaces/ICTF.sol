// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ICTF {
	/// @notice get the all tokens handled by the CTF
	function getUnderlyingTokens() external view returns (address[] memory);
}
