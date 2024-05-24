// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BalancerERC20Helpers} from "src/libraries/BalancerERC20Helpers.sol";
import {IERC20 as OpenZeppelinIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVault, IERC20 as BalancerIERC20} from "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBalancerManagedPoolFactoryV2} from "src/interfaces/IBalancerManagedPoolFactoryV2.sol";
import {ProtocolFeeType} from "@balancer-labs/v2-interfaces/contracts/standalone-utils/IProtocolFeePercentagesProvider.sol"; //solhint-disable-line max-line-length
import {IManagedPool} from "@balancer-labs/v2-interfaces/contracts/pool-utils/IManagedPool.sol";
import {Arrays} from "src/libraries/Arrays.sol";
import {IBalancerQueries} from "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerQueries.sol";

abstract contract BalancerPoolManager {
	using BalancerERC20Helpers for BalancerIERC20[];
	using Arrays for uint256[];
	using SafeERC20 for OpenZeppelinIERC20;

	enum JoinPoolKind {
		INIT,
		EXACT_TOKENS_IN_FOR_BPT_OUT,
		TOKEN_IN_FOR_EXACT_BPT_OUT,
		ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
	}

	enum ExitPoolKind {
		EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
		EXACT_BPT_IN_FOR_TOKENS_OUT,
		BPT_IN_FOR_EXACT_TOKENS_OUT
	}

	IVault private immutable i_vault;
	IBalancerManagedPoolFactoryV2 private immutable i_managedPoolFactory;
	IBalancerQueries private immutable i_queries;
	uint256 private constant MAX_POOL_TOKENS = 50;
	uint256 private constant NORMALIZED_WEIGHT_SUM = 1e18; // all tokens weight summed should be equal to 1e18

	/// @notice thrown if at the creation of a pool or adding a token, the total number of tokens exceeds the MAX_POOL_TOKENS
	error BalancerPoolManager__ExceededMaxPoolTokens(uint256 tokens, uint256 maxTokens);

	/// @notice thrown if the join kind is `INIT` and the number of join assets is not equal to the number of tokens in the pool
	error BalancerPoolManager__JoinAssetsCountMismatch(uint256 joinAssetsCount, uint256 assetsCount);

	/// @notice thrown if the contract have not received the BPT after joining the pool
	error BalancerPoolManager__BPTNotReceived();

	constructor(address balancerManagedPoolFactory, address balancerVault) {
		i_vault = IVault(balancerVault);
		i_managedPoolFactory = IBalancerManagedPoolFactoryV2(balancerManagedPoolFactory);
	}

	function getExitPoolData(
		bytes32 poolId,
		uint256 exitTokenIndex,
		uint256 bptAmountIn,
		uint256 minAmountOut
	) public view returns (IVault.ExitPoolRequest memory exitPoolRequest, OpenZeppelinIERC20 exitToken) {
		(BalancerIERC20[] memory poolTokens, , ) = i_vault.getPoolTokens(poolId);
		exitToken = OpenZeppelinIERC20(address(poolTokens[exitTokenIndex + 1])); // we use +1 to skip the BPT token

		uint256[] memory minAmountsOut = new uint256[](poolTokens.length);
		minAmountsOut[exitTokenIndex] = minAmountOut;

		exitPoolRequest = IVault.ExitPoolRequest({
			assets: poolTokens.asIAsset(),
			minAmountsOut: minAmountsOut,
			userData: abi.encode(ExitPoolKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, bptAmountIn, exitTokenIndex),
			toInternalBalance: false
		});
	}

	function _createPool(
		string memory name,
		string memory symbol,
		OpenZeppelinIERC20[] memory initialTokens
	) internal returns (address poolAddress, bytes32 poolId, uint256[] memory weights) {
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

		pool.addAllowedAddress(address(this));

		return (_poolAddress, _poolId, initialNormalizedWeights);
	}

	function _joinPool(bytes32 poolId, uint256 minBPTOut) internal returns (uint256 bptAmountReceived) {
		(address poolAddress, ) = i_vault.getPool(poolId);
		uint256 bptAmountBeforeJoin = BalancerIERC20(poolAddress).balanceOf(address(this));
		(BalancerIERC20[] memory poolTokens, uint256[] memory balances, ) = i_vault.getPoolTokens(poolId);
		uint256 poolTokensCountWithBPT = poolTokens.length;
		uint256[] memory maxAmountsInWithBPT = new uint256[](poolTokens.length);
		uint256[] memory amountsInWithoutBPT = new uint256[](poolTokens.length - 1); // -1 to remove the BPT token from the count
		JoinPoolKind joinKind = balances.sum() > 0 ? JoinPoolKind.EXACT_TOKENS_IN_FOR_BPT_OUT : JoinPoolKind.INIT;

		uint256 bptIndexOffset = 0;
		for (uint256 i; i < poolTokensCountWithBPT; ) {
			if (address(poolTokens[i]) == poolAddress) {
				unchecked {
					bptIndexOffset = 1;
					if (joinKind == JoinPoolKind.INIT) maxAmountsInWithBPT[i] = type(uint256).max;
					++i;
				}

				continue;
			}

			uint256 tokenBalance = poolTokens[i].balanceOf(address(this));

			maxAmountsInWithBPT[i] = tokenBalance;
			amountsInWithoutBPT[i - bptIndexOffset] = tokenBalance;
			OpenZeppelinIERC20(address(poolTokens[i])).forceApprove(address(i_vault), tokenBalance);

			unchecked {
				++i;
			}
		}

		bytes memory userData = abi.encode(joinKind, amountsInWithoutBPT, minBPTOut);

		IVault.JoinPoolRequest memory joinPoolRequest = IVault.JoinPoolRequest(poolTokens.asIAsset(), maxAmountsInWithBPT, userData, false);
		i_vault.joinPool(poolId, address(this), address(this), joinPoolRequest);

		uint256 bptAmountAfterJoin = BalancerIERC20(poolAddress).balanceOf(address(this));

		bptAmountReceived = (bptAmountAfterJoin - bptAmountBeforeJoin);
	}

	function _exitPool(
		bytes32 poolId,
		uint256 bptAmountIn,
		uint256 minAmountOut,
		uint256 exitTokenIndex
	) internal returns (uint256 exitTokenAmountReceived, OpenZeppelinIERC20 exitToken) {
		(address poolAddress, ) = i_vault.getPool(poolId);

		(IVault.ExitPoolRequest memory request, OpenZeppelinIERC20 _exitToken) = getExitPoolData(
			poolId,
			exitTokenIndex,
			bptAmountIn,
			minAmountOut
		);

		OpenZeppelinIERC20(poolAddress).forceApprove(address(i_vault), bptAmountIn);

		uint256 exitTokenBalanceBeforeExit = _exitToken.balanceOf(address(this));
		i_vault.exitPool(poolId, address(this), payable(address(this)), request);
		uint256 exitTokenBalanceAfterExit = _exitToken.balanceOf(address(this));

		exitTokenAmountReceived = (exitTokenBalanceAfterExit - exitTokenBalanceBeforeExit);

		return (exitTokenAmountReceived, _exitToken);
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
		uint256[] memory tokensWeights = new uint256[](tokensCount);
		uint256 tokensWeightSum;

		for (uint256 i = 0; i < tokensCount; ) {
			// set equal weight for all tokens
			// 1e10 is used to equalize to 1e18 decimals after division, as Balancer requires 1e18
			uint256 tokenWeight = _getTokenWeight(tokensCount);
			tokensWeights[i] = tokenWeight;
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
			tokensWeights[0] += diffBetweenMinWeightAndWeightSum;
		}

		assert(tokensWeights.length == tokensCount);

		return tokensWeights;
	}
}
