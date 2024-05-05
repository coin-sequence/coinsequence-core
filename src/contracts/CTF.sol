// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICTF} from "src/interfaces/ICTF.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CTF is ICTF, ERC20 {
	constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

	function getPoolId() external override returns (bytes32) {}
}
