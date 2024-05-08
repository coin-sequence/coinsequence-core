// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICSFactory, ICTF} from "src/interfaces/ICSFactory.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IBalancerManagedPoolFactoryV2} from "src/interfaces/IBalancerManagedPoolFactoryV2.sol";

abstract contract CSFactory is ICSFactory {
	using EnumerableSet for EnumerableSet.AddressSet;

	EnumerableSet.AddressSet internal s_createdCTFs;
	IBalancerManagedPoolFactoryV2 private immutable i_balancerManagedPoolFactoryV2;

	constructor(address balancerManagedPoolFactoryV2) {
		i_balancerManagedPoolFactoryV2 = IBalancerManagedPoolFactoryV2(balancerManagedPoolFactoryV2);
	}

	/// @inheritdoc ICSFactory
	function createCTF(
		UnderlyingToken[] calldata underlyingTokens,
		string calldata name,
		string calldata symbol
	) external override returns (ICTF) {
		for (uint256 i = 0; i < underlyingTokens.length; ) {
			UnderlyingToken memory token = underlyingTokens[i];
			// token.chainId

			unchecked {
				i++;
			}
		}

		// IBalancerManagedPoolFactoryV2.ManagedPoolParams memory balancerManagedPoolParams = IBalancerManagedPoolFactoryV2
		// 	.ManagedPoolParams({name: name, symbol: symbol, assetManagers: new address[]()});

		// IBalancerManagedPoolFactoryV2.ManagedPoolSettingsParams memory balancerSettingsParams = IBalancerManagedPoolFactoryV2.ManagedPoolSettingsParams(
		// IERC20[] tokens;
		// uint256[] normalizedWeights;
		// uint256 swapFeePercentage;
		// bool swapEnabledOnStart;
		// bool mustAllowlistLPs;
		// uint256 managementAumFeePercentage;
		// uint256 aumFeeId;
		// )

		// i_balancerManagedPoolFactoryV2.create(managedPoolParams, settingsParams, address(this), salt);
	}
}
