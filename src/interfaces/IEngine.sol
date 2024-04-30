// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICTF} from "src/interfaces/ICTF.sol";
import {FunctionsRequestStatus} from "src/types/FunctionsRequestStatus.sol";

interface IEngine {
	/// @notice Emitted when the functions request is sent to call the API
	/// responsible for managing the CTFs Deposit
	/// @param requestId The ID of the Chainlink Functions Request
	/// @param user The address of the user who requested the deposit
	/// @param ctf The target CTF address to deposit funds
	event Engine__RequestedDeposit(bytes32 indexed requestId, address indexed user, address indexed ctf);

	/// @notice Emitted when the call to swap the user input token to the CTF Underlying Token succeeds
	event Engine__TokensSwapped();

	/// @notice Thrown when the call to swap the user input token to the CTF Underlying Token fails
	error Engine__SwapFailed();

	/// @notice Thrown when the passed request id does not match the required request status
	/// @param expected The needed request status to perform the call
	/// @param actual The actual request status, which is not the expected
	error Engine__RequestStatusMismatch(FunctionsRequestStatus expected, FunctionsRequestStatus actual);

	/// @notice Thrown when the passed swap contract for the swap function is not a valid contract
	error Engine__InvalidSwapContract();

	/// @notice deposit some token and get CTF Token in return
	/// @param outputCTF the CTF Token address that the user wants to receive
	/// @param inputToken The user chosen token to deposit
	/// @param inputTokenAmount The amount of the user chosen token to deposit
	function deposit(ICTF outputCTF, IERC20 inputToken, uint256 inputTokenAmount) external;

	/// @notice external call to swap the user input tokens for the CTF Underlying Tokens.
	/// @param swapContract The address of the contract which will perform the swap
	/// @param swapCalldata the calldata to pass to the swap contract
	/// @param requestId The Chainlink Functions Request ID
	/// @dev Only Wallets with the Swapper role will be able to perform this call
	/// @dev If the Request ID status is not "REQUESTED" an error should be be thrown.
	function swap(address swapContract, bytes32 requestId, bytes calldata swapCalldata) external;
}
