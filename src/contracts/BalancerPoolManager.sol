// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BalancerERC20Helpers} from "src/libraries/BalancerERC20Helpers.sol";
import {IERC20 as OpenZeppelinIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault, IERC20 as BalancerIERC20} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {WeightedPoolUserData} from "@balancer-labs/v2-interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";
import {IBalancerManagedPoolFactoryV2} from "src/interfaces/IBalancerManagedPoolFactoryV2.sol";
import {ProtocolFeeType} from "@balancer-labs/v2-interfaces/contracts/standalone-utils/IProtocolFeePercentagesProvider.sol"; //solhint-disable-line max-line-length
import {IManagedPool} from "@balancer-labs/v2-interfaces/contracts/pool-utils/IManagedPool.sol";

abstract contract BalancerPoolManager {
	using BalancerERC20Helpers for BalancerIERC20[];

	IVault private immutable i_vault;
	IBalancerManagedPoolFactoryV2 private immutable i_managedPoolFactory;

	/// @notice Emitted once the Tokens are successfully deposited into Balancer
	event BalancerPoolManager__Deposited(bytes32 poolId);

	/**
	 * @notice thrown when try to deposit tokens to balancer, but one of the tokens balance is zero.
	 *
	 * Can be interpreted as a failure in the swap from USDC to Pool tokens. The deposit Function
	 * should only be called after swapping the USDC to the Pool Tokens.
	 * */
	error BalancerPoolManager__PoolTokenBalanceIsZero(address token);

	/// @notice thrown when try to deposit tokens to balancer, but the minBPTOut param is zero.
	error BalancerPoolManager__MinBPTOutIsZero();

	constructor(address balancerManagedPoolFactory, address balancerVault) {
		i_vault = IVault(balancerVault);
		i_managedPoolFactory = IBalancerManagedPoolFactoryV2(balancerManagedPoolFactory);
	}

	function _createPool(
		string memory name,
		string memory symbol,
		OpenZeppelinIERC20[] memory initialTokens
	) internal returns (address poolAddress, bytes32 poolId) {
		uint256 initialTokensLength = initialTokens.length;
		address[] memory assetManagers = new address[](1);
		uint256[] memory initialNormalizedWeights = new uint256[](initialTokens.length);

		assetManagers[0] = address(this);

		for (uint256 i = 0; i < initialTokensLength; ) {
			// set equal weight for all tokens
			initialNormalizedWeights[i] = 1e18 / (initialTokensLength * 1 ** 10);

			unchecked {
				++i;
			}
		}

		IBalancerManagedPoolFactoryV2.ManagedPoolParams memory params = IBalancerManagedPoolFactoryV2.ManagedPoolParams({
			name: name,
			symbol: symbol,
			assetManagers: assetManagers
		});

		IBalancerManagedPoolFactoryV2.ManagedPoolSettingsParams memory settingsParams = IBalancerManagedPoolFactoryV2
			.ManagedPoolSettingsParams({
				tokens: initialTokens,
				normalizedWeights: initialNormalizedWeights,
				swapFeePercentage: 0,
				swapEnabledOnStart: false,
				mustAllowlistLPs: true,
				managementAumFeePercentage: 0,
				aumFeeId: ProtocolFeeType.AUM
			});

		address _poolAddress = i_managedPoolFactory.create(params, settingsParams, address(this), bytes32(0));
		IManagedPool pool = IManagedPool(_poolAddress);
		bytes32 _poolId = pool.getPoolId();

		pool.addAllowedAddress(address(this)); // TODO: Test if need to add the contract itself

		return (_poolAddress, _poolId);
	}

	//slither-disable-start calls-loop
	function _depositTokensToBalancer(bytes32 poolId, uint256 minBPTOut) internal {
		if (minBPTOut == 0) revert BalancerPoolManager__MinBPTOutIsZero();

		//slither-disable-next-line unused-return
		(BalancerIERC20[] memory poolTokens, , ) = i_vault.getPoolTokens(poolId);
		uint256 poolTokensLength = poolTokens.length;
		uint256[] memory maxAmountsIn = new uint256[](poolTokensLength);

		for (uint256 i = 0; i < poolTokensLength; ) {
			BalancerIERC20 poolToken = poolTokens[i];
			OpenZeppelinIERC20 poolTokenAsOpenZeppelinIERC20 = _covertFromBalancerIERC20ToOpenZeppelinIERC20(poolToken);

			uint256 maxAmountIn = poolToken.balanceOf(address(this));

			if (maxAmountIn < 1) revert BalancerPoolManager__PoolTokenBalanceIsZero(address(poolToken));

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
			maxAmountsIn: maxAmountsIn,
			userData: abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, minBPTOut),
			fromInternalBalance: false
		});

		i_vault.joinPool({poolId: poolId, sender: address(this), recipient: address(this), request: joinPoolRequest});

		//slither-disable-next-line reentrancy-events
		emit BalancerPoolManager__Deposited(poolId);
	}
	// slither-disable-end calls-loop

	function _getPoolAddress(bytes32 poolId) internal view returns (address) {
		(address _pool, ) = i_vault.getPool(poolId);
		return _pool;
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
