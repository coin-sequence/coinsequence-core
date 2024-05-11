// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library CustomCast {
	/**
	 * @notice converts an address list to an IERC20 list
	 * @dev take care when using this function, as it does not check if the
	 * address is a valid IERC20(OpenZeppelin version), it just converts
	 * the address to the IERC20 type
	 *  */
	function toIERC20List(address[] memory tokens) internal pure returns (IERC20[] memory tokensAsIERC20) {
		// solhint-disable-next-line no-inline-assembly
		assembly {
			tokensAsIERC20 := tokens
		}
	}
}
