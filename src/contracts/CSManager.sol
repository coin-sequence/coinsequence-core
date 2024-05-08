// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ICSManager} from "src/interfaces/ICSManager.sol";
import {CSFactory, EnumerableSet} from "src/contracts/CSFactory.sol";

contract CSManager is CSFactory, ICSManager {
	using EnumerableSet for EnumerableSet.AddressSet;

	constructor(address balancerManagedPoolFactoryV2) CSFactory(balancerManagedPoolFactoryV2) {}

	/// @inheritdoc ICSManager
	function isCTFLegit(address ctf) external view override returns (bool) {
		return s_createdCTFs.contains(ctf);
	}
}
