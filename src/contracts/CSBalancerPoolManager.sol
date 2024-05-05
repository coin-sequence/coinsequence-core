// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IVault, IERC20 as BalancerIERC20} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import {IERC20 as OpenZeppelinIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICTF} from "src/interfaces/ICTF.sol";
import {BalancerERC20Helpers} from "src/libraries/BalancerERC20Helpers.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract CSBalancerPoolManager {
	using BalancerERC20Helpers for BalancerIERC20[];

	IVault private immutable i_vault;

	/**
	 * @notice thrown when try to deposit tokens to balancer, but one of the tokens balance is zero.
	 *
	 * Can be interpreted as a failure in the swap from USDC to Pool tokens. The deposit Function
	 * should only be called after swapping the USDC to the Pool Tokens.
	 * */
	error CSBalancerPoolManager__PoolTokenBalanceIsZero(address token);

	constructor(address balancerVault) {
		i_vault = IVault(balancerVault);
	}

	/// @notice deposit pool tokens into balancer
	function _depositTokensToBalancer(ICTF ctf) internal {
		bytes32 poolId = ctf.getPoolId();

		(BalancerIERC20[] memory poolTokens, , ) = i_vault.getPoolTokens(poolId);
		uint256 poolTokensLength = poolTokens.length;
		uint256[] memory maxAmountsIn = new uint256[](poolTokens.length);

		for (uint256 i = 0; i < poolTokensLength; ) {
			BalancerIERC20 poolToken = poolTokens[i];
			OpenZeppelinIERC20 poolTokenAsOpenZeppelinIERC20 = _covertFromBalancerIERC20ToOpenZeppelinIERC20(poolToken);
			uint256 maxAmountIn = poolToken.balanceOf(address(this));

			if (maxAmountIn == 0) revert CSBalancerPoolManager__PoolTokenBalanceIsZero(address(poolToken));

			maxAmountsIn[i] = maxAmountIn;
			SafeERC20.forceApprove(poolTokenAsOpenZeppelinIERC20, address(i_vault), maxAmountIn);

			// We use uncheched here to save gas,
			// as it's not possible to have 2^256+ tokens (Balancer max pool tokens is 50)
			unchecked {
				++i;
			}
		}

		IVault.JoinPoolRequest memory joinPoolRequest = IVault.JoinPoolRequest({
			assets: poolTokens.asIAsset(),
			maxAmountsIn: maxAmountsIn
			// userData: abi.encodePacked(""),
			// fromInternalBalance: false
		});

		i_vault.joinPool({poolId: poolId, sender: address(this), recipient: address(this), request: joinPoolRequest});
	}

	function _covertFromBalancerIERC20ToOpenZeppelinIERC20(
		BalancerIERC20 balancerIERC20
	) private pure returns (OpenZeppelinIERC20 openzeppelinIERC20) {
		// solhint-disable-next-line no-inline-assembly
		assembly {
			openzeppelinIERC20 := balancerIERC20
		}
	}
}
