// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {Engine} from "src/contracts/Engine.sol";
import {NetworkHelper} from "script/helpers/NetworkHelper.sol";

contract DeployEngine is Script {
	function run() external returns (Engine) {
		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper.getNetworkConfig();
		string memory functionsDepositSource = vm.readFile("./functions/deposit.js");

		vm.startBroadcast();
		Engine engine = new Engine(
			networkConfig.functionsRouter,
			networkConfig.functionsSubscriptionId,
			networkConfig.functionsCallbackGasLimit,
			networkConfig.functionsDonId,
			functionsDepositSource,
			address(1) // TODO: Change this address to the real admin wallet
		);
		vm.stopBroadcast();

		return engine;
	}
}
