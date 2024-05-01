// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

struct FunctionsRequestParams {
	uint32 subscriptionId;
	uint32 callbackGasLimit;
	bytes32 donId;
	string source;
}
