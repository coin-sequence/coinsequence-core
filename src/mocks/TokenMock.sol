// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenMock is ERC20 {
	constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

	function mint(address account, uint256 value) external {
		_mint(account, value);
	}
}
