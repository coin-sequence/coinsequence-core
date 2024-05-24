// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeChain} from "src/libraries/SafeChain.sol";
import {BalancerPoolManager} from "src/contracts/BalancerPoolManager.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IRouterClient, Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {AccessControlDefaultAdminRules, IAccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol"; //solhint-disable-line max-line-length
import {CrossChainRequest} from "src/libraries/CrossChainRequest.sol";
import {CustomCast} from "src/libraries/CustomCast.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {RequestReceipt} from "src/libraries/RequestReceipt.sol";
import {SafeCrossChainReceipt} from "src/libraries/SafeCrossChainReceipt.sol";
import {NetworkHelper} from "src/libraries/NetworkHelper.sol";
import {Arrays} from "src/libraries/Arrays.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Swap} from "src/contracts/Swap.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract PoolManager is CCIPReceiver, AccessControlDefaultAdminRules, BalancerPoolManager, Swap {
	using SafeChain for uint256;
	using Strings for uint256;
	using CustomCast for address[];
	using SafeCrossChainReceipt for RequestReceipt.CrossChainReceiptType;
	using SafeCrossChainReceipt for RequestReceipt.CrossChainSuccessReceiptType;
	using SafeCrossChainReceipt for RequestReceipt.CrossChainFailureReceiptType;
	using EnumerableSet for EnumerableSet.UintSet;
	using SafeERC20 for IERC20;

	enum PoolStatus {
		NOT_CREATED,
		ACTIVE,
		CREATING
	}

	enum DepositStatus {
		NOT_DEPOSITED,
		DEPOSITED,
		PENDING,
		FAILED
	}

	enum WithdrawStatus {
		NOT_WITHDRAWN,
		WITHDRAWN,
		PENDING,
		FAILED
	}

	struct ChainPool {
		address poolAddress;
		address[] poolTokens;
		uint256[] weights;
		bytes32 poolId;
		PoolStatus status;
	}

	struct ChainDeposit {
		DepositStatus status;
		address user;
		uint256 receivedBPT;
		uint256 usdcAmount;
	}

	struct ChainWithdrawal {
		WithdrawStatus status;
		address user;
		uint256 bptAmount;
		uint256 usdcReceived;
	}

	/**
	 * @notice we use 1 as gas limit, because the ccip max gas limit is
	 * still not enough for the creation of the pool. So we need to manually
	 * execute it in the ccip explorer, once it fail for out of gas
	 */
	uint256 private constant CREATE_POOL_GAS_LIMIT = 1;
	uint256 private constant DEPOSIT_GAS_LIMIT = 1_100_000;
	uint256 private constant WITHDRAW_GAS_LIMIT = 1_100_000;
	uint48 private constant ADMIN_TRANSFER_DELAY = 7 days;

	bytes32 public constant TOKENS_MANAGER_ROLE = "TOKENS_MANAGER";

	IRouterClient private immutable i_ccipRouterClient;

	mapping(uint256 chainId => address crossChainPoolManager) private s_chainCrossChainPoolManager;
	mapping(bytes32 depositId => mapping(uint256 chainId => ChainDeposit)) private s_deposits;
	mapping(bytes32 withdrawId => mapping(uint256 chainId => ChainWithdrawal)) private s_withdrawals;
	mapping(uint256 chainId => ChainPool pool) private s_chainPool;
	EnumerableSet.UintSet internal s_chainsSet;
	IERC20 internal immutable i_usdc;

	/// @notice emitted once the Pool for the same chain as the CTF is successfully created.
	event PoolManager__SameChainPoolCreated(bytes32 indexed poolId, address indexed poolAddress, address[] tokens);

	/// @notice emitted once a deposit is made in the same chain is made in the CTF
	event PoolManager__SameChainDeposited(address indexed forUser, bytes32 indexed depositId);

	event PoolManager__SameChainWithdrawn(address indexed forUser, bytes32 indexed withdrawId);

	/// @notice emitted once a cross chain deposit is requested
	event PoolManager__CrossChainDepositRequested(
		bytes32 indexed depositId,
		uint256 indexed chainId,
		address indexed user,
		bytes32 messageId,
		uint256 usdcAmount
	);

	/// @notice emitted once a cross chain withdrawal is requested
	event PoolManager__CrossChainWithdrawRequested(
		bytes32 indexed withdrawId,
		uint256 indexed chainId,
		address indexed user,
		bytes32 messageId,
		uint256 bptAmount
	);

	/// @notice emitted once the CrossChainPoolManager for the given chain is set
	event PoolManager__CrossChainPoolManagerSet(uint256 indexed chainId, address indexed crossChainPoolManager);

	/// @notice emitted once the message to create a pool in another chain is sent
	event PoolManager__CrossChainCreatePoolRequested(
		address indexed crossChainPoolManager,
		bytes32 indexed messageId,
		uint256 indexed chainId,
		address[] tokens,
		string poolName
	);

	/// @notice emitted once the cross chain pool creation receipt is received
	event PoolManager__CrossChainPoolCreated(address indexed poolAddress, bytes32 indexed poolId, uint256 indexed chainId);

	/// @notice emitted once an amount of ETH has been withdrawn from the Pool Manager
	event PoolManager__ETHWithdrawn(uint256 amount);

	/// @notice emitted once the deposits on all pools across all chains have been confirmed
	event PoolManager__AllDepositsConfirmed(bytes32 indexed depositId, address indexed user);

	/// @notice emitted once the withdrawals on all pools across all chains have been confirmed
	event PoolManager__AllWithdrawalsConfirmed(bytes32 indexed withdrawId, address indexed user);

	/// @notice emitted once one Cross Chain Deposit receipt is reived
	event PoolManager__CrossChainDepositConfirmed(uint256 chainId, address indexed user, bytes32 indexed depositId);

	/// @notice emitted once one Cross Chain Withdrawal receipt is reived
	event PoolManager__CrossChainWithdrawalConfirmed(uint256 chainId, address indexed user, bytes32 indexed withdrawId);

	/**
	 * @notice emitted when the Pool Manager receives the Cross Chain Pool not created receipt
	 * from the Cross Chain Pool Manager.
	 *  */
	event PoolManager__FailedToCreateCrossChainPool(uint256 chainId, address crossChainPoolManager);

	/// @notice emitted when the Pool Manager receives the Cross Chain Deposit failed receipt
	event PoolManager__FailedToDeposit(address indexed forUser, bytes32 indexed depositId, uint256 usdcAmount);

	/// @notice thrown if the pool has already been created and the CTF is trying to create it again
	error PoolManager__PoolAlreadyCreated(address poolAddress, uint256 chainId);

	/**
	 * @notice thrown if the CrossChain Pool manager for the given chain have not been found.
	 * it can be due to the missing call to `setCrossChainPoolManager` or actually not existing yet
	 *  */
	error PoolManager__CrossChainPoolManagerNotFound(uint256 chainId);

	/**
	 * @notice thrown if the ccip chain selector for the given chain have not been found.
	 * it can be due to the missing call to `setChainSelector` or actually not existing yet
	 */
	error PoolManager__ChainSelectorNotFound(uint256 chainId);

	/// @notice thrown if the admin tries to add a CrossChainPoolManager for the same chain as the CTF
	error PoolManager__CannotAddCrossChainPoolManagerForTheSameChain();

	/// @notice thrown if the admin tries to add a ccip chain selector for the same chain as the CTF
	error PoolManager__CannotAddChainSelectorForTheSameChain();

	/// @notice thrown if the CrossChainPoolManager for the given chain have already been set
	error PoolManager__CrossChainPoolManagerAlreadySet(address crossChainPoolManager);

	/// @notice thrown if the adming tries to add a CrossChainPoolManager with an invalid address
	error PoolManager__InvalidPoolManager();

	/// @notice thrown if the admin tries to add a ccip chain selector with an invalid value
	error PoolManager__InvalidChainSelector();

	/// @notice thrown if the sender of the Cross Chain Receipt is not a registered Cross Chain Pool Manager
	error PoolManager__InvalidReceiptSender(address sender, address crossChainPoolManager);

	/// @notice thrown when the ETH witdraw fails for some reason
	error PoolManager__FailedToWithdrawETH(bytes data);

	/**
	 * @notice thrown when the chainid passed is not mapped.
	 * @custom:note this is not used in the create pool function, as they will add the chain
	 *  */
	error PoolManager__UnknownChain(uint256 chainId);

	///  @notice thrown when the pool for the given chain is not active yet
	error PoolManager__PoolNotActive(uint256 chainId);

	constructor(
		address balancerManagedPoolFactory,
		address balancerVault,
		address ccipRouterClient,
		address admin
	)
		BalancerPoolManager(balancerManagedPoolFactory, balancerVault)
		AccessControlDefaultAdminRules(ADMIN_TRANSFER_DELAY, admin)
		CCIPReceiver(ccipRouterClient)
	{
		i_ccipRouterClient = IRouterClient(ccipRouterClient);
		s_chainsSet.add(block.chainid);
		i_usdc = IERC20(NetworkHelper._getUSDC());
	}

	receive() external payable {}

	/**
	 * @notice withdraw ETH from the CTF. Only the admin can perform this action
	 * @param amount the amount of ETH to withdraw (with decimals)
	 * @custom:note this only withdraw the ETH used to cover infrastructural costs
	 * it doesn't withdraw users deposited funds
	 *  */
	function withdrawETH(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
		//slither-disable-next-line arbitrary-send-eth
		(bool success, bytes memory data) = defaultAdmin().call{value: amount}("");

		if (!success) revert PoolManager__FailedToWithdrawETH(data);

		emit PoolManager__ETHWithdrawn(amount);
	}

	/**
	 * @notice set the Cross Cross Chain Pool Manager contract for the given chain.
	 * Only the tokens manager can set it.
	 * @param crossChainPoolManager the address of the Cross Chain Pool Manager at the given chain
	 * @param chainId the chain id of the given `crossChainPoolManager` address
	 *  */
	function setCrossChainPoolManager(uint256 chainId, address crossChainPoolManager) external onlyRole(TOKENS_MANAGER_ROLE) {
		address currentCrossChainPoolManager = s_chainCrossChainPoolManager[chainId];

		if (chainId.isCurrent()) revert PoolManager__CannotAddCrossChainPoolManagerForTheSameChain();
		if (crossChainPoolManager == address(0)) revert PoolManager__InvalidPoolManager();
		if (currentCrossChainPoolManager != address(0)) {
			revert PoolManager__CrossChainPoolManagerAlreadySet(currentCrossChainPoolManager);
		}

		s_chainCrossChainPoolManager[chainId] = crossChainPoolManager;

		emit PoolManager__CrossChainPoolManagerSet(chainId, crossChainPoolManager);
	}

	/**
	 * @notice get the chains that the underlying tokens are on
	 * @return chains the array of chains without duplicates
	 *  */
	function getChains() external view returns (uint256[] memory chains) {
		return s_chainsSet.values();
	}

	/**
	 * @notice get the withdrawal info for the given id at the given chain
	 * @return chainWithdrawal the withdrawal info at the given chain
	 * */
	function getWithdrawal(bytes32 withdrawId, uint256 chainId) external view returns (ChainWithdrawal memory chainWithdrawal) {
		return s_withdrawals[withdrawId][chainId];
	}

	/**
	 * @notice get the Cross Chain Pool Manager contract for the given chain
	 * @param chainId the chain id that the Cross Chain Pool Manager contract is on
	 *  */
	function getCrossChainPoolManager(uint256 chainId) external view returns (address) {
		return s_chainCrossChainPoolManager[chainId];
	}

	/**
	 * @notice get the Pool info for the given chain
	 * @param chainId the chain id that the Pool contract is on
	 *  */
	function getChainPool(uint256 chainId) public view returns (ChainPool memory) {
		return s_chainPool[chainId];
	}

	function supportsInterface(bytes4 interfaceId) public pure override(AccessControlDefaultAdminRules, CCIPReceiver) returns (bool) {
		return interfaceId == type(IAccessControlDefaultAdminRules).interfaceId || CCIPReceiver.supportsInterface(interfaceId);
	}

	function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
		RequestReceipt.CrossChainReceipt memory receipt = abi.decode(message.data, (RequestReceipt.CrossChainReceipt));
		address ccipSender = abi.decode(message.sender, (address));
		address crossChainPoolManager = s_chainCrossChainPoolManager[receipt.chainId];

		if (ccipSender != crossChainPoolManager) revert PoolManager__InvalidReceiptSender(ccipSender, crossChainPoolManager);

		if (receipt.receiptType.isSuccess()) {
			RequestReceipt.CrossChainSuccessReceiptType successTypeReceipt = abi.decode(
				receipt.data,
				(RequestReceipt.CrossChainSuccessReceiptType)
			);
			_handleCrossChainSuccessReceipt(receipt.chainId, successTypeReceipt, receipt);
		} else {
			RequestReceipt.CrossChainFailureReceiptType failureTypeReceipt = abi.decode(
				receipt.data,
				(RequestReceipt.CrossChainFailureReceiptType)
			);
			_handleCrossChainFailureReceipt(receipt.chainId, failureTypeReceipt, ccipSender);
		}
	}

	function _onCreatePool(uint256 chainId, address[] memory tokens) internal virtual;

	function _onDeposit(address user, uint256 totalBPTReceived) internal virtual;

	function _onWithdraw(address user, uint256 totalBPTWithdrawn, uint256 totalUSDCToSend) internal virtual;

	function _requestPoolDeposit(
		bytes32 depositId,
		uint256 chainId,
		address swapProvider,
		bytes[] calldata swapsCalldata,
		uint256 minBPTOut,
		uint256 depositUSDCAmount
	) internal {
		if (!s_chainsSet.contains(chainId)) revert PoolManager__UnknownChain(chainId);

		ChainPool memory chainPool = s_chainPool[chainId];

		if (chainPool.status != PoolStatus.ACTIVE) revert PoolManager__PoolNotActive(chainId);

		if (chainId.isCurrent()) {
			_swap(IERC20(i_usdc), depositUSDCAmount, swapProvider, swapsCalldata);
			uint256 bptReceived = _joinPool(chainPool.poolId, minBPTOut);

			s_deposits[depositId][chainId] = ChainDeposit(DepositStatus.DEPOSITED, msg.sender, bptReceived, depositUSDCAmount);
			if (s_chainsSet.length() == 1) _onDeposit(msg.sender, bptReceived);

			emit PoolManager__SameChainDeposited(msg.sender, depositId);
		} else {
			address crossChainPoolManager = s_chainCrossChainPoolManager[chainId];
			uint64 chainSelector = NetworkHelper._getCCIPChainSelector(chainId);

			s_deposits[depositId][chainId] = ChainDeposit(DepositStatus.PENDING, msg.sender, 0, depositUSDCAmount);
			_verifyPoolManagerAndChainSelector(chainId, chainSelector, crossChainPoolManager);

			bytes memory messageData = abi.encode(
				CrossChainRequest.CrossChainRequestType.DEPOSIT,
				CrossChainRequest.CrossChainDepositRequest({
					depositId: depositId,
					poolId: chainPool.poolId,
					minBPTOut: minBPTOut,
					swapProvider: swapProvider,
					swapsCalldata: swapsCalldata
				})
			);

			bytes32 messageId;

			// we use scopes here because somehow stack too deep error is being thrown
			{
				(Client.EVM2AnyMessage memory message, uint256 fee) = _buildCrossChainMessage(
					chainId,
					DEPOSIT_GAS_LIMIT,
					depositUSDCAmount,
					messageData
				);

				i_usdc.forceApprove(address(i_ccipRouterClient), depositUSDCAmount);
				messageId = i_ccipRouterClient.ccipSend{value: fee}(chainSelector, message);
			}

			emit PoolManager__CrossChainDepositRequested(depositId, chainId, msg.sender, messageId, depositUSDCAmount);
		}
	}

	function _requestPoolWithdrawal(
		bytes32 withdrawId,
		uint256 bptAmountIn,
		uint256 chainId,
		address swapProvider,
		uint256 exitTokenIndex,
		uint256 exitTokenMinAmountOut,
		bytes calldata swapData
	) internal {
		if (!s_chainsSet.contains(chainId)) revert PoolManager__UnknownChain(chainId);

		ChainPool memory chainPool = s_chainPool[chainId];
		bytes[] memory swapsCalldata = new bytes[](1);
		swapsCalldata[0] = swapData;

		if (chainId.isCurrent()) {
			(uint256 exitTokenAmountOut, IERC20 exitToken) = _exitPool(chainPool.poolId, bptAmountIn, exitTokenMinAmountOut, exitTokenIndex);

			uint256 usdcReceived = _swapUSDCOut(exitToken, i_usdc, exitTokenAmountOut, swapProvider, swapsCalldata);
			s_withdrawals[withdrawId][chainId] = ChainWithdrawal(WithdrawStatus.WITHDRAWN, msg.sender, bptAmountIn, usdcReceived);

			if (s_chainsSet.length() == 1) _onWithdraw({user: msg.sender, totalBPTWithdrawn: bptAmountIn, totalUSDCToSend: usdcReceived});

			emit PoolManager__SameChainWithdrawn(msg.sender, withdrawId);
		} else {
			address crossChainPoolManager = s_chainCrossChainPoolManager[chainId];
			uint64 chainSelector = NetworkHelper._getCCIPChainSelector(chainId);

			s_withdrawals[withdrawId][chainId] = ChainWithdrawal(WithdrawStatus.PENDING, msg.sender, bptAmountIn, 0);
			_verifyPoolManagerAndChainSelector(chainId, chainSelector, crossChainPoolManager);

			bytes memory messageData = abi.encode(
				CrossChainRequest.CrossChainRequestType.WITHDRAW,
				CrossChainRequest.CrossChainWithdrawRequest({
					withdrawalId: withdrawId,
					poolId: chainPool.poolId,
					bptAmountIn: bptAmountIn,
					exitTokenIndex: exitTokenIndex,
					exitTokenMinAmountOut: exitTokenMinAmountOut,
					swapProvider: swapProvider,
					swapCalldata: swapData
				})
			);

			(Client.EVM2AnyMessage memory message, uint256 fee) = _buildCrossChainMessage(chainId, WITHDRAW_GAS_LIMIT, 0, messageData);
			bytes32 messageId = i_ccipRouterClient.ccipSend{value: fee}(chainSelector, message);

			emit PoolManager__CrossChainWithdrawRequested(withdrawId, chainId, msg.sender, messageId, bptAmountIn);
		}
	}

	/**
	 * @notice Create a new pool with the given Tokens for the given chain
	 * @param chainId the chain that the pool will be created on
	 * @param tokens the tokens that will be added to the pool
	 */
	function _requestNewPoolCreation(uint256 chainId, string memory poolName, address[] memory tokens) internal {
		ChainPool memory chainPool = s_chainPool[chainId];

		// sort the tokens in ascending order
		// balancer requires the tokens in ascending order
		tokens = Arrays.sort(tokens);

		if (chainPool.status != PoolStatus.NOT_CREATED) revert PoolManager__PoolAlreadyCreated(chainPool.poolAddress, chainId);

		if (chainId.isCurrent()) {
			//slither-disable-next-line reentrancy-no-eth
			(address poolAddress, bytes32 poolId, uint256[] memory weights) = _createPool(poolName, chainId.toString(), tokens.toIERC20List());

			s_chainPool[chainId] = ChainPool({
				poolAddress: poolAddress,
				poolId: poolId,
				poolTokens: tokens,
				status: PoolStatus.ACTIVE,
				weights: weights
			});

			_onCreatePool(chainId, tokens);

			emit PoolManager__SameChainPoolCreated(poolId, poolAddress, tokens);
		} else {
			s_chainPool[chainId].status = PoolStatus.CREATING;
			address crossChainPoolManager = s_chainCrossChainPoolManager[chainId];
			uint64 chainSelector = NetworkHelper._getCCIPChainSelector(chainId);

			if (crossChainPoolManager == address(0)) revert PoolManager__CrossChainPoolManagerNotFound(chainId);
			if (chainSelector == 0) revert PoolManager__ChainSelectorNotFound(chainId);

			bytes memory messageData = abi.encode(
				CrossChainRequest.CrossChainRequestType.CREATE_POOL,
				CrossChainRequest.CrossChainCreatePoolRequest({tokens: tokens, poolName: poolName})
			);

			(Client.EVM2AnyMessage memory message, uint256 fee) = _buildCrossChainMessage(chainId, CREATE_POOL_GAS_LIMIT, 0, messageData);
			//slither-disable-next-line arbitrary-send-eth
			bytes32 messageId = i_ccipRouterClient.ccipSend{value: fee}(chainSelector, message);

			emit PoolManager__CrossChainCreatePoolRequested(crossChainPoolManager, messageId, chainId, tokens, poolName);
		}
	}

	function _handleCrossChainSuccessReceipt(
		uint256 chainId,
		RequestReceipt.CrossChainSuccessReceiptType successTypeReceipt,
		RequestReceipt.CrossChainReceipt memory receipt
	) private {
		if (successTypeReceipt.isPoolCreated()) {
			(, RequestReceipt.CrossChainPoolCreatedReceipt memory receiptPoolCreated) = abi.decode(
				receipt.data,
				(RequestReceipt.CrossChainSuccessReceiptType, RequestReceipt.CrossChainPoolCreatedReceipt)
			);

			return _handleCrossChainPoolCreatedReceipt(chainId, receiptPoolCreated);
		}

		if (successTypeReceipt.isDeposited()) {
			(, RequestReceipt.CrossChainDepositedReceipt memory receiptDeposited) = abi.decode(
				receipt.data,
				(RequestReceipt.CrossChainSuccessReceiptType, RequestReceipt.CrossChainDepositedReceipt)
			);

			return _handleCrossChainDepositedReceipt(chainId, receiptDeposited);
		}

		if (successTypeReceipt.isWithdrawn()) {
			(, RequestReceipt.CrossChainWithdrawReceipt memory receiptWithdrawn) = abi.decode(
				receipt.data,
				(RequestReceipt.CrossChainSuccessReceiptType, RequestReceipt.CrossChainWithdrawReceipt)
			);

			return _handleCrossChainWithdrawReceipt(chainId, receiptWithdrawn);
		}
	}

	function _handleCrossChainFailureReceipt(
		uint256 chainId,
		RequestReceipt.CrossChainFailureReceiptType failureTypeReceipt,
		address sender
	) private {
		if (failureTypeReceipt.isPoolNotCreated()) {
			emit PoolManager__FailedToCreateCrossChainPool(chainId, sender);
			return;
		}
	}

	function _handleCrossChainPoolCreatedReceipt(uint256 chainId, RequestReceipt.CrossChainPoolCreatedReceipt memory receipt) private {
		ChainPool memory chainPool = s_chainPool[chainId];
		if (chainPool.status == PoolStatus.ACTIVE) revert PoolManager__PoolAlreadyCreated(chainPool.poolAddress, chainId);

		s_chainsSet.add(chainId);
		s_chainPool[chainId] = ChainPool({
			status: PoolStatus.ACTIVE,
			poolAddress: receipt.poolAddress,
			poolId: receipt.poolId,
			poolTokens: receipt.tokens,
			weights: receipt.weights
		});

		_onCreatePool(chainId, receipt.tokens);

		emit PoolManager__CrossChainPoolCreated(receipt.poolAddress, receipt.poolId, chainId);
	}

	function _handleCrossChainDepositedReceipt(uint256 chainId, RequestReceipt.CrossChainDepositedReceipt memory receipt) private {
		uint256 chains = s_chainsSet.length();
		uint256 confirmedDeposits = 0;
		uint256 totalReceivedBpt = 0;
		address user = s_deposits[receipt.depositId][chainId].user;

		s_deposits[receipt.depositId][chainId].status = DepositStatus.DEPOSITED;
		s_deposits[receipt.depositId][chainId].receivedBPT = receipt.receivedBPT;

		for (uint256 i = 0; i < chains; ) {
			ChainDeposit memory chainDeposit = s_deposits[receipt.depositId][s_chainsSet.at(i)];

			if (chainDeposit.status == DepositStatus.DEPOSITED) {
				++confirmedDeposits;
				totalReceivedBpt += chainDeposit.receivedBPT;
			}

			unchecked {
				++i;
			}
		}

		if (chains == confirmedDeposits) {
			emit PoolManager__AllDepositsConfirmed(receipt.depositId, user);

			_onDeposit(user, totalReceivedBpt);
		} else {
			emit PoolManager__CrossChainDepositConfirmed(chainId, user, receipt.depositId);
		}
	}

	function _handleCrossChainWithdrawReceipt(uint256 chainId, RequestReceipt.CrossChainWithdrawReceipt memory receipt) private {
		uint256 chains = s_chainsSet.length();
		uint256 confirmedWithdrawals = 0;
		uint256 totalReceivedUSDC = 0;
		uint256 ctfAmountToBurn = 0;
		address user = s_withdrawals[receipt.withdrawId][chainId].user;

		s_withdrawals[receipt.withdrawId][chainId].status = WithdrawStatus.WITHDRAWN;
		s_withdrawals[receipt.withdrawId][chainId].usdcReceived = receipt.receivedUSDC;

		for (uint256 i = 1; i < chains; ) {
			ChainWithdrawal memory chainWithdrawal = s_withdrawals[receipt.withdrawId][s_chainsSet.at(i)];
			if (chainWithdrawal.status == WithdrawStatus.WITHDRAWN) {
				++confirmedWithdrawals;
				totalReceivedUSDC += chainWithdrawal.usdcReceived;
				ctfAmountToBurn += chainWithdrawal.bptAmount;
			}

			unchecked {
				++i;
			}
		}

		if (chains == confirmedWithdrawals) {
			emit PoolManager__AllWithdrawalsConfirmed(receipt.withdrawId, user);
			_onWithdraw({user: user, totalBPTWithdrawn: totalReceivedUSDC, totalUSDCToSend: totalReceivedUSDC});
		} else {
			emit PoolManager__CrossChainWithdrawalConfirmed(chainId, user, receipt.withdrawId);
		}
	}

	/**
	 * @dev build CCIP Message to send to another chain
	 * @param chainId the chain that the CrossChainPoolManager is in
	 * @param gasLimit the gas limit for the transaction in the other chain
	 * @param usdcAmount the amount of USDC to send, if zero, no usdc will be sent
	 * @param data the encoded data to pass to the CrossChainPoolManager
	 * @return message the CCIP Message to be sent
	 * @return fee the ccip fee to send this message, note that the fee will be in ETH
	 */
	function _buildCrossChainMessage(
		uint256 chainId,
		uint256 gasLimit,
		uint256 usdcAmount,
		bytes memory data
	) private view returns (Client.EVM2AnyMessage memory message, uint256 fee) {
		Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);

		if (usdcAmount != 0) {
			tokenAmounts = new Client.EVMTokenAmount[](1);
			tokenAmounts[0] = Client.EVMTokenAmount({token: address(i_usdc), amount: usdcAmount});
		}

		message = Client.EVM2AnyMessage({
			receiver: abi.encode(s_chainCrossChainPoolManager[chainId]),
			data: data,
			tokenAmounts: tokenAmounts,
			feeToken: address(0),
			extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: gasLimit}))
		});

		fee = i_ccipRouterClient.getFee(NetworkHelper._getCCIPChainSelector(chainId), message);

		return (message, fee);
	}

	function _verifyPoolManagerAndChainSelector(uint256 chainId, uint256 chainSelector, address crossChainPoolManager) private pure {
		if (crossChainPoolManager == address(0)) revert PoolManager__CrossChainPoolManagerNotFound(chainId);
		if (chainSelector == 0) revert PoolManager__ChainSelectorNotFound(chainId);
	}
}
