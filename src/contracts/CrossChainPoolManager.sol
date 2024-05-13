// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CCIPReceiver, Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {BalancerPoolManager} from "src/contracts/BalancerPoolManager.sol";
import {SafeCrossChainRequestType, CrossChainRequestType} from "src/libraries/SafeCrossChainRequestType.sol";
import {CrossChainCreatePoolRequest} from "src/types/CrossChainCreatePoolRequest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CustomCast} from "src/libraries/CustomCast.sol";
import {RequestReceipt} from "src/libraries/RequestReceipt.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract CrossChainPoolManager is CCIPReceiver, BalancerPoolManager, Ownable2Step {
	using SafeCrossChainRequestType for CrossChainRequestType;
	using Strings for uint256;
	using CustomCast for address[];

	struct CCIPReceipt {
		RequestReceipt.CrossChainReceipt receipt;
		uint64 sourceChainSelector;
		bytes sender;
		bytes32 originMessageId;
	}

	address private immutable i_CCIPRouterClient;
	address private immutable i_CTF;

	mapping(bytes32 originMessageId => CCIPReceipt ccipReceipt) private s_receipts;
	mapping(bytes32 originMessageId => bool retryAllowed) private s_receiptRetryAllowed;

	/// @notice emitted once the Pool for the CTF is successfully created
	event CrossChainPoolManager__PoolCreated(address indexed poolAddress, bytes32 indexed poolId, address[] tokens);

	/// @notice emitted once the receipt couldn't be sent by some reason
	event CrossChainPoolManager__FailedToSendReceipt(
		bytes32 indexed originMessageId,
		RequestReceipt.CrossChainReceiptType indexed receiptType,
		bytes errorData
	);

	/// @notice emitted once the receipt was successfully sent
	event CrossChainPoolManager__ReceiptSent(
		bytes32 indexed originMessageId,
		bytes32 indexed receiptMessageId,
		RequestReceipt.CrossChainReceiptType indexed receiptType
	);

	/// @notice thrown when the ccip received message sender is not the CTF
	error CrossChainPoolManager__SenderIsNotCTF(address sender, address ctf);

	/// @notice thrown when someone else tries to call `proccessCCIPMessage` instead of the contract itself
	error CrossChainPoolManager__OnlySelf(address caller);

	/// @notice thrown when the message couldn't be processed and we don't know what it is
	error CrossChainPoolManager__UnknownMessage(bytes32 messageId, bytes messageData);

	/// @notice thrown when someone tries to re-send a receipt which didn't fail
	error CrossChainPoolManager__CannotRetrySendReceipt(bytes32 originMessageId);

	/// @notice thrown when the CTF address is invalid at the creation of the contract
	error CrossChainPoolManager__InvalidCTFAddress();

	/// @notice thrown when the CCIP Router Client address is invalid at the creation of the contract
	error CrossChainPoolManager__InvalidCCIPRouterClient();

	/// @notice thrown when the ETH witdraw fails for some reason
	error CrossChainPoolManager__FailedToWithdrawETH(bytes errorData);

	modifier onlySelf() {
		if (msg.sender != address(this)) revert CrossChainPoolManager__OnlySelf(msg.sender);
		_;
	}

	constructor(
		address ccipRouterClient,
		address ctf,
		address balancerManagedPoolFactory,
		address balancerVault,
		address admin
	) Ownable(admin) CCIPReceiver(ccipRouterClient) BalancerPoolManager(balancerManagedPoolFactory, balancerVault) {
		if (ccipRouterClient == address(0) || ccipRouterClient.code.length == 0) revert CrossChainPoolManager__InvalidCCIPRouterClient();
		if (ctf == address(0)) revert CrossChainPoolManager__InvalidCTFAddress();

		i_CCIPRouterClient = ccipRouterClient;
		i_CTF = ctf;
	}

	receive() external payable {}

	/**
	 * @notice withdraw ETH from the Contract. Only the admin can perform this action
	 * @param amount amount of ETH to withdraw (with decimals)
	 * @custom:note this only withdraw the ETH used to cover infrastructural costs,
	 * Nothing is withdrawn from the Pool
	 */
	function withdrawETH(uint256 amount) external onlyOwner {
		(bool success, bytes memory data) = owner().call{value: amount}("");

		if (!success) revert CrossChainPoolManager__FailedToWithdrawETH(data);
	}

	/// @notice re-send a failed-to-send receipt
	function retrySendReceipt(bytes32 originMessageId) external returns (bytes32 receiptMessageId) {
		if (!s_receiptRetryAllowed[originMessageId]) revert CrossChainPoolManager__CannotRetrySendReceipt(originMessageId);
		s_receiptRetryAllowed[originMessageId] = false;

		return _rawSendReceipt(s_receipts[originMessageId]);
	}

	/**
	 * 	@notice Process the CCIP Message received. It can only be called by the contract itself
	 *  @dev We use this function as external to make it possible to use Try-Catch
	 */
	function processCCIPMessage(bytes32 messageId, bytes calldata data) external onlySelf returns (RequestReceipt.CrossChainReceipt memory) {
		CrossChainRequestType requestType = abi.decode(data, (CrossChainRequestType));

		if (requestType.isCreatePool()) {
			(, CrossChainCreatePoolRequest memory request) = abi.decode(data, (CrossChainRequestType, CrossChainCreatePoolRequest));
			return _createPool(request);
		}

		revert CrossChainPoolManager__UnknownMessage(messageId, data);
	}

	/**
	 * @notice Send the receipt back to the CTF. It can only be called by the contract itself
	 * @dev We use this function as public to make it possible to use Try-Catch
	 */
	function sendReceipt(CCIPReceipt memory ccipReceipt) external onlySelf returns (bytes32 messageId) {
		return _rawSendReceipt(ccipReceipt);
	}

	//slither-disable-next-line reentrancy-benign
	function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
		address messageSender = abi.decode(message.sender, (address));
		if (messageSender != i_CTF) revert CrossChainPoolManager__SenderIsNotCTF(messageSender, i_CTF);

		try this.processCCIPMessage(message.messageId, message.data) returns (RequestReceipt.CrossChainReceipt memory receipt) {
			_sendReceipt(message, receipt);
		} catch {
			RequestReceipt.CrossChainReceipt memory receipt = _getErrorReceipt(message.data);
			_sendReceipt(message, receipt);
		}
	}

	function _createPool(CrossChainCreatePoolRequest memory request) private returns (RequestReceipt.CrossChainReceipt memory receipt) {
		(address poolAddress, bytes32 poolId) = super._createPool({
			name: request.poolName,
			symbol: block.chainid.toString(),
			initialTokens: request.tokens.toIERC20List()
		});

		emit CrossChainPoolManager__PoolCreated(poolAddress, poolId, request.tokens);

		return RequestReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, request.tokens);
	}

	//slither-disable-next-line reentrancy-benign
	function _sendReceipt(Client.Any2EVMMessage memory message, RequestReceipt.CrossChainReceipt memory receipt) private {
		CCIPReceipt memory ccipReceipt = CCIPReceipt({
			receipt: receipt,
			originMessageId: message.messageId,
			sourceChainSelector: message.sourceChainSelector,
			sender: message.sender
		});

		s_receipts[message.messageId] = ccipReceipt;

		try this.sendReceipt(ccipReceipt) {
			// DO NOTHING
		} catch (bytes memory errorData) {
			s_receiptRetryAllowed[message.messageId] = true;

			emit CrossChainPoolManager__FailedToSendReceipt(message.messageId, receipt.receiptType, errorData);
		}
	}

	function _rawSendReceipt(CCIPReceipt memory ccipReceipt) private returns (bytes32 messageId) {
		(Client.EVM2AnyMessage memory message, uint256 fee) = _buildReceiptCCIPMessage(ccipReceipt);

		messageId = IRouterClient(i_ccipRouter).ccipSend{value: fee}(ccipReceipt.sourceChainSelector, message);

		emit CrossChainPoolManager__ReceiptSent(ccipReceipt.originMessageId, messageId, ccipReceipt.receipt.receiptType);
	}

	function _getErrorReceipt(bytes memory data) private view returns (RequestReceipt.CrossChainReceipt memory receipt) {
		CrossChainRequestType requestType = abi.decode(data, (CrossChainRequestType));

		if (requestType.isCreatePool()) {
			return RequestReceipt.crossChainGenericFailedReceipt(RequestReceipt.CrossChainFailureReceiptType.POOL_CREATION_FAILED);
		}
	}

	function _buildReceiptCCIPMessage(
		CCIPReceipt memory ccipReceipt
	) private view returns (Client.EVM2AnyMessage memory message, uint256 fee) {
		message = Client.EVM2AnyMessage({
			receiver: ccipReceipt.sender,
			data: abi.encode(ccipReceipt.receipt),
			tokenAmounts: new Client.EVMTokenAmount[](0),
			feeToken: address(0),
			extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: /* TODO: check needed gas limit */ 3_000_000}))
		});

		fee = IRouterClient(i_ccipRouter).getFee(ccipReceipt.sourceChainSelector, message);
		return (message, fee);
	}
}
