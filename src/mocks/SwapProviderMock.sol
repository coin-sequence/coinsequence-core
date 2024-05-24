// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {TokenMock} from "src/mocks/TokenMock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapProvider {
	/**
	 * @dev the @param toToken should be a mock token with a public `mint` function without restrictions
	 */
	function swapFromUSDC(address usdc, TokenMock toToken, uint256 usdcAmount, uint256 toTokenAmount) external {
		IERC20(usdc).transferFrom(msg.sender, address(this), usdcAmount);
		toToken.mint(msg.sender, toTokenAmount);
	}

	/**
	 * @dev pay attention that the @param usdcAmountToReceive should be at max the received amount when
	 * calling `swapFromUSDC`. As this function uses the usdc received from `swapFromUSDC`
	 *  */
	function swapToUSDC(address fromToken, uint256 fromTokenAmount, address usdc, uint256 usdcAmountToReceive) external {
		IERC20(fromToken).transferFrom(msg.sender, address(this), fromTokenAmount);
		IERC20(usdc).transfer(msg.sender, usdcAmountToReceive);
	}
}
