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

	struct FailedWithdraw {
		CrossChainRequest.CrossChainWithdrawRequest request;
		Client.Any2EVMMessage ccipMessage;
		bool retriable;
	}

	struct FailedDeposit {
		CrossChainRequest.CrossChainDepositRequest request;
		Client.Any2EVMMessage ccipMessage;
		bool retriable;
	}

	address private immutable i_CTF;

	mapping(bytes32 originMessageId => CCIPReceipt ccipReceipt) private s_receipts;
	mapping(bytes32 originMessageId => bool retryAllowed) private s_receiptRetryAllowed;
	mapping(bytes32 withdrawId => FailedWithdraw failedWithdraw) private s_failedWithdraws;
	mapping(bytes32 depositId => FailedDeposit failedDeposit) private s_failedDeposits;

	/// @notice emitted once the Pool for the CTF is successfully created
	event CrossChainPoolManager__PoolCreated(address indexed poolAddress, bytes32 indexed poolId, address[] tokens);

	/// @notice emitted once the receipt couldn't be sent by some reason
	event CrossChainPoolManager__FailedToSendReceipt(
		bytes32 indexed originMessageId,
		RequestReceipt.CrossChainReceiptType indexed receiptType,
		bytes errorData
	);

	/// @notice emitted once a withdraw failed for some reason
	event CrossChainPoolManager__FailedToWithdraw(bytes32 indexed withdrawId);

	/// @notice emitted once a deposit failed for some reason
	event CrossChainPoolManager__FailedToDeposit(bytes32 indexed depositId);

	/// @notice emitted once the receipt was successfully sent
	event CrossChainPoolManager__ReceiptSent(
		bytes32 indexed originMessageId,
		bytes32 indexed receiptMessageId,
		RequestReceipt.CrossChainReceiptType indexed receiptType
	);

	/// @notice emitted once the requested deposit was successful
	event CrossChainPoolManager__Deposited(bytes32 indexed poolId, bytes32 indexed depositId, uint256 usdcAmount, uint256 bptreceived);

	/// @notice emitted once the requested withdrawal was successful
	event CrossChainPoolManager__Withdrawn(bytes32 indexed amount, bytes32 indexed withdrawId, uint256 bptIn, uint256 usdcReceived);

	/// @notice emitted once the ETH was withdrawn by the Admin
	event CrossChainPoolManager__ETHWithdrawn(uint256 amount);

	/// @notice emitted when the admin successfully overrode a failed withdraw
	event CrossChainPoolManager__overrodeFailedWithdraw(bytes32 withdrawId);

	/// @notice emitted when the admin successfully overrode a failed deposit
	event CrossChainPoolManager__overrodeFailedDeposit(bytes32 depositId);

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

	/// @notice thrown when someone tries to retry a failed withdraw which didn't fail
	error CrossChainPoolManager__CannotRetryFailedWithdraw(bytes32 withdrawId);

	/// @notice thrown when the CTF address is invalid at the creation of the contract
	error CrossChainPoolManager__InvalidCTFAddress();

	/// @notice thrown when the ETH witdraw fails for some reason
	error CrossChainPoolManager__FailedToWithdrawETH(bytes errorData);

	modifier onlySelf() {
		if (msg.sender != address(this)) revert CrossChainPoolManager__OnlySelf(msg.sender);
		_;
	}

	constructor(
		address ctf,
		address admin
	)
		Ownable(admin)
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

	/// @notice re-send a failed withdraw at given withdraw id and override the request data. Only the admin can perform this action
	function overrideFailedWithdraw(bytes32 withdrawId, CrossChainRequest.CrossChainWithdrawRequest memory request) external onlyOwner {
		FailedWithdraw memory failedWithdraw = s_failedWithdraws[withdrawId];

		if (!failedWithdraw.retriable) revert CrossChainPoolManager__CannotRetryFailedWithdraw(withdrawId);

		delete s_failedWithdraws[withdrawId];
		_executeSuccessActions(failedWithdraw.ccipMessage, _withdraw(request));

		emit CrossChainPoolManager__overrodeFailedWithdraw(withdrawId);
	}

	/// @notice re-send a failed deposit at given deposit id and override the request data. Only the admin can perform this action
	function overrideFailedDeposit(bytes32 depositId, CrossChainRequest.CrossChainDepositRequest memory request) external onlyOwner {
		FailedDeposit memory failedDeposit = s_failedDeposits[depositId];
		uint256 receivedUSDC = failedDeposit.ccipMessage.destTokenAmounts[0].amount;
		IERC20 usdc = IERC20(failedDeposit.ccipMessage.destTokenAmounts[0].token);

		if (!failedDeposit.retriable) revert CrossChainPoolManager__CannotRetryFailedWithdraw(depositId);

		delete s_failedDeposits[depositId];
		_executeSuccessActions(failedDeposit.ccipMessage, _deposit(request, receivedUSDC, usdc));

		emit CrossChainPoolManager__overrodeFailedDeposit(depositId);
	}

	/**
	 * 	@notice Process the CCIP Message received. It can only be called by the contract itself
	 *  @dev We use this function as external to make it possible the use of Try-Catch
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

		if (requestType.isWithdraw()) {
			(, CrossChainRequest.CrossChainWithdrawRequest memory request) = abi.decode(
				message.data,
				(CrossChainRequest.CrossChainRequestType, CrossChainRequest.CrossChainWithdrawRequest)
			);

			return _withdraw(request);
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

	/// @notice get the Failed withdraw at the given id
	function getFailedWithdraw(bytes32 withdrawId) external view returns (FailedWithdraw memory) {
		return s_failedWithdraws[withdrawId];
	}

	//slither-disable-next-line reentrancy-benign
	function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
		address messageSender = abi.decode(message.sender, (address));
		if (messageSender != i_CTF) revert CrossChainPoolManager__SenderIsNotCTF(messageSender, i_CTF);

		try this.processCCIPMessage(message) returns (RequestReceipt.CrossChainReceipt memory receipt) {
			_executeSuccessActions(message, receipt);
		} catch {
			_executeErrorActions(message);
		}
	}

	function _createPool(
		CrossChainRequest.CrossChainCreatePoolRequest memory request
	) private returns (RequestReceipt.CrossChainReceipt memory receipt) {
		(address poolAddress, bytes32 poolId, uint256[] memory weights) = super._createPool({
			name: request.poolName,
			symbol: block.chainid.toString(),
			initialTokens: request.tokens.toIERC20List()
		});

		emit CrossChainPoolManager__PoolCreated(poolAddress, poolId, request.tokens);

		return RequestReceipt.crossChainPoolCreatedReceipt(poolAddress, poolId, request.tokens, weights);
	}

	function _deposit(
		CrossChainRequest.CrossChainDepositRequest memory request,
		uint256 usdcAmountReceived,
		IERC20 usdc
	) private returns (RequestReceipt.CrossChainReceipt memory receipt) {
		_swap(usdc, usdcAmountReceived, request.swapProvider, request.swapsCalldata);
		uint256 bptReceived = _joinPool(request.poolId, request.minBPTOut);

		emit CrossChainPoolManager__Deposited(request.poolId, request.depositId, usdcAmountReceived, bptReceived);

		return RequestReceipt.crossChainDepositedReceipt(request.depositId, bptReceived);
	}

	function _withdraw(
		CrossChainRequest.CrossChainWithdrawRequest memory request
	) private returns (RequestReceipt.CrossChainReceipt memory receipt) {
		bytes[] memory swapsData = new bytes[](1);
		swapsData[0] = request.swapCalldata;
		address usdcAddress = NetworkHelper._getUSDC();
		IERC20 usdc = IERC20(usdcAddress);

		(uint256 exitTokenAmountOut, IERC20 exitToken) = _exitPool(
			request.poolId,
			request.bptAmountIn,
			request.exitTokenMinAmountOut,
			request.exitTokenIndex
		);

		uint256 usdcOut = _swapUSDCOut(exitToken, usdc, exitTokenAmountOut, request.swapProvider, swapsData);

		emit CrossChainPoolManager__Withdrawn(request.poolId, request.withdrawalId, request.bptAmountIn, usdcOut);

		return RequestReceipt.crossChainWithdrawnReceipt(request.withdrawalId, usdcOut);
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

		if (usdcAmount != 0 && usdcAddress != address(0)) IERC20(usdcAddress).forceApprove(i_ccipRouter, usdcAmount);

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

			s_failedDeposits[depositRequest.depositId] = FailedDeposit({request: depositRequest, ccipMessage: message, retriable: true});
			emit CrossChainPoolManager__FailedToDeposit(depositRequest.depositId);

			return;
		}

		if (requestType.isWithdraw()) {
			(, CrossChainRequest.CrossChainWithdrawRequest memory withdrawRequest) = abi.decode(
				message.data,
				(CrossChainRequest.CrossChainRequestType, CrossChainRequest.CrossChainWithdrawRequest)
			);

			s_failedWithdraws[withdrawRequest.withdrawalId] = FailedWithdraw({request: withdrawRequest, ccipMessage: message, retriable: true});
			emit CrossChainPoolManager__FailedToWithdraw(withdrawRequest.withdrawalId);

			return;
		}

		_sendReceipt(message, _getGenericErrorReceipt(message.messageId, requestType), 0, address(0));
	}

	function _executeSuccessActions(Client.Any2EVMMessage memory message, RequestReceipt.CrossChainReceipt memory receipt) private {
		CrossChainRequest.CrossChainRequestType requestType = abi.decode(message.data, (CrossChainRequest.CrossChainRequestType));

		if (requestType.isWithdraw()) {
			RequestReceipt.CrossChainWithdrawReceipt memory withdrawReceipt = abi.decode(
				receipt.data,
				(RequestReceipt.CrossChainWithdrawReceipt)
			);
			return _sendReceipt(message, receipt, withdrawReceipt.receivedUSDC, NetworkHelper._getUSDC());
		}

		_sendReceipt(message, receipt, 0, address(0));
	}

	function _getGenericErrorReceipt(
		bytes32 ccipMessageId,
		CrossChainRequest.CrossChainRequestType requestType
	) private view returns (RequestReceipt.CrossChainReceipt memory receipt) {
		if (requestType.isCreatePool()) {
			return RequestReceipt.crossChainGenericFailedReceipt(RequestReceipt.CrossChainFailureReceiptType.POOL_CREATION_FAILED);
		}

		revert CrossChainPoolManager__UnknownReceipt(ccipMessageId);
	}

	function _buildReceiptCCIPMessage(
		CCIPReceipt memory ccipReceipt
	) private view returns (Client.EVM2AnyMessage memory message, uint256 fee) {
		//slither-disable-next-line uninitialized-local
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
