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

	/// @dev nonce used to generate withdraw and deposit ids
	uint256 private s_nonce;

	/**
	 * @notice emitted once a deposit is successfully made and CTF tokens are minted
	 * to the user
	 *  */
	event CTF__Deposited(address indexed user, uint256 amount);

	/// @notice emitted once a withdraw is successfully made and CTF tokens are burned
	event CTF__Withdrawn(address indexed user, uint256 ctfAmountBurned, uint256 usdcAmountWithdrawn);

	/// @notice thrown if the underlying tokens array and chains array have different lengths
	error CTF__TokensAndChainsMismatch(uint256 tokens, uint256 chains);

	/// @notice thrown when the swap providers array and chains array have different lengths
	error CTF__SwapProvidersLengthMismatch(uint256 swapProvidersLength, uint256 chainsLength);

	/// @notice thrown when the swap calldata array and chains array have different lengths
	error CTF__SwapsCallDataLengthMismatch(uint256 swapsCalldataLength, uint256 chainsLength);

	/// @notice thrown when the min BPT out array and chains array have different lengths
	error CTF__MinBPTOutLengthMismatch(uint256 minBPTOutLength, uint256 chainsLength);

	/// @notice thrown when the min exit token out array and chains array have different lengths
	error CTF__MinExitTokenOutLengthMismatch(uint256 minExitTokenOutLength, uint256 chainsLength);

	/// @notice thrown when the exit token index array and chains array have different lengths
	error CTF__ExitTokenIndexLengthMismatch(uint256 exitTokenIndexLength, uint256 chainsLength);

	/**
	 * @notice thrown when trying to perform actions in a pool that is not in Active state
	 * e.g add new underlying tokens
	 *  */
	error Pool__NotActive(uint256 chainId);

	constructor(
		string memory ctfName,
		string memory ctfSymbol,
		address admin
	)
		ERC20(ctfName, ctfSymbol)
		ERC20Permit(ctfName)
		PoolManager(NetworkHelper._getBalancerManagedPoolFactory(), NetworkHelper._getBalancerVault(), NetworkHelper._getCCIPRouter(), admin)
	{}

	/**
	 * @notice deposit into the CTF to receive CTF Tokens
	 * @param swapProviders the swap contract for each chain to be used for swapping the USDC for the pool tokens.
	 * @param swapsCalldata the swaps calldata for each chain to be passed to the swap contract.
	 * @param minBPTOut the min BPT out for each chain given the in token amount for each chain.
	 * @param usdcAmountPerChain the USDC Amount to send for each chain to execute the swap (with decimals)
	 * @custom:note the @param swapProviders, @param swapsCalldata and @param minBPTOut are corretaled
	 * so they must be in the same order, as they all will be used in the same chain.
	 * Also they should have the same length as the chains array, and also the same order as the chains array
	 *  */
	function deposit(
		address[] calldata swapProviders,
		bytes[][] calldata swapsCalldata,
		uint256[] calldata minBPTOut,
		uint256 usdcAmountPerChain
	) external {
		bytes32 depositId = keccak256(abi.encodePacked(block.number, msg.sender, ++s_nonce));
		uint256 chains = s_chainsSet.length();

		if (chains != swapProviders.length) revert CTF__SwapProvidersLengthMismatch(swapProviders.length, chains);
		if (chains != swapsCalldata.length) revert CTF__SwapsCallDataLengthMismatch(swapsCalldata.length, chains);
		if (chains != minBPTOut.length) revert CTF__MinBPTOutLengthMismatch(minBPTOut.length, chains);

		i_usdc.safeTransfer(address(this), usdcAmountPerChain * chains);

		for (uint256 i = 0; i < chains; ) {
			uint256 chainId = s_chainsSet.at(i);
			_requestPoolDeposit(depositId, chainId, swapProviders[i], swapsCalldata[i], minBPTOut[i], usdcAmountPerChain);

			unchecked {
				++i;
			}
		}
	}

	/**
	 * @notice withdraw from the CTF and received USDC back
	 * @param bptAmountPerChain the total ctf amount to withdraw divided by the number of chains
	 * @param exitTokenIndex the index of the token that will be removed in the balancer pool for each chain
	 * @param exitTokenMinAmountOut the min amount of the exit token that will be received from balancer given
	 * the bpt amount in, in each chain
	 * @param swapProviders the swap contract used for swapping the exit token to usdc for each chain.
	 * @param swapsCalldata the swap calldata to be passed for the swap contract for each chain.
	 * 	*/
	function withdraw(
		uint256 bptAmountPerChain,
		address[] calldata swapProviders,
		uint256[] calldata exitTokenIndex,
		uint256[] calldata exitTokenMinAmountOut,
		bytes[] calldata swapsCalldata
	) external {
		bytes32 withdrawId = keccak256(abi.encodePacked(block.number, msg.sender, ++s_nonce));
		uint256 chains = s_chainsSet.length();

		if (chains != swapProviders.length) revert CTF__SwapProvidersLengthMismatch(swapProviders.length, chains);
		if (chains != swapsCalldata.length) revert CTF__SwapsCallDataLengthMismatch(swapsCalldata.length, chains);
		if (chains != exitTokenIndex.length) revert CTF__ExitTokenIndexLengthMismatch(exitTokenIndex.length, chains);
		if (chains != exitTokenMinAmountOut.length) revert CTF__MinExitTokenOutLengthMismatch(exitTokenMinAmountOut.length, chains);

		transferFrom(msg.sender, address(this), bptAmountPerChain * chains);

		for (uint256 i = 0; i < chains; ) {
			_requestPoolWithdrawal(
				withdrawId,
				bptAmountPerChain,
				s_chainsSet.at(i),
				swapProviders[i],
				exitTokenIndex[i],
				exitTokenMinAmountOut[i],
				swapsCalldata[i]
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
			} else {
				revert Pool__NotActive(tokenChain);
			}

			//slither-disable-next-line costly-loop
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
		} else {
			revert Pool__NotActive(block.chainid);
		}
	}

	function _onCreatePool(uint256 chainId, address[] memory tokens) internal override {
		uint256 tokensLength = tokens.length;

		for (uint256 i = 0; i < tokensLength; ) {
			s_chainUnderlyingTokens[chainId].push(tokens[i]);
			s_underlyingTokens.push(tokens[i]);

			unchecked {
				++i;
			}
		}

		s_chains.push(chainId);
	}

	function _onDeposit(address user, uint256 totalBPTReceived) internal virtual override {
		_mint(user, totalBPTReceived);

		emit CTF__Deposited(user, totalBPTReceived);
	}

	function _onWithdraw(address user, uint256 totalBPTWithdrawn, uint256 totalUSDCToSend) internal virtual override {
		_burn(address(this), totalBPTWithdrawn);
		i_usdc.transfer(user, totalUSDCToSend);

		emit CTF__Withdrawn(user, totalBPTWithdrawn, totalUSDCToSend);
	}
}
