// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ILocker} from "src/interfaces/ILocker.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev contract used to lock failed operations tokens
 * to make possible the recover of the funds and send back
 * to the users
 */
contract Locker is ILocker, Ownable2Step {
	using SafeERC20 for IERC20;

	mapping(address user => uint256 lockedUSDCAmount) public s_lockedUSDC;
	address private immutable i_poolManager;

	modifier onlyAuthorized(address user) {
		if (msg.sender != owner() || msg.sender != user) revert Locker__Unauthorized();
		_;
	}

	modifier onlyPoolManager() {
		if (msg.sender != i_poolManager) revert Locker__Unauthorized();
		_;
	}

	constructor(address admin, address poolManager) Ownable(admin) {
		i_poolManager = poolManager;
	}

	/// @inheritdoc ILocker
	function lockUSDC(IERC20 usdc, address user, uint256 amount) external override onlyPoolManager {
		usdc.safeTransferFrom(msg.sender, address(this), amount);

		s_lockedUSDC[user] += amount;

		emit Locker__LockedUSDC(user, amount);
	}

	/// @inheritdoc ILocker
	function withdrawUSDC(IERC20 usdc, address user) external override onlyAuthorized(user) {
		s_lockedUSDC[user] = 0;

		usdc.safeTransfer(msg.sender, s_lockedUSDC[user]);
	}
}
