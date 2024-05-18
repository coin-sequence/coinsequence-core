// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {TokenMock} from "src/mocks/TokenMock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapProviderMock {
	function swap(address fromToken, TokenMock toToken, uint256 fromTokenAmount, uint256 toTokenAmount) external {
		IERC20(fromToken).transferFrom(msg.sender, address(this), fromTokenAmount);
		toToken.mint(msg.sender, toTokenAmount);
	}
}
