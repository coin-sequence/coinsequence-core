// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CustomCast} from "src/libraries/CustomCast.sol";

abstract contract Swap {
	using SafeERC20 for IERC20;
	using CustomCast for address[];

	/// @notice emitted when USDC is successfully swapped for the tokens
	event Swap__USDCSwapped(uint256 usdcAmount);

	/// @notice thrown when the swap fails for some reason(in the callee contract)
	error Swap__SwapFailed(bytes errorData);

	/// @notice thrown when the passed USDC address is invalid
	error Swap__InvalidUSDC(address passedUSDCAddress);

	/// @notice thrown when trying to swap more USDC than available in balance
	error Swap__InsufficientFunds(uint256 balance, uint256 amount);

	/// @notice thrown when the swap does not use all available usdc for the swaps
	error Swap__ShouldUseAllUSDC(uint256 usdcProvided, uint256 usdcUsed);

	/**
	 * @notice swap usdc for the specified tokens in the @param swapsData
	 * @param usdcAmount the total amount of usdc to swap in this call (with decimals)
	 * @param swapProvider address of the swap contract
	 * @param swapsData the calldata to be passed to the @param swapContract
	 *  */
	function _swapUSDC(IERC20 usdc, uint256 usdcAmount, address swapProvider, bytes[] memory swapsData) internal {
		if (address(usdc).code.length == 0) revert Swap__InvalidUSDC(address(usdc));

		uint256 swapsDataLength = swapsData.length;
		uint256 usdcBalanceBeforeSwap = usdc.balanceOf(address(this));

		if (usdcAmount > usdcBalanceBeforeSwap) revert Swap__InsufficientFunds(usdcBalanceBeforeSwap, usdcAmount);

		usdc.forceApprove(swapProvider, usdcAmount);

		for (uint256 i = 0; i < swapsDataLength; ) {
			//solhint-disable-next-line avoid-low-level-calls
			(bool success, bytes memory errorData) = swapProvider.call(swapsData[i]);
			if (!success) revert Swap__SwapFailed(errorData);

			unchecked {
				++i;
			}
		}

		uint256 usdcBalanceAfterSwap = usdc.balanceOf(address(this));
		uint256 usdcUsedForSwaps = usdcBalanceBeforeSwap - usdcBalanceAfterSwap;

		if (usdcAmount != usdcUsedForSwaps) revert Swap__ShouldUseAllUSDC(usdcAmount, usdcUsedForSwaps);

		// ensure that no approval is left for the swapProvider to avoid exploits from the swap provider
		if (usdc.allowance(address(this), swapProvider) != 0) usdc.forceApprove(swapProvider, 0);

		emit Swap__USDCSwapped(usdcAmount);
	}
}
