// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CSDeposit} from "src/types/CSDeposit.sol";
import {ICTF} from "src/interfaces/ICTF.sol";

interface ICSEngine {
	/// @notice thrown when the swap from USDC to balancer tokens Fails
	error CSEngine__SwapFailed();

	/// @notice thrown when the USDC Swap amount is greater than the current balance
	error CSEngine__SwapAmountExceedsBalance();

	/**
	 * @notice deposit funds into the CTF and Receive CTF Tokens
	 *
	 * @param deposits list of deposit data for tokens in different networks.
	 * If the CTF Only handle tokens from the same network, the list will have a single item.
	 *
	 * e.g: the CTF Handles 1 token on OP ans 2 Tokens on Polygon. The list should have 2 items
	 * e.g-2: The CTF Handles 4 tokens on OP, the list should have 1 item
	 *
	 * @param totalUSDCAmount the total amount of USDC to deposit across all networks.
	 *
	 * @dev this function assumes that the pool on balancer for each network exists.
	 *  */
	function deposit(uint256 totalUSDCAmount, ICTF ctf, CSDeposit[] calldata deposits) external;

	function withdraw() external;
}
