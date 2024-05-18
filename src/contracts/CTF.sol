// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {PoolManager} from "src/contracts/PoolManager.sol";
import {NetworkHelper} from "src/libraries/NetworkHelper.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CTF is PoolManager, ERC20Permit {
	using EnumerableSet for EnumerableSet.UintSet;
	using SafeERC20 for IERC20;

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
	uint256 private s_depositNounce;

	/**
	 * @notice emitted once a deposit is successfully made and CTF tokens are minted
	 * to the user
	 *  */
	event CTF__Deposited(address indexed user, uint256 amount);

	/// @notice thrown if the underlying tokens array and chains array have different lengths
	error CTF__TokensAndChainsMismatch(uint256 tokens, uint256 chains);

	/// @notice thrown when try to add a new underlying token, but the token is already added
	error CTF__TokenAlreadyAdded(address token);

	/// @notice thrown when try to add a token to a pool, but the pool is not created
	error CTF__PoolNotCreated();

	/// @notice thrown when the swap providers array and chains array have different lengths
	error CTF__SwapProvidersLengthMismatch(uint256 swapProvidersLength, uint256 chainsLength);

	/// @notice thrown when the swap calldata array and chains array have different lengths
	error CTF__SwapsCallDataLengthMismatch(uint256 swapsCalldataLength, uint256 chainsLength);

	/// @notice thrown when the min BPT out array and chains array have different lengths
	error CTF__MinBPTOutLengthMismatch(uint256 minBPTOutLength, uint256 chainsLength);

	/**
	 * @notice thrown when try to perform actions in a pool that is not in Active state
	 * e.g add new underlying tokens
	 *  */
	error Pool__NotActive(uint256 chainId);

	constructor(
		string memory ctfName,
		string memory ctfSymbol
	)
		ERC20(ctfName, ctfSymbol)
		ERC20Permit(ctfName)
		PoolManager(
			NetworkHelper._getBalancerManagedPoolFactory(),
			NetworkHelper._getBalancerVault(),
			NetworkHelper._getCCIPRouter(),
			NetworkHelper._getCTFAdmin()
		)
	{}

	/**
	 * @notice deposit into the CTF to receive CTF Tokens
	 * @param swapProviders the swap providers for each chain.
	 * @param swapsCalldata the swaps calldata for each chain.
	 * @param minBPTOut the min BPT out for each chain.
	 * @param usdcAmountPerChain the USDC Amount to send for each chain to execute the swap (with decimals)
	 * @param totalUSDCAmount the total amount of USDC that will be used for all chains (with decimals)
	 * @custom:note the @param swapProviders, @param swapsCalldata and @param minBPTOut are corretaled
	 * so they must be in the same order, as they all will be used in the same chain.
	 * Also they should have the same length as the chains that the Underlying Tokens are on
	 *  */
	function deposit(
		address[] calldata swapProviders,
		bytes[][] calldata swapsCalldata,
		uint256[] calldata minBPTOut,
		uint256[] calldata usdcAmountPerChain,
		uint256 totalUSDCAmount
	) external {
		bytes32 depositId = keccak256(abi.encodePacked(block.number, msg.sender, ++s_depositNounce));

		uint256 chainsLength = s_chainsSet.length();

		if (chainsLength != swapProviders.length) revert CTF__SwapProvidersLengthMismatch(swapProviders.length, chainsLength);
		if (chainsLength != swapsCalldata.length) revert CTF__SwapsCallDataLengthMismatch(swapsCalldata.length, chainsLength);
		if (chainsLength != minBPTOut.length) revert CTF__MinBPTOutLengthMismatch(minBPTOut.length, chainsLength);

		s_usdc.safeTransferFrom(msg.sender, address(this), totalUSDCAmount);

		for (uint256 i = 0; i < chainsLength; ) {
			uint256 chainId = s_chainsSet.at(i);
			_requestPoolDeposit(
				depositId,
				chainId,
				s_chainUnderlyingTokens[chainId],
				swapProviders[i],
				swapsCalldata[i],
				minBPTOut[i],
				usdcAmountPerChain[i]
			);

			unchecked {
				++i;
			}
		}
	}

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
			ChainPool memory chainPool = getChainPool(tokenChain);
			address[] memory chainTokensToBeAdded = s_chainTokensToBeAdded[tokenChain];
			uint256 chainTokensToBeAddedLength = chainTokensToBeAdded.length;

			// we assume that if the length is 0, the tokens have been added already
			// so we don't procceed, to save gas
			if (chainTokensToBeAddedLength == 0) {
				unchecked {
					++i;
				}

				continue;
			}

			if (chainPool.status == PoolStatus.NOT_CREATED) {
				//slither-disable-next-line reentrancy-eth
				_requestNewPoolCreation({poolName: string.concat(name(), " ", "Pool"), chainId: tokenChain, tokens: chainTokensToBeAdded});

				//slither-disable-next-line costly-loop
			} else if (chainPool.status == PoolStatus.ACTIVE) {
				chainTokensToBeAddedLength > 1
					? _requestBatchTokenAddition({chainId: tokenChain, tokens: chainTokensToBeAdded, pool: chainPool.poolAddress})
					: _requestTokenAddition({chainId: tokenChain, token: underlyingTokens[i], pool: chainPool.poolAddress});
			} else {
				revert Pool__NotActive(tokenChain);
			}

			delete s_chainTokensToBeAdded[tokenChain];

			unchecked {
				++i;
			}
		}
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
		ChainPool memory chainPool = getChainPool(block.chainid);

		if (chainPool.status == PoolStatus.NOT_CREATED) {
			_requestNewPoolCreation({poolName: string.concat(name(), " ", "Pool"), chainId: block.chainid, tokens: underlyingTokens});
		} else if (chainPool.status == PoolStatus.ACTIVE) {
			_requestBatchTokenAddition({chainId: block.chainid, tokens: underlyingTokens, pool: chainPool.poolAddress});
		} else {
			revert Pool__NotActive(block.chainid);
		}
	}

	function _onCreatePool(uint256 chainId, address[] memory tokens) internal override {
		uint256 tokensLength = tokens.length;

		for (uint256 i = 0; i < tokensLength; ) {
			s_chainUnderlyingTokens[chainId].push(tokens[i]);
			s_underlyingTokens.push(tokens[i]);
			s_chains.push(chainId);

			unchecked {
				++i;
			}
		}
	}

	function _onDeposit(address user, uint256 totalBPTReceived) internal virtual override {
		_mint(user, totalBPTReceived);

		emit CTF__Deposited(user, totalBPTReceived);
	}
}
