// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BalancerERC20Helpers} from "src/libraries/BalancerERC20Helpers.sol";
import {IERC20 as OpenZeppelinIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault, IERC20 as BalancerIERC20} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import {IBalancerManagedPoolFactoryV2} from "src/interfaces/IBalancerManagedPoolFactoryV2.sol";
import {ProtocolFeeType} from "@balancer-labs/v2-interfaces/contracts/standalone-utils/IProtocolFeePercentagesProvider.sol"; //solhint-disable-line max-line-length
import {IManagedPool} from "@balancer-labs/v2-interfaces/contracts/pool-utils/IManagedPool.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract BalancerPoolManager {
	using BalancerERC20Helpers for BalancerIERC20[];

	IVault private immutable i_vault;
	IBalancerManagedPoolFactoryV2 private immutable i_managedPoolFactory;
	uint256 private constant MAX_POOL_TOKENS = 50;
	uint256 private constant NORMALIZED_WEIGHT_SUM = 1e18;

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

	/// @notice thrown if at the creation of a pool or adding a token, the total number of tokens exceeds the MAX_POOL_TOKENS
	error BalancerPoolManager__ExceededMaxPoolTokens(uint256 tokens, uint256 maxTokens);

	/// @notice thrown if the token is invalid in some way, either not having code or being address 0
	error BalancerPoolManager__InvalidToken();

	constructor(address balancerManagedPoolFactory, address balancerVault) {
		i_vault = IVault(balancerVault);
		i_managedPoolFactory = IBalancerManagedPoolFactoryV2(balancerManagedPoolFactory);
	}

	function _createPool(
		string memory name,
		string memory symbol,
		OpenZeppelinIERC20[] memory initialTokens
	) internal returns (address poolAddress, bytes32 poolId) {
		if (initialTokens.length > MAX_POOL_TOKENS) revert BalancerPoolManager__ExceededMaxPoolTokens(initialTokens.length, MAX_POOL_TOKENS);

		address[] memory assetManagers = new address[](initialTokens.length);
		uint256[] memory initialNormalizedWeights;

		initialNormalizedWeights = _getTokensWeight(initialTokens.length);

		assetManagers[0] = address(this);

		IBalancerManagedPoolFactoryV2.ManagedPoolParams memory params = IBalancerManagedPoolFactoryV2.ManagedPoolParams({
			name: name,
			symbol: symbol,
			assetManagers: assetManagers
		});

		IBalancerManagedPoolFactoryV2.ManagedPoolSettingsParams memory settingsParams = IBalancerManagedPoolFactoryV2
			.ManagedPoolSettingsParams({
				tokens: initialTokens,
				normalizedWeights: initialNormalizedWeights,
				swapFeePercentage: 1e12, // 1e12 is the MIN_SWAP_FEE of Balancer
				swapEnabledOnStart: true,
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

	function _addTokenToPool(address tokenToAdd, address pool) internal {
		// if (tokenToAdd == address(0) || tokenToAdd.code.length == 0) revert BalancerPoolManager__InvalidToken();
		// IManagedPool managedPool = IManagedPool(pool);
		// uint256 poolTokensCount = managedPool.getNormalizedWeights().length;
		// uint256 newTokensWeight = _getTokenWeight(++poolTokensCount);
		// managedPool.addToken(BalancerIERC20(tokenToAdd), address(this), newTokensWeight, 0, address(0));
		// // i_vault.batchSwap(IVault.SwapKind.GIVEN_IN, swaps, assets, funds, limits, deadline);
		// i_vault.managePoolBalance(ops);
	}

	/**
	 * @notice calculate the normalized weight of the pool tokens
	 * @param tokensCount the length of the pool tokens (without decimals)
	 * @return weight the weight of each token in the pool (with balancer decimals, 1e18 for 1)
	 * @custom:warning this function does not prevent that (weight * tokensCount) is equal to 1e18
	 * If you want to ensure that the output will be exacly 1e18, use the `_getTokensWeight` function
	 *  */
	function _getTokenWeight(uint256 tokensCount) private pure returns (uint256 weight) {
		return (NORMALIZED_WEIGHT_SUM / (tokensCount * 1 ** 10));
	}

	/**
	 * @notice calculate the normalized weight of the pool tokens and return them as list
	 * @param tokensCount the length of the pool tokens (without decimals)
	 * @return weights the weight of each token in the pool (with balancer decimals, 1e18 for 1)
	 */
	function _getTokensWeight(uint256 tokensCount) private pure returns (uint256[] memory weights) {
		uint256 tokensWeightSum;

		for (uint256 i = 0; i < tokensCount; ) {
			// set equal weight for all tokens
			// 1e10 is used to equalize to 1e18 decimals after division, as Balancer requires 1e18
			uint256 tokenWeight = _getTokenWeight(tokensCount);
			weights[i] = tokenWeight;
			tokensWeightSum += tokenWeight;

			unchecked {
				++i;
			}
		}

		uint256 diffBetweenMinWeightAndWeightSum = NORMALIZED_WEIGHT_SUM - tokensWeightSum;

		// add the difference between the NORMALIZED_WEIGHT_SUM and the tokens weight sum to the first token.
		// this will ensure that the total weight of the pool is equal to NORMALIZED_WEIGHT_SUM.
		// Not being equal to NORMALIZED_WEIGHT_SUM will result in revert from balancer when creating the pool
		if (diffBetweenMinWeightAndWeightSum > 0) {
			weights[0] += diffBetweenMinWeightAndWeightSum;
		}

		assert(weights.length == tokensCount);
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
