// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICTF} from "src/interfaces/ICTF.sol";
import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {PoolManager} from "src/contracts/PoolManager.sol";

contract CTF is ICTF, PoolManager, ERC20Permit {
	using EnumerableSet for EnumerableSet.UintSet;
	using EnumerableSet for EnumerableSet.AddressSet;

	mapping(uint256 chainId => address[] tokens) private s_chainUnderlyingTokens;

	/**
	 * @dev we use this temporary mapping to store the tokens that we want to add
	 * before adding to the real list. This is done because we can't have mapping
	 * in the memory storage :(
	 *
	 * This mapping values should be cleared after every use. Because after we just
	 * move the tokens from this mapping to the real one `s_chainUnderlyingTokens`,
	 * Not clearing it will lead to adding wrong tokens to `s_chainUnderlyingTokens`
	 * and the CTF will be broken
	 *  */
	mapping(uint256 chainId => address[] tokens) private s_chainTokensToBeAdded;

	address[] private s_underlyingTokens;
	uint256[] private s_chains; // TODO: Check if need to be a state variable
	EnumerableSet.UintSet private s_chainsSet;

	constructor(
		string memory ctfName,
		string memory ctfSymbol,
		address admin,
		address balancerVault,
		address balancerManagedPoolFactory,
		address ccipRouterClient
	) ERC20(ctfName, ctfSymbol) ERC20Permit(ctfName) PoolManager(balancerManagedPoolFactory, balancerVault, ccipRouterClient, admin) {}

	/**
	 * @notice Add Cross-Chain underlying tokens to the CTF.
	 *
	 * @dev the @param underlyingTokens and @param chains must have the same length.
	 * These arrays are corretaled, so they must be in the same order also.
	 *
	 * e.g: 3 tokens from 3 different chains, the @param underlyingTokens should be:
	 * [token1, token2, token3] and the @param chains should be [token1ChainId, token2ChainId, token3ChainId].
	 *
	 * Not following this rule, will cause the contract to crash, and the CTF will not work as expected.
	 *
	 * @custom:note If the pool for the given chain is not created yet, it will be created.
	 *  */
	function addUnderlyingTokensCrossChain(address[] calldata underlyingTokens, uint256[] calldata chains) external onlyOwner {
		uint256 underlyingTokensLength = underlyingTokens.length;

		if (chains.length != underlyingTokensLength) {
			revert CTF__TokensAndChainsMismatch(underlyingTokens.length, chains.length);
		}

		for (uint256 i = 0; i < underlyingTokensLength; ) {
			uint256 tokenChain = chains[i];

			s_chainTokensToBeAdded[tokenChain].push(underlyingTokens[i]);

			unchecked {
				++i;
			}
		}

		// create the pool if it does not exist yet or add the token if it already exists
		for (uint256 i = 0; i < underlyingTokensLength; ) {
			uint256 tokenChain = chains[i];
			ChainPool memory chainPool = _getPool(tokenChain);

			if (chainPool.status == PoolStatus.NOT_CREATED) {
				_requestNewPoolCreation({
					poolName: string.concat(name(), " ", "Pool"),
					chainId: tokenChain,
					tokens: s_chainTokensToBeAdded[tokenChain]
				});

				delete s_chainTokensToBeAdded[tokenChain];
			} else if (chainPool.status == PoolStatus.ACTIVE) {
				_requestTokenAddition({chainId: tokenChain, token: underlyingTokens[i], pool: chainPool.poolAddress});
			}

			unchecked {
				++i;
			}
		}

		emit RequestedToAddUnderlyingTokensCrossChain(underlyingTokens, chains);
	}

	/**
	 * @notice add underlying tokens for the same chain as the CTF.
	 * If the pool is not created yet, it will be created.
	 *
	 *
	 * @dev we use `s_chainUnderlyingTokens` here instead of `s_chainTokensToBeAdded`
	 * because as this transaction is on the same chain, if any error occur,
	 * it will just revert this whole transaction, different from the
	 * `addUnderlyingTokensCrossChain` function, where the error can occur in another chain
	 * and the transaction here have been completed already.
	 *
	 * Using `s_chainUnderlyingTokens` directly will save us some gas.
	 *  */
	function addUnderlyingTokensSameChain(address[] calldata underlyingTokens) external onlyOwner {
		ChainPool memory chainPool = _getPool(block.chainid);
		uint256 underlyingTokensLength = underlyingTokens.length;

		for (uint256 i = 0; i < underlyingTokensLength; ) {
			s_chainUnderlyingTokens[block.chainid].push(underlyingTokens[i]);
			s_underlyingTokens.push(underlyingTokens[i]);

			unchecked {
				++i;
			}
		}

		if (chainPool.status == PoolStatus.NOT_CREATED) {
			_requestNewPoolCreation({poolName: string.concat(name(), " ", "Pool"), chainId: block.chainid, tokens: underlyingTokens});
		} else {
			_requestBatchTokenAddition({chainId: block.chainid, tokens: underlyingTokens, pool: chainPool.poolAddress});
		}

		emit AddedUnderlyingTokensSameChain(underlyingTokens);
	}

	function onCreatePool(uint256 chainId, address[] memory tokens) internal override {
		uint256 tokensLength = tokens.length;

		for (uint256 i = 0; i < tokensLength; ) {
			s_chainUnderlyingTokens[chainId].push(tokens[i]);
			s_underlyingTokens.push(tokens[i]);
			s_chains.push(chainId);
			s_chainsSet.add(chainId);

			unchecked {
				++i;
			}
		}
	}
}
