// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeChain} from "src/libraries/SafeChain.sol";
import {BalancerPoolManager} from "src/contracts/BalancerPoolManager.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IRouterClient, Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {CrossChainRequestType} from "src/types/CrossChainRequestType.sol";
import {CrossChainCreatePoolRequest} from "src/types/CrossChainCreatePoolRequest.sol";
import {CustomCast} from "src/libraries/CustomCast.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {RequestReceipt} from "src/libraries/RequestReceipt.sol";
import {SafeCrossChainReceipt} from "src/libraries/SafeCrossChainReceipt.sol";

abstract contract PoolManager is CCIPReceiver, AccessControlDefaultAdminRules, BalancerPoolManager {
	using SafeChain for uint256;
	using Strings for uint256;
	using CustomCast for address[];
	using SafeCrossChainReceipt for RequestReceipt.CrossChainReceiptType;
	using SafeCrossChainReceipt for RequestReceipt.CrossChainSuccessReceiptType;

	enum PoolStatus {
		NOT_CREATED,
		ACTIVE,
		CREATING
	}

	struct ChainPool {
		address poolAddress;
		address[] poolTokens;
		bytes32 poolId;
		PoolStatus status;
	}

	uint48 private constant ADMIN_TRANSFER_DELAY = 7 days;
	bytes32 public constant TOKENS_MANAGER_ROLE = "TOKENS_MANAGER";

	IRouterClient private immutable i_ccipRouterClient;

	mapping(uint256 chainId => uint64 chainSelector) private s_chainSelector;
	mapping(uint256 chainId => address crossChainPoolManager) private s_chainCrossChainPoolManager;
	mapping(uint256 chainId => ChainPool pool) private s_chainPool;

	/// @notice emitted once the Pool for the same chain as the CTF is successfully created.
	event PoolManager__SameChainPoolCreated(bytes32 indexed poolId, address indexed poolAddress, address[] tokens);

	/// @notice emitted once the CrossChainPoolManager for the given chain is set
	event PoolManager__CrossChainPoolManagerSet(uint256 indexed chainId, address indexed crossChainPoolManager);

	/// @notice emitted once the ccip chain selector for the given chain is set
	event PoolManager__ChainSelectorSet(uint256 indexed chainId, uint64 indexed chainSelector);

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
	}

	/**
	 * @notice set the Cross Cross Chain Pool Manager contract for the given chain.
	 * Only the admin can set it.
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
	 * @notice set the ccip chain selector for the given chain.
	 * Only the admin can set it.
	 * @param chainSelector the ccip chain selector for the given chain
	 * @param chainId the chain id of the given `chainSelector`
	 *  */
	function setChainSelector(uint256 chainId, uint64 chainSelector) external onlyRole(TOKENS_MANAGER_ROLE) {
		if (chainId.isCurrent()) revert PoolManager__CannotAddChainSelectorForTheSameChain();
		if (chainSelector == 0) revert PoolManager__InvalidChainSelector();

		s_chainSelector[chainId] = chainSelector;

		emit PoolManager__ChainSelectorSet(chainId, chainSelector);
	}

	/**
	 * @notice get the Cross Chain Pool Manager contract for the given chain
	 * @param chainId the chain id that the Cross Chain Pool Manager contract is in
	 *  */
	function getCrossChainPoolManager(uint256 chainId) external view returns (address) {
		return s_chainCrossChainPoolManager[chainId];
	}

	/**
	 * @notice get the ccip chain selector for the given chain
	 * @param chainId the chain id that the ccip chain selector is for
	 *  */
	function getChainSelector(uint256 chainId) external view returns (uint64) {
		return s_chainSelector[chainId];
	}

	/**
	 * @notice get the Pool info for the given chain
	 * @param chainId the chain id that the Pool contract is in
	 *  */
	function getChainPool(uint256 chainId) external view returns (ChainPool memory) {
		return s_chainPool[chainId];
	}

	function supportsInterface(bytes4 interfaceId) public view override(AccessControlDefaultAdminRules, CCIPReceiver) returns (bool) {
		return AccessControlDefaultAdminRules.supportsInterface(interfaceId) || CCIPReceiver.supportsInterface(interfaceId);
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
		}
	}

	function _onCreatePool(uint256 chainId, address[] memory tokens) internal virtual;

	/**
	 * @notice Create a new pool with the given Tokens for the given chain
	 * @param chainId the chain that the pool will be created on
	 * @param tokens the tokens that will be added to the pool
	 */
	function _requestNewPoolCreation(uint256 chainId, string memory poolName, address[] memory tokens) internal {
		ChainPool memory chainPool = s_chainPool[chainId];

		if (chainPool.status != PoolStatus.NOT_CREATED) revert PoolManager__PoolAlreadyCreated(chainPool.poolAddress, chainId);

		if (chainId.isCurrent()) {
			s_chainPool[chainId].poolTokens = tokens;
			s_chainPool[chainId].status = PoolStatus.ACTIVE;

			(address poolAddress, bytes32 poolId) = _createPool(poolName, chainId.toString(), tokens.toIERC20List());

			//slither-disable-start reentrancy-no-eth
			s_chainPool[chainId].poolAddress = poolAddress;
			s_chainPool[chainId].poolId = poolId;
			//slither-disable-end reentrancy-no-eth

			_onCreatePool(chainId, tokens);

			emit PoolManager__SameChainPoolCreated(poolId, poolAddress, tokens);
		} else {
			s_chainPool[chainId].status = PoolStatus.CREATING;
			address crossChainPoolManager = s_chainCrossChainPoolManager[chainId];
			uint64 chainSelector = s_chainSelector[chainId];

			if (crossChainPoolManager == address(0)) revert PoolManager__CrossChainPoolManagerNotFound(chainId);
			if (chainSelector == 0) revert PoolManager__ChainSelectorNotFound(chainId);

			bytes memory messageData = abi.encode(
				CrossChainRequestType.CREATE_POOL,
				CrossChainCreatePoolRequest({tokens: tokens, poolName: poolName})
			);

			(Client.EVM2AnyMessage memory message, uint256 fee) = _buildCrossChainMessage(chainId, messageData);
			//slither-disable-next-line arbitrary-send-eth
			bytes32 messageId = i_ccipRouterClient.ccipSend{value: fee}(chainSelector, message);

			emit PoolManager__CrossChainCreatePoolRequested(crossChainPoolManager, messageId, chainId, tokens, poolName);
		}
	}

	/**
	 * @notice Add the given token to an existing pool at the given chain
	 * @param chainId the chain that the pool is in
	 * @param token the token that will be added to the pool
	 * @param pool the pool that the token will be added to
	 */
	function _requestTokenAddition(uint256 chainId, address token, address pool) internal {
		ChainPool memory chainPool = s_chainPool[chainId];

		if (chainId.isCurrent()) {} else {}
	}

	/**
	 * @notice Batch token add for the given pool at the given chain
	 * @param chainId the chain that the pool is in
	 * @param tokens the tokens that will be added to the pool
	 * @param pool the pool that the token will be added to
	 */
	function _requestBatchTokenAddition(uint256 chainId, address[] memory tokens, address pool) internal {
		ChainPool memory chainPool = s_chainPool[chainId];

		if (chainId.isCurrent()) {} else {}
	}

	function _getPool(uint256 chainId) internal view returns (ChainPool memory pool) {
		return s_chainPool[chainId];
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

			_handleCrossChainPoolCreatedReceipt(chainId, receiptPoolCreated);
		}
	}

	function _handleCrossChainPoolCreatedReceipt(uint256 chainId, RequestReceipt.CrossChainPoolCreatedReceipt memory receipt) private {
		ChainPool memory chainPool = s_chainPool[chainId];
		if (chainPool.status == PoolStatus.ACTIVE) revert PoolManager__PoolAlreadyCreated(chainPool.poolAddress, chainId);

		s_chainPool[chainId] = ChainPool({
			status: PoolStatus.ACTIVE,
			poolAddress: receipt.poolAddress,
			poolId: receipt.poolId,
			poolTokens: receipt.tokens
		});

		_onCreatePool(chainId, receipt.tokens);

		emit PoolManager__CrossChainPoolCreated(receipt.poolAddress, receipt.poolId, chainId);
	}

	function _buildCrossChainMessage(
		uint256 chainId,
		bytes memory data
	) private view returns (Client.EVM2AnyMessage memory message, uint256 fee) {
		message = Client.EVM2AnyMessage({
			receiver: abi.encode(s_chainCrossChainPoolManager[chainId]),
			data: data,
			tokenAmounts: new Client.EVMTokenAmount[](0),
			feeToken: address(0),
			extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: /*TODO: check gas limit*/ 3_000_000}))
		});

		fee = i_ccipRouterClient.getFee(s_chainSelector[chainId], message);

		return (message, fee);
	}
}
