// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ICTF} from "src/interfaces/ICTF.sol";

contract CTF is ERC20, ICTF {
	// address private immutable i_engine;
	address[] private s_underlyingTokens;

	constructor(
		string memory _name,
		string memory _symbol,
		// address engine,
		address[] memory underlyingTokens
	) ERC20(_name, _symbol) {
		// i_engine = engine;
		s_underlyingTokens = underlyingTokens;
	}

	/// @inheritdoc ICTF
	function mint(uint256 mintAmount, address to) external override {
		_mint(to, mintAmount);
	}

	/// @inheritdoc ICTF
	function getUnderlyingTokens() external view override returns (address[] memory) {
		return s_underlyingTokens;
	}
}
