// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICSEngine, CSDeposit, ICTF} from "src/interfaces/ICSEngine.sol";
import {SafeChain} from "src/libraries/SafeChain.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CSBalancerPoolManager} from "src/contracts/CSBalancerPoolManager.sol";

contract CSEngine is CSBalancerPoolManager, ICSEngine {
	using SafeChain for uint256;
	using SafeERC20 for IERC20;

	IERC20 private immutable i_usdc;

	constructor(address usdc, address balancerVault) CSBalancerPoolManager(balancerVault) {
		i_usdc = IERC20(usdc);
	}

	/// @inheritdoc ICSEngine
	function deposit(uint256 totalUSDCAmount, ICTF ctf, CSDeposit[] calldata deposits) external override {
		i_usdc.safeTransferFrom(msg.sender, address(this), totalUSDCAmount);
		uint256 depositsLength = deposits.length;

		for (uint256 i = 0; i < depositsLength; ) {
			CSDeposit calldata networkDeposit = deposits[i];

			if (networkDeposit.chainId.isCurrent()) {
				_swapUSDCToBalancerTokens(networkDeposit.usdcAmount, networkDeposit.swapsData, networkDeposit.swapProvider);
				_depositTokensToBalancer(ctf);
			}

			// We use unchecked here to save gas as its impossible to overflow.
			// Each item of the array is one network, no way to have 2^256+ networks :)
			unchecked {
				++i;
			}
		}
	}

	function withdraw() external override {}

	function _swapUSDCToBalancerTokens(uint256 usdcAmount, bytes[] calldata swapsData, address swapProvider) private {
		uint256 swapsDataLength = swapsData.length;

		if (usdcAmount > i_usdc.balanceOf(address(this))) revert CSEngine__SwapAmountExceedsBalance();
		i_usdc.forceApprove(swapProvider, usdcAmount);

		for (uint256 i = 0; i < swapsDataLength; ) {
			(bool success, ) = swapProvider.call(swapsData[i]); // solhint-disable-line avoid-low-level-calls

			if (!success) revert CSEngine__SwapFailed();

			// We use unchecked here to save gas as its impossible to overflow.
			// we would need to have 2^256+ swaps to execute and the block gas limit will be reached for sure
			unchecked {
				++i;
			}
		}
	}
}
