// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test} from "forge-std/Test.sol";
import {Engine} from "src/contracts/Engine.sol";
import {NetworkHelper} from "script/helpers/NetworkHelper.sol";
import {FunctionsRequestParams} from "src/types/FunctionsRequestParams.sol";
import {DeployEngine} from "script/DeployEngine.s.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";

contract DeployEngineUnitTest is Test {
	function test_deployEngine_useCorrectFunctionsParams() external {
		NetworkHelper.NetworkConfig memory networkConfig = NetworkHelper.getNetworkConfig();
		Engine engine = new DeployEngine().run();

		FunctionsRequestParams memory functionsParams = engine.getFunctionsRequestParams();

		assertEq(
			functionsParams.subscriptionId,
			networkConfig.functionsSubscriptionId,
			"Functions subscription ID does not match"
		);
		assertEq(
			functionsParams.callbackGasLimit,
			networkConfig.functionsCallbackGasLimit,
			"Functions callback gas limit does not match"
		);
		assertEq(functionsParams.donId, networkConfig.functionsDonId, "Functions DON ID does not match");
	}

	function test_deployEngine_setRightAddressAsAdmin() external {
		Engine engine = new DeployEngine().run();

		assertEq(engine.defaultAdmin(), address(1), "Engine Admin address does not match");
	}
}
