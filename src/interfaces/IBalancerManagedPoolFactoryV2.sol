// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the Balancer Managed Pool Factory.
 * As they don't provide an Interface for it, We've created one
 * to not rely on low-level calls.
 *
 * If you want to see the full implementation, please check their github:
 * https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/pool-weighted/contracts/managed/ManagedPoolFactory.sol
 *
 * */
interface IBalancerManagedPoolFactoryV2 {
	struct ManagedPoolParams {
		string name;
		string symbol;
		address[] assetManagers;
	}

	struct ManagedPoolSettingsParams {
		IERC20[] tokens;
		uint256[] normalizedWeights;
		uint256 swapFeePercentage;
		bool swapEnabledOnStart;
		bool mustAllowlistLPs;
		uint256 managementAumFeePercentage;
		uint256 aumFeeId;
	}

	function create(
		ManagedPoolParams memory params,
		ManagedPoolSettingsParams memory settingsParams,
		address owner,
		bytes32 salt
	) external returns (address pool);
}
