// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IEngine, ICTF, IERC20} from "src/interfaces/IEngine.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FunctionsRequestParams} from "src/types/FunctionsRequestParams.sol";
import {FunctionsClient, FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol"; // solhint-disable-line max-line-length
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SafeFunctionsRequestStatus, FunctionsRequestStatus} from "src/libraries/SafeFunctionsRequestStatus.sol";

/// @dev This contract is used to control the CTFs deposits and withdrawals.
contract Engine is IEngine, FunctionsClient, AccessControlDefaultAdminRules {
	using SafeERC20 for IERC20;
	using FunctionsRequest for FunctionsRequest.Request;
	using Strings for uint256;
	using Strings for address;
	using SafeFunctionsRequestStatus for FunctionsRequestStatus;

	bytes32 public constant SWAPPER_ROLE = "SWAPPER";

	FunctionsRequestParams private s_functionsRequestParams;
	mapping(bytes32 requestId => FunctionsRequestStatus status) private s_functionsRequests;

	/// @dev as the roles are not initialized in the constructor(only the admin is),
	/// after the contract deployment, make sure to ask the admin wallet
	/// to assign the missing roles.
	constructor(
		address functionsRouter,
		uint32 functionsSubscriptionId,
		uint32 functionsCallbackGasLimit,
		bytes32 functionsDonId,
		string memory functionsDepositSource,
		address admin
	) FunctionsClient(functionsRouter) AccessControlDefaultAdminRules(3 days, admin) {
		s_functionsRequestParams = FunctionsRequestParams({
			subscriptionId: functionsSubscriptionId,
			callbackGasLimit: functionsCallbackGasLimit,
			donId: functionsDonId,
			source: functionsDepositSource
		});
	}

	/// @inheritdoc IEngine
	function deposit(ICTF outputCTF, IERC20 inputToken, uint256 inputTokenAmount) external override {
		inputToken.safeTransferFrom(msg.sender, address(this), inputTokenAmount);

		FunctionsRequestParams memory functionsRequestParams = s_functionsRequestParams;

		string[] memory functionsArgs = new string[](4);
		functionsArgs[0] = block.chainid.toString();
		functionsArgs[1] = address(inputToken).toHexString();
		functionsArgs[2] = inputTokenAmount.toString();
		functionsArgs[3] = address(outputCTF).toHexString();

		//slither-disable-next-line uninitialized-local
		FunctionsRequest.Request memory req;

		req.initializeRequestForInlineJavaScript(functionsRequestParams.source);
		req.setArgs(functionsArgs);

		bytes32 requestId = _sendRequest(
			req.encodeCBOR(),
			functionsRequestParams.subscriptionId,
			functionsRequestParams.callbackGasLimit,
			functionsRequestParams.donId
		);

		s_functionsRequests[requestId] = FunctionsRequestStatus.REQUESTED;

		emit Engine__RequestedDeposit(requestId, msg.sender, address(outputCTF));
	}

	/// @inheritdoc IEngine
	function swap(
		address swapContract,
		bytes32 requestId,
		bytes calldata swapCalldata
	) external override onlyRole(SWAPPER_ROLE) {
		FunctionsRequestStatus requestStatus = s_functionsRequests[requestId];

		if (swapContract == address(0)) revert Engine__InvalidSwapContract();

		if (!requestStatus._isRequested()) {
			// solhint-disable-next-line chainlink-solidity/no-block-single-if-reverts
			revert Engine__RequestStatusMismatch({expected: FunctionsRequestStatus.REQUESTED, actual: requestStatus});
		}

		//slither-disable-next-line low-level-calls
		(bool success, ) = swapContract.call(swapCalldata); // solhint-disable-line avoid-low-level-calls

		if (!success) revert Engine__SwapFailed();

		//slither-disable-next-line reentrancy-events
		emit Engine__TokensSwapped();
	}

	/// @notice Set the Chainlink Functions request Params.
	/// This can only be executed if the sender wallet is the admin wallet
	function setFunctionsRequestParams(FunctionsRequestParams calldata params) external onlyRole(DEFAULT_ADMIN_ROLE) {
		s_functionsRequestParams = params;
	}

	// solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
	function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual override {
		if (!s_functionsRequests[requestId]._isRequested()) {
			// solhint-disable-next-line chainlink-solidity/no-block-single-if-reverts
			revert Engine__RequestStatusMismatch({
				expected: FunctionsRequestStatus.REQUESTED,
				actual: s_functionsRequests[requestId]
			});
		}

		if (err.length > 0) {}
	}
}
