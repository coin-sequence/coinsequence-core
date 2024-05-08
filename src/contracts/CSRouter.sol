// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CSExecutor} from "src/contracts/CSExecutor.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {CSRouterDepositRequest} from "src/types/CSRouterDepositRequest.sol";
import {CSRouterMintRequest} from "src/types/CSRouterMintRequest.sol";
import {CSRouterCTFRequestType} from "src/types/CSRouterCTFRequestType.sol";
import {IRouterClient, Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @dev CSRouter is the contract resposible for receiving CCIP
 * Messages and act accordingly to them(Deposit, withdraw, etc...)
 *
 */
contract CSRouter is CSExecutor, CCIPReceiver, Ownable2Step {
	mapping(bytes32 messageId => bool allowRetry) public retryAllowed;

	/// @notice emitted when a deposit is succesfully made
	event Deposited(address indexed user, address indexed ctf, uint256 usdcAmount, uint256 bptAmountReceived);

	/// @notice emitted when a deposit Request is failed and needs to be retried
	event DepositRetryRequired(bytes32 indexed messageId, CSRouterDepositRequest errorDepositRequest);

	/// @notice thrown if the caller is not the CSRouter itself
	error OnlySelf();

	/// @notice thrown if trying to retry a call thats not ready to be retried
	error OnlyRetry();

	modifier onlySelf() {
		if (msg.sender != address(this)) revert OnlySelf();
		_;
	}

	modifier onlyRetry(bytes32 messageId) {
		if (!retryAllowed[messageId]) revert OnlyRetry();
		_;
	}

	constructor(
		address balancerVault,
		address ccipRouter,
		address usdc,
		address admin
	) Ownable(admin) CSExecutor(balancerVault, usdc) CCIPReceiver(ccipRouter) {}

	function retryDeposit(
		uint64 originChainSelector,
		bytes32 messageId,
		CSRouterDepositRequest calldata depositRequest
	) external onlyOwner onlyRetry(messageId) {
		retryAllowed[messageId] = false;
		this.handleDepositRequest(originChainSelector, abi.encode(depositRequest));
	}

	/// @notice Handle the deposit request, this function should only be called by the CSRouter.
	/// @dev this function is external to allow the use of try-catch
	function handleDepositRequest(uint64 originChainSelector, bytes calldata data) external onlySelf {
		CSRouterDepositRequest memory depositRequest = abi.decode(data, (CSRouterDepositRequest));

		uint256 receivedBPT = _swapAndDepositToBalancer(
			depositRequest.poolId,
			depositRequest.ogDeposit.usdcAmount,
			depositRequest.ogDeposit.swapsData,
			depositRequest.ogDeposit.swapProvider,
			depositRequest.ogDeposit.minBPTOut
		);

		bytes memory mintRequest = abi.encode(
			CSRouterCTFRequestType.MINT,
			CSRouterMintRequest(depositRequest.user, receivedBPT)
		);

		Client.EVM2AnyMessage memory ccipMessage = _buildCCIPMessage(address(depositRequest.targetCTF), mintRequest);
		IRouterClient routerClient = IRouterClient(i_ccipRouter);

		uint256 ccipFee = routerClient.getFee(originChainSelector, ccipMessage);
		routerClient.ccipSend{value: ccipFee}(originChainSelector, ccipMessage);

		emit Deposited(
			depositRequest.user,
			address(depositRequest.targetCTF),
			depositRequest.ogDeposit.usdcAmount,
			receivedBPT
		);
	}

	function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {
		if (message.destTokenAmounts.length > 0) {
			try this.handleDepositRequest(message.sourceChainSelector, message.data) {} catch {
				emit DepositRetryRequired(message.messageId, abi.decode(message.data, (CSRouterDepositRequest)));

				//slither-disable-next-line reentrancy-benign
				retryAllowed[message.messageId] = true;
			}
		} else {
			// handle withdraw
		}
	}

	function _buildCCIPMessage(
		address receiver,
		bytes memory data
	) private pure returns (Client.EVM2AnyMessage memory message) {
		return
			Client.EVM2AnyMessage({
				receiver: abi.encode(receiver),
				data: data,
				tokenAmounts: new Client.EVMTokenAmount[](0),
				feeToken: address(0),
				extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: /* TODO: check gasLimit */ 3_000_000}))
			});
	}
}
