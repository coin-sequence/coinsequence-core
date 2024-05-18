// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILocker {
	event Locker__LockedUSDC(address indexed user, uint256 amount);

	/**
	 * @notice thrown when the user is not authorized to perform the withdraw
	 *  */
	error Locker__Unauthorized();

	/**
	 * @notice lock USDC in this contract in case of an emergency
	 * Like a failure to deposit cross chain
	 * @param user address of the user that sent the USDC
	 * @param amount the amount of USDC to lock
	 *  */
	function lockUSDC(IERC20 usdc, address user, uint256 amount) external;

	/**
	 * @notice withdraw locked funds. Only the user that deposited
	 * or the Admin can perform this action
	 *
	 * @param user address of the user to withdraw
	 */
	function withdrawUSDC(IERC20 usdc, address user) external;
}
