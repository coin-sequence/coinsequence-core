#!/bin/bash

read -p "Chain Id: " CHAIN_ID
read -p "CTF(Cross Chain Pool Manager in case of another chain): " CTF
read -p "Bpt Amount In (With Decimals): " BPT_AMOUNT_IN
read -p "Balancer Queries Contract: " BALANCER_QUERIES
read -p "Mock Token Address: " MOCK_TOKEN_ADDRESS
read -p "USDC Address: " USDC_ADDRESS
read -p "USDC Amount to Receive (With Decimals): " USDC_AMOUNT
read -p "RPC: " RPC

POOL_ID=$(cast call ${CTF} "getChainPool(uint256) ((address,address[],uint256[],bytes32,uint256))" ${CHAIN_ID} --rpc-url ${RPC} | sed -n 's/.*\(0x[a-fA-F0-9]\{64\}\).*/\1/p')
EXIT_POOL_DATA=$(cast call ${CTF} "getExitPoolData(bytes32,uint256,uint256,uint256) ((address[],uint256[],bytes,bool),address)" "${POOL_ID}" 0 ${BPT_AMOUNT_IN} 0 --rpc-url ${RPC})
EXIT_POOL_REQUEST=$(echo "$EXIT_POOL_DATA" | sed '$d' | tr -d ' ')
BALANCER_EXIT_QUERY=$(cast call ${BALANCER_QUERIES} "queryExit(bytes32,address,address,(address[],uint256[],bytes,bool)) (uint256,uint256[])" ${POOL_ID} ${CTF} ${CTF} ${EXIT_POOL_REQUEST} --rpc-url ${RPC})
BPT_AMOUNT_OUT=$(echo "$BALANCER_EXIT_QUERY" | grep -o '[0-9]\{15,\}' | sed -n '2p')
SWAP_TO_USDC_CALLDATA=$(cast calldata "swapToUSDC(address,uint256,address,uint256)" ${MOCK_TOKEN_ADDRESS} ${BPT_AMOUNT_OUT} ${USDC_ADDRESS} ${USDC_AMOUNT})
 
echo $SWAP_TO_USDC_CALLDATA
