// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @notice Required Params for depositing into the CTF.
 * @param usdcAmount the amount of USDC to deposit for the given network.
 * @param swapsData the data for the swap from USDC to balancer pool tokens, for the given network.
 * @param chainId the id of the network to perform the actions.
 * @param swapProvider the address of the contract which will be performing the swaps for the given network.
 */
struct CSDeposit {
	uint256 usdcAmount;
	bytes[] swapsData;
	uint256 chainId;
	address swapProvider;
}
