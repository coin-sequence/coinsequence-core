// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CSDeposit} from "src/types/CSDeposit.sol";
import {ICTF} from "src/interfaces/ICTF.sol";

interface ICSEngine {
	/// @notice emitted when the funds for the same network as the CTF are deposited
	event CSEngine_DepositedToCurrentNetwork(
		address indexed ctf,
		bytes32 indexed poolId,
		uint256 usdcAmount,
		uint256 bptReceivedAmount
	);

	/// @notice emitted when a cross chain deposit request is sent to another chain
	event CSEngine_sentCrossChainDepositRequest(
		address indexed ctf,
		bytes32 indexed poolId,
		uint256 indexed chainId,
		bytes32 messageId,
		uint64 chainSelector,
		uint256 usdcAmount
	);

	/// @notice thrown when the CSRouter is not valid at the creation of the CSEngine
	error CSEngine__InvalidCSRouter();

	/// @notice thrown when the given CTF has not been created by Coin Sequence
	error CSEngine__CtfIsNotLegit(address ctf);

	/// @notice thrown when the given Chain ID is zero
	error CSEngine__ChainIdIsZero();

	/// @notice thrown when the given swap data array for deposit or withdraw from CTFs is empty
	error CSEngine__SwapDataIsEmpty();

	/// @notice thrown when the given swap provider is not valid
	error CSEngine__InvalidSwapProvider();

	/// @notice thrown when the given usdc amount to swap is zero
	error CSEngine__SwapAmountIsZero();

	/// @notice thrown when the ETH Value sent is not enough to pay for CCIP fees
	error CSEngine__CannotPayFees(uint256 valueSent, uint256 feeValue);

	/// @notice thrown when the deposits length does not match the underlying tokens chains length
	error CSEngine__DepositsLengthMismatch(uint256 depositsLength, uint256 underlyingTokensChainsLength);

	/**
	 * @notice deposit funds into the CTF and Receive CTF Tokens
	 *
	 * @param totalUSDCAmount the total amount of USDC to deposit across all networks.
	 * This amount should be the sum of all the networks USDC Deposit amounts. Otherwise
	 * We'll not have sufficient funds to deposit into balancer for each network.
	 *
	 * @param ctf the CTF that the user wants to receive
	 *
	 * @param deposits list of deposit data for tokens in different networks.
	 * If the CTF Only handle tokens from the same network, the list will have a single item.
	 *
	 * e.g: the CTF Handles 1 token on OP ans 2 Tokens on Polygon. The list should have 2 items
	 * e.g-2: The CTF Handles 4 tokens on OP, the list should have 1 item
	 *
	 * @dev this function assumes that the pool on balancer for each network already exists.
	 *  */
	function deposit(uint256 totalUSDCAmount, address router, ICTF ctf, CSDeposit[] calldata deposits) external payable;

	function withdraw() external;

	/**
	 * @notice calculate the CCIP Fee in ETH for Deposits to the CTF
	 * @param ctf the CTF that the user wants to receive
	 * @return fee the CCIP fee in ETH with decimals.
	 * e.g if the fee is 1 ETH, then the return value will be "1000000000000000000" (18 decimals)
	 *  */
	function calculateTotalCCIPDepositFee(
		ICTF ctf,
		address router,
		CSDeposit[] calldata deposits
	) external view returns (uint256 fee);
}
