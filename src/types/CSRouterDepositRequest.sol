// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {CSDeposit} from "src/types/CSDeposit.sol";
import {ICTF} from "src/interfaces/ICTF.sol";

struct CSRouterDepositRequest {
	CSDeposit ogDeposit;
	ICTF targetCTF;
	address user;
	bytes32 poolId;
}
