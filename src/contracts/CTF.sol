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
	uint256[] private s_chains;
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
	function addUnderlyingTokensCrossChain(
		address[] calldata underlyingTokens,
		uint256[] calldata chains
	) external onlyRole(TOKENS_MANAGER_ROLE) {
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
				//slither-disable-next-line reentrancy-eth
				_requestNewPoolCreation({
					poolName: string.concat(name(), " ", "Pool"),
					chainId: tokenChain,
					tokens: s_chainTokensToBeAdded[tokenChain]
				});

				//slither-disable-next-line costly-loop
				delete s_chainTokensToBeAdded[tokenChain];
			} else if (chainPool.status == PoolStatus.ACTIVE) {
				_requestTokenAddition({chainId: tokenChain, token: underlyingTokens[i], pool: chainPool.poolAddress});
			}

			unchecked {
				++i;
			}
		}

		emit CTF__RequestedToAddUnderlyingTokensCrossChain(underlyingTokens, chains);
	}

	function getChainUnderlyingTokens(uint256 chainId) external view returns (address[] memory) {
		return s_chainUnderlyingTokens[chainId];
	}

	function getAllUnderlyingTokens() external view returns (address[] memory underlyingTokens, uint256[] memory chains) {
		return (s_underlyingTokens, s_chains);
	}

	/**
	 * @notice add underlying tokens for the same chain as the CTF.
	 * If the pool is not created yet, it will be created.
	 *  */
	function addUnderlyingTokensSameChain(address[] calldata underlyingTokens) public onlyRole(TOKENS_MANAGER_ROLE) {
		ChainPool memory chainPool = _getPool(block.chainid);

		if (chainPool.status == PoolStatus.NOT_CREATED) {
			_requestNewPoolCreation({poolName: string.concat(name(), " ", "Pool"), chainId: block.chainid, tokens: underlyingTokens});
		} else {
			_requestBatchTokenAddition({chainId: block.chainid, tokens: underlyingTokens, pool: chainPool.poolAddress});
		}

		emit CTF__AddedUnderlyingTokensSameChain(underlyingTokens);
	}

	function _onCreatePool(uint256 chainId, address[] memory tokens) internal override {
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
