// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICTF} from "src/interfaces/ICTF.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CCIPReceiver, Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

contract CTF is ICTF, ERC20, CCIPReceiver {
	constructor(
		string memory name,
		string memory symbol,
		address ccipRouter
	) ERC20(name, symbol) CCIPReceiver(ccipRouter) {}

	function mint(address to, uint256 amount) external override {
		// Analyze if the CTF is cross chain, if it's, wait for confirmation received from the other chains
		// TODO: Transfer BPT from the sender to this, and then mint the amount
		_mint(to, amount);
	}

	function getNetworkInfo(uint256 chainId) external view override returns (NetworkInfo memory networkInfo) {}

	function underlyingTokensChains() external view override returns (uint256[] memory) {}

	function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {}
}
