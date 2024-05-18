// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CCIPReceiver, Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {BalancerPoolManager} from "src/contracts/BalancerPoolManager.sol";
import {SafeCrossChainRequestType, CrossChainRequest} from "src/libraries/SafeCrossChainRequestType.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CustomCast} from "src/libraries/CustomCast.sol";
import {RequestReceipt} from "src/libraries/RequestReceipt.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {NetworkHelper} from "src/libraries/NetworkHelper.sol";
import {Swap} from "src/contracts/Swap.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CrossChainPoolManager is CCIPReceiver, BalancerPoolManager, Ownable2Step, Swap {
	using SafeERC20 for IERC20;
	using SafeCrossChainRequestType for CrossChainRequest.CrossChainRequestType;
	using Strings for uint256;
	using CustomCast for address[];

	struct CCIPReceipt {
		RequestReceipt.CrossChainReceipt receipt;
		bytes sender;
		bytes32 originMessageId;
		uint256 usdcAmount;
		uint64 sourceChainSelector;
		address usdcAddress;
	}

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

	/// @notice emitted once the requested deposit was successful
	event CrossChainPoolManager__Deposited(bytes32 indexed poolId, bytes32 indexed depositId, uint256 usdcAmount, uint256 bptreceived);

	/// @notice emitted once the ETH was withdrawn by the Admin
	event CrossChainPoolManager__ETHWithdrawn(uint256 amount);

	/// @notice thrown when the ccip received message sender is not the CTF
	error CrossChainPoolManager__SenderIsNotCTF(address sender, address ctf);

	/// @notice thrown when someone else tries to call `proccessCCIPMessage` instead of the contract itself
	error CrossChainPoolManager__OnlySelf(address caller);

	/// @notice thrown when the message couldn't be processed and we don't know what it is
	error CrossChainPoolManager__UnknownMessage(bytes32 messageId, bytes messageData);

	/// @notice thrown when the receipt couldn't be generated for the message because the request type is unknown
	error CrossChainPoolManager__UnknownReceipt(bytes32 messageId);

	/// @notice thrown when someone tries to re-send a receipt which didn't fail
	error CrossChainPoolManager__CannotRetrySendReceipt(bytes32 originMessageId);

	/// @notice thrown when the CTF address is invalid at the creation of the contract
	error CrossChainPoolManager__InvalidCTFAddress();

	/// @notice thrown when the ETH witdraw fails for some reason
	error CrossChainPoolManager__FailedToWithdrawETH(bytes errorData);

	modifier onlySelf() {
		if (msg.sender != address(this)) revert CrossChainPoolManager__OnlySelf(msg.sender);
		_;
	}

	constructor(
		address ctf
	)
		Ownable(NetworkHelper._getCTFAdmin())
		CCIPReceiver(NetworkHelper._getCCIPRouter())
		BalancerPoolManager(NetworkHelper._getBalancerManagedPoolFactory(), NetworkHelper._getBalancerVault())
	{
		if (ctf == address(0)) revert CrossChainPoolManager__InvalidCTFAddress();
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

		emit CrossChainPoolManager__ETHWithdrawn(amount);
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
	function processCCIPMessage(Client.Any2EVMMessage calldata message) external onlySelf returns (RequestReceipt.CrossChainReceipt memory) {
		CrossChainRequest.CrossChainRequestType requestType = abi.decode(message.data, (CrossChainRequest.CrossChainRequestType));

		if (requestType.isCreatePool()) {
			(, CrossChainRequest.CrossChainCreatePoolRequest memory request) = abi.decode(
				message.data,
				(CrossChainRequest.CrossChainRequestType, CrossChainRequest.CrossChainCreatePoolRequest)
			);
			return _createPool(request);
		}

		if (requestType.isDeposit()) {
			(, CrossChainRequest.CrossChainDepositRequest memory request) = abi.decode(
				message.data,
				(CrossChainRequest.CrossChainRequestType, CrossChainRequest.CrossChainDepositRequest)
			);

			return _deposit(request, message.destTokenAmounts[0].amount, IERC20(message.destTokenAmounts[0].token));
		}

		revert CrossChainPoolManager__UnknownMessage(message.messageId, message.data);
	}

	/**
	 * @notice Send the receipt back to the CTF. It can only be called by the contract itself
	 * @dev We use this function as public to make it possible to use Try-Catch
	 */
	function sendReceipt(CCIPReceipt calldata ccipReceipt) external onlySelf returns (bytes32 messageId) {
		return _rawSendReceipt(ccipReceipt);
	}

	/// @notice get the CTF that this pool manager is linked to
	function getCTF() external view returns (address) {
		return i_CTF;
	}

	//slither-disable-next-line reentrancy-benign
	function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
		address messageSender = abi.decode(message.sender, (address));
		if (messageSender != i_CTF) revert CrossChainPoolManager__SenderIsNotCTF(messageSender, i_CTF);

		try this.processCCIPMessage(message) returns (RequestReceipt.CrossChainReceipt memory receipt) {
			_sendReceipt(message, receipt, 0, address(0));
		} catch {
			_executeErrorActions(message);
		}
	}

	function _createPool(
		CrossChainRequest.CrossChainCreatePoolRequest memory request
	) private returns (RequestReceipt.CrossChainReceipt memory receipt) {
		(address poolAddress, bytes32 poolId) = super._createPool({
			name: request.poolName,
			symbol: block.chainid.toString(),
			initialTokens: request.tokens.toIERC20List()
		});

		emit CrossChainPoolManager__PoolCreated(poolAddress, poolId, request.tokens);

		return RequestReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, request.tokens);
	}

	function _deposit(
		CrossChainRequest.CrossChainDepositRequest memory request,
		uint256 usdcAmountReceived,
		IERC20 usdc
	) private returns (RequestReceipt.CrossChainReceipt memory receipt) {
		_swapUSDC(usdc, usdcAmountReceived, request.swapProvider, request.swapsCalldata);
		uint256 bptReceived = _joinPool(request.poolId, request.joinTokens, request.minBPTOut);

		emit CrossChainPoolManager__Deposited(request.poolId, request.depositId, usdcAmountReceived, bptReceived);

		return RequestReceipt.crossChainDepositedReceipt(request.depositId, bptReceived);
	}

	//slither-disable-next-line reentrancy-benign
	function _sendReceipt(
		Client.Any2EVMMessage memory message,
		RequestReceipt.CrossChainReceipt memory receipt,
		uint256 usdcAmount,
		address usdcAddress
	) private {
		CCIPReceipt memory ccipReceipt = CCIPReceipt({
			receipt: receipt,
			originMessageId: message.messageId,
			sourceChainSelector: message.sourceChainSelector,
			sender: message.sender,
			usdcAmount: usdcAmount,
			usdcAddress: usdcAddress
		});

		s_receipts[message.messageId] = ccipReceipt;

		// solhint-disable-next-line no-empty-blocks
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

	function _executeErrorActions(Client.Any2EVMMessage memory message) private {
		CrossChainRequest.CrossChainRequestType requestType = abi.decode(message.data, (CrossChainRequest.CrossChainRequestType));

		if (requestType.isDeposit()) {
			(, CrossChainRequest.CrossChainDepositRequest memory depositRequest) = abi.decode(
				message.data,
				(CrossChainRequest.CrossChainRequestType, CrossChainRequest.CrossChainDepositRequest)
			);
			RequestReceipt.CrossChainReceipt memory receipt = RequestReceipt.crossChainDepositFailedReceipt(depositRequest.depositId);
			return _sendReceipt(message, receipt, message.destTokenAmounts[0].amount, message.destTokenAmounts[0].token);
		}

		_sendReceipt(message, _getGenericErrorReceipt(message.messageId, requestType), 0, address(0));
	}

	function _getGenericErrorReceipt(
		bytes32 ccipMessageId,
		CrossChainRequest.CrossChainRequestType requestType
	) private view returns (RequestReceipt.CrossChainReceipt memory receipt) {
		if (requestType.isCreatePool()) {
			return RequestReceipt.crossChainGenericFailedReceipt(RequestReceipt.CrossChainFailureReceiptType.POOL_CREATION_FAILED);
		}

		if (requestType.isDeposit()) {
			return RequestReceipt.crossChainGenericFailedReceipt(RequestReceipt.CrossChainFailureReceiptType.DEPOSIT_FAILED);
		}

		revert CrossChainPoolManager__UnknownReceipt(ccipMessageId);
	}

	function _buildReceiptCCIPMessage(
		CCIPReceipt memory ccipReceipt
	) private view returns (Client.EVM2AnyMessage memory message, uint256 fee) {
		Client.EVMTokenAmount[] memory tokens;

		if (ccipReceipt.usdcAmount != 0) {
			tokens = new Client.EVMTokenAmount[](1);
			tokens[0] = Client.EVMTokenAmount({token: ccipReceipt.usdcAddress, amount: ccipReceipt.usdcAmount});
		}

		message = Client.EVM2AnyMessage({
			receiver: ccipReceipt.sender,
			data: abi.encode(ccipReceipt.receipt),
			tokenAmounts: tokens,
			feeToken: address(0),
			extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 500_000}))
		});

		fee = IRouterClient(i_ccipRouter).getFee(ccipReceipt.sourceChainSelector, message);
		return (message, fee);
	}
}
