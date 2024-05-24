// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CustomCast} from "src/libraries/CustomCast.sol";

abstract contract Swap {
	using SafeERC20 for IERC20;
	using CustomCast for address[];

	/// @notice emitted when the Token is successfully swapped
	event Swap__TokensSwapped(uint256 amount, address token);

	/// @notice thrown when the swap fails for some reason(in the callee contract)
	error Swap__SwapFailed(bytes errorData);

	/// @notice thrown when the passed Token address is invalid
	error Swap__InvalidToken(address passedAddress);

	/// @notice thrown when trying to swap more Tokens than available in balance
	error Swap__InsufficientFunds(uint256 balance, uint256 amount);

	/// @notice thrown when the swap does not use all available tokens for the swaps
	error Swap__ShouldUseAllTokens(uint256 providedAmount, uint256 usedAmount);

	/**
	 * @notice thrown when the USDC Balance is not greater than it was before the swap
	 * it means that the swap provider with the passed calldata didn't gave us USDC back
	 *  */
	error Swap__USDCAmountShouldIncrease(uint256 amountBeforeSwap, uint256 amountAfterSwap);

	function _swap(IERC20 from, uint256 amount, address swapProvider, bytes[] memory swapsData) internal {
		if (address(from).code.length == 0) revert Swap__InvalidToken(address(from));

		uint256 swapsDataLength = swapsData.length;
		uint256 tokenBalanceBeforeSwap = from.balanceOf(address(this));

		if (amount > tokenBalanceBeforeSwap) revert Swap__InsufficientFunds(tokenBalanceBeforeSwap, amount);

		from.forceApprove(swapProvider, amount);

		for (uint256 i = 0; i < swapsDataLength; ) {
			//solhint-disable-next-line avoid-low-level-calls
			(bool success, bytes memory errorData) = swapProvider.call(swapsData[i]);
			if (!success) revert Swap__SwapFailed(errorData);

			unchecked {
				++i;
			}
		}

		// ensure that no approval is left for the swapProvider to avoid exploits from the swap provider
		if (from.allowance(address(this), swapProvider) != 0) from.forceApprove(swapProvider, 0);

		emit Swap__TokensSwapped(amount, address(from));
	}

	function _swapUSDCOut(
		IERC20 from,
		IERC20 usdc,
		uint256 amount,
		address swapProvider,
		bytes[] memory swapsData
	) internal returns (uint256 usdcReceived) {
		uint256 usdcBalanceBeforeSwap = usdc.balanceOf(address(this));
		_swap(from, amount, swapProvider, swapsData);
		uint256 usdcBalanceAfterSwap = usdc.balanceOf(address(this));

		if (usdcBalanceAfterSwap <= usdcBalanceBeforeSwap) revert Swap__USDCAmountShouldIncrease(usdcBalanceBeforeSwap, usdcBalanceAfterSwap);

		return (usdcBalanceAfterSwap - usdcBalanceBeforeSwap);
	}
}
