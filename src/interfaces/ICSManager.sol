// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ICSManager {
	/// @notice Verify if the given CTF is created by Coin Sequence.
	/// @param ctf the Address of the CTF to be verified.
	/// @return isLegit true if the CTF is created by Coin Sequence, false otherwise.
	function isCTFLegit(address ctf) external view returns (bool isLegit);
}
