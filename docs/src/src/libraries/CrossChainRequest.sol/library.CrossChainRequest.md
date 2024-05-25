# CrossChainRequest
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/libraries/CrossChainRequest.sol)


## Structs
### CrossChainCreatePoolRequest

```solidity
struct CrossChainCreatePoolRequest {
    address[] tokens;
    string poolName;
}
```

### CrossChainDepositRequest

```solidity
struct CrossChainDepositRequest {
    bytes32 depositId;
    bytes32 poolId;
    uint256 minBPTOut;
    address swapProvider;
    bytes[] swapsCalldata;
}
```

### CrossChainWithdrawRequest

```solidity
struct CrossChainWithdrawRequest {
    bytes32 withdrawalId;
    bytes32 poolId;
    uint256 bptAmountIn;
    uint256 exitTokenIndex;
    uint256 exitTokenMinAmountOut;
    address swapProvider;
    bytes swapCalldata;
}
```

## Enums
### CrossChainRequestType

```solidity
enum CrossChainRequestType {
    CREATE_POOL,
    DEPOSIT,
    WITHDRAW
}
```

