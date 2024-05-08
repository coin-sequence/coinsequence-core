// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CSBalancerPoolManager} from "src/contracts/CSBalancerPoolManager.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract CSExecutor is CSBalancerPoolManager {
	using SafeERC20 for IERC20;
	IERC20 private immutable i_USDC;

	/// @notice emitted when USDC is swapped to Balancer Managed Pool Tokens
	event CSExecutor__USDCSwapped(address indexed swapProvider, uint256 amount);

	/// @notice thrown when the swap from USDC to balancer tokens Fails
	error CSExecutor__SwapFailed();

	/// @notice thrown when the USDC Swap amount is greater than the current balance
	error CSExecutor__SwapAmountExceedsBalance(uint256 balance, uint256 swapAmount);

	constructor(address balancerVault, address usdc) CSBalancerPoolManager(balancerVault) {
		i_USDC = IERC20(usdc);
	}

	function _swapAndDepositToBalancer(
		bytes32 poolId,
		uint256 usdcAmount,
		bytes[] memory swapsData,
		address swapProvider,
		uint256 minBPTOut
	) internal returns (uint256 bptAmountReceived) {
		IERC20 pool = IERC20(_getPoolAddress(poolId));
		uint256 bptBalancerBeforeDeposit = pool.balanceOf(address(this));

		_swapUSDCToBalancerTokens(usdcAmount, swapsData, swapProvider);
		_depositTokensToBalancer(poolId, minBPTOut);

		uint256 bptBalancerAfterDeposit = pool.balanceOf(address(this));

		return (bptBalancerAfterDeposit - bptBalancerBeforeDeposit);
	}

	function _swapUSDCToBalancerTokens(uint256 usdcAmount, bytes[] memory swapsData, address swapProvider) internal {
		uint256 swapsDataLength = swapsData.length;
		//slither-disable-next-line calls-loop
		uint256 usdcBalance = i_USDC.balanceOf(address(this));

		if (usdcAmount > usdcBalance) revert CSExecutor__SwapAmountExceedsBalance(usdcBalance, usdcAmount);
		i_USDC.forceApprove(swapProvider, usdcAmount);

		for (uint256 i = 0; i < swapsDataLength; ) {
			//slither-disable-next-line low-level-calls,calls-loop
			(bool success, ) = swapProvider.call(swapsData[i]); // solhint-disable-line avoid-low-level-calls

			if (!success) revert CSExecutor__SwapFailed();

			// We use unchecked here to save gas as its impossible to overflow.
			// we would need to have 2^256+ swaps to execute and the block gas limit will be reached for sure
			unchecked {
				++i;
			}
		}

		if (i_USDC.allowance(address(this), swapProvider) != 0) i_USDC.forceApprove(swapProvider, 0);

		emit CSExecutor__USDCSwapped(swapProvider, usdcAmount);
	}
}
