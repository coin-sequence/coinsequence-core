// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICTF} from "src/interfaces/ICTF.sol";

interface ICSFactory {
	/// @param token address of the token undelying token
	/// @param chainId the chain id that the token is deployed on
	struct UnderlyingToken {
		address token;
		uint256 chainId;
	}

	/// @notice create a new CTF
	/// @param underlyingTokens the list of underlying tokens that the CTF will start with
	/// @param name the name of the CTF ERC20
	/// @param symbol the symbol of the CTF ERC20
	/// @return ctf the created CTF address
	function createCTF(
		UnderlyingToken[] memory underlyingTokens,
		string calldata name,
		string calldata symbol
	) external returns (ICTF ctf);
}
