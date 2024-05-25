#!/bin/bash

read -p "Chain Id: " CHAIN_ID
read -p "CTF: " CTF
read -p "Pool Manager: " POOL_MANAGER
read -p "Bpt Amount In (With Decimals): " BPT_AMOUNT_IN
read -p "Balancer Queries Contract: " BALANCER_QUERIES
read -p "Mock Token Address: " MOCK_TOKEN_ADDRESS
read -p "USDC Address: " USDC_ADDRESS
read -p "USDC Amount to Receive (With Decimals): " USDC_AMOUNT
read -p "CTF RPC: " CTF_RPC
read -p "Pool Manager RPC: " POOL_MANAGER_RPC

POOL_ID=$(cast call ${CTF} "getChainPool(uint256) ((address,address[],uint256[],bytes32,uint256))" ${CHAIN_ID} --rpc-url ${CTF_RPC} | sed -n 's/.*\(0x[a-fA-F0-9]\{64\}\).*/\1/p')
EXIT_POOL_DATA=$(cast call ${POOL_MANAGER} "getExitPoolData(bytes32,uint256,uint256,uint256) ((address[],uint256[],bytes,bool),address)" "${POOL_ID}" 0 ${BPT_AMOUNT_IN} 0 --rpc-url ${POOL_MANAGER_RPC})
EXIT_POOL_REQUEST=$(echo "$EXIT_POOL_DATA" | sed '$d' | tr -d ' ')
BALANCER_EXIT_QUERY=$(cast call ${BALANCER_QUERIES} "queryExit(bytes32,address,address,(address[],uint256[],bytes,bool)) (uint256,uint256[])" ${POOL_ID} ${POOL_MANAGER} ${POOL_MANAGER} ${EXIT_POOL_REQUEST} --rpc-url ${POOL_MANAGER_RPC})
BPT_AMOUNT_OUT=$(echo "$BALANCER_EXIT_QUERY" | grep -o '[0-9]\{15,\}' | sed -n '2p')
SWAP_TO_USDC_CALLDATA=$(cast calldata "swapToUSDC(address,uint256,address,uint256)" ${MOCK_TOKEN_ADDRESS} ${BPT_AMOUNT_OUT} ${USDC_ADDRESS} ${USDC_AMOUNT})
 
echo $SWAP_TO_USDC_CALLDATA
