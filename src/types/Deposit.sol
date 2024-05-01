// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {FunctionsRequestStatus} from "src/types/FunctionsRequestStatus.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICTF} from "src/interfaces/ICTF.sol";

struct Deposit {
	address user;
	ICTF ctf;
	IERC20 inputToken;
	uint256 inputTokenAmount;
	FunctionsRequestStatus requestStatus;
}
