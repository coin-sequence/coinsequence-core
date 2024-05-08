// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IRouterClient, Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {ICSEngine, CSDeposit, ICTF} from "src/interfaces/ICSEngine.sol";
import {SafeChain} from "src/libraries/SafeChain.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICSManager} from "src/interfaces/ICSManager.sol";
import {CSExecutor} from "src/contracts/CSExecutor.sol";
import {CSRouterDepositRequest} from "src/types/CSRouterDepositRequest.sol";

contract CSEngine is ICSEngine, CSExecutor {
	using SafeChain for uint256;
	using SafeERC20 for IERC20;

	IERC20 private immutable i_usdc;
	ICSManager private immutable i_csManager;
	IRouterClient private immutable i_ccipRouterClient;

	constructor(
		address usdc,
		address balancerVault,
		address ccipRouterClient,
		address csManager
	) CSExecutor(balancerVault, usdc) {
		i_usdc = IERC20(usdc);
		i_csManager = ICSManager(csManager);
		i_ccipRouterClient = IRouterClient(ccipRouterClient);
	}

	/// @inheritdoc ICSEngine
	function deposit(
		uint256 totalUSDCAmount,
		address router,
		ICTF targetCTF,
		CSDeposit[] calldata deposits
	) external payable override {
		if (router == address(0) || router.code.length == 0) revert CSEngine__InvalidCSRouter();

		uint256 ctfChainsLength = targetCTF.underlyingTokensChains().length;

		if (deposits.length > 1) {
			uint256 totalCCIPFee = calculateTotalCCIPDepositFee(targetCTF, router, deposits);
			if (msg.value < totalCCIPFee) revert CSEngine__CannotPayFees(msg.value, totalCCIPFee);
		}
		if (!i_csManager.isCTFLegit(address(targetCTF))) revert CSEngine__CtfIsNotLegit(address(targetCTF));
		if (deposits.length != ctfChainsLength) revert CSEngine__DepositsLengthMismatch(deposits.length, ctfChainsLength);

		i_usdc.safeTransferFrom(msg.sender, address(this), totalUSDCAmount);

		for (uint256 i = 0; i < deposits.length; ) {
			CSDeposit calldata networkDeposit = deposits[i];
			_verifyDepositData(networkDeposit);

			//slither-disable-next-line calls-loop
			ICTF.NetworkInfo memory networkInfo = targetCTF.getNetworkInfo(networkDeposit.chainId);

			bytes32 poolId = networkInfo.poolId;

			if (networkDeposit.chainId.isCurrent()) {
				uint256 bptReceivedAmount = _swapAndDepositToBalancer({
					poolId: networkInfo.poolId,
					usdcAmount: networkDeposit.usdcAmount,
					swapsData: networkDeposit.swapsData,
					swapProvider: networkDeposit.swapProvider,
					minBPTOut: networkDeposit.minBPTOut
				});

				IERC20(networkInfo.pool).forceApprove(address(targetCTF), bptReceivedAmount);
				targetCTF.mint(msg.sender, bptReceivedAmount);

				emit CSEngine_DepositedToCurrentNetwork(
					address(targetCTF),
					poolId,
					networkDeposit.usdcAmount,
					bptReceivedAmount
				);
			} else {
				Client.EVM2AnyMessage memory ccipMessage = _buildCCIPMessageForDeposit(
					networkDeposit,
					router,
					targetCTF,
					poolId
				);

				uint256 ccipFee = i_ccipRouterClient.getFee(networkInfo.chainSelector, ccipMessage);
				//slither-disable-next-line arbitrary-send-eth
				bytes32 messageId = i_ccipRouterClient.ccipSend{value: ccipFee}(networkInfo.chainSelector, ccipMessage);

				emit CSEngine_sentCrossChainDepositRequest(
					address(targetCTF),
					poolId,
					networkDeposit.chainId,
					messageId,
					networkInfo.chainSelector,
					networkDeposit.usdcAmount
				);
			}

			// We use unchecked here to save gas as its impossible to overflow.
			// Each item of the array is one network, no way to have 2^256+ networks :)
			unchecked {
				++i;
			}
		}
	}

	function withdraw() external override {}

	/// @inheritdoc ICSEngine
	function calculateTotalCCIPDepositFee(
		ICTF targetCTF,
		address router,
		CSDeposit[] calldata deposits
	) public view override returns (uint256) {
		uint256 totalFee;

		for (uint256 i = 0; i < deposits.length; ) {
			CSDeposit calldata networkDeposit = deposits[i];
			ICTF.NetworkInfo memory networkInfo = targetCTF.getNetworkInfo(networkDeposit.chainId);

			Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
			tokenAmounts[0] = Client.EVMTokenAmount({token: address(i_usdc), amount: networkDeposit.usdcAmount});

			totalFee += i_ccipRouterClient.getFee(
				targetCTF.getNetworkInfo(networkDeposit.chainId).chainSelector,
				_buildCCIPMessageForDeposit(networkDeposit, router, targetCTF, networkInfo.poolId)
			);

			// We use unchecked here to save gas as its impossible to overflow.
			// Each item of the array is one network, no way to have 2^256+ networks :)
			unchecked {
				++i;
			}
		}

		return totalFee;
	}

	/// @dev we do not verify the minBPTOut here as the CSBalancerPoolManager already do it
	function _verifyDepositData(CSDeposit calldata networkDeposit) private view {
		if (networkDeposit.chainId == 0) revert CSEngine__ChainIdIsZero();
		if (networkDeposit.swapsData.length == 0) revert CSEngine__SwapDataIsEmpty();
		if (networkDeposit.swapProvider == address(0)) revert CSEngine__InvalidSwapProvider();
		if (networkDeposit.swapProvider.code.length == 0) revert CSEngine__InvalidSwapProvider();
		if (networkDeposit.usdcAmount == 0) revert CSEngine__SwapAmountIsZero();
	}

	function _buildCCIPMessageForDeposit(
		CSDeposit calldata _deposit,
		address router,
		ICTF targetCTF,
		bytes32 poolId
	) private view returns (Client.EVM2AnyMessage memory ccipMessage) {
		Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
		tokenAmounts[0] = Client.EVMTokenAmount({token: address(i_usdc), amount: _deposit.usdcAmount});

		CSRouterDepositRequest memory data = CSRouterDepositRequest({
			targetCTF: targetCTF,
			ogDeposit: _deposit,
			user: msg.sender,
			poolId: poolId
		});

		return
			Client.EVM2AnyMessage({
				receiver: abi.encode(router),
				data: abi.encode(data),
				tokenAmounts: tokenAmounts,
				feeToken: address(0),
				extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: /* TODO: check gasLimit */ 3_000_000}))
			});
	}
}
