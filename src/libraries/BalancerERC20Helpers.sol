// SPDX-License-Identifier: GPL-3.0-or-later
// some functions in this file have been taken from Balancer's ERC20Helpers.sol file
// https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/helpers/ERC20Helpers.sol#L1
// This file is to adapt their code to work with the 0.8.25 solc version (our project is using solc 0.8.25)
// Balancer functions: `asIAsset(IERC20[])`

pragma solidity 0.8.25;

import {IERC20} from "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import {IAsset} from "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";
// solhint-disable chainlink-solidity/prefix-internal-functions-with-underscore
library BalancerERC20Helpers {
	function asIAsset(IERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
		// solhint-disable-next-line no-inline-assembly
		assembly {
			assets := tokens
		}
	}
}
