# RequestReceipt
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/libraries/RequestReceipt.sol)


## Functions
### crossChainPoolCreatedReceipt


```solidity
function crossChainPoolCreatedReceipt(
    address poolAddress,
    bytes32 poolId,
    address[] memory tokens,
    uint256[] memory weights
) internal view returns (CrossChainReceipt memory);
```

### crossChainDepositedReceipt


```solidity
function crossChainDepositedReceipt(bytes32 depositId, uint256 bptReceived)
    internal
    view
    returns (CrossChainReceipt memory);
```

### crossChainWithdrawnReceipt


```solidity
function crossChainWithdrawnReceipt(bytes32 withdrawId, uint256 usdcReceived)
    internal
    view
    returns (CrossChainReceipt memory);
```

### crossChainGenericFailedReceipt


```solidity
function crossChainGenericFailedReceipt(CrossChainFailureReceiptType failureReceiptType)
    internal
    view
    returns (CrossChainReceipt memory);
```

### _successReceipt


```solidity
function _successReceipt(bytes memory data) private view returns (CrossChainReceipt memory);
```

### _failureReceipt


```solidity
function _failureReceipt(bytes memory data) private view returns (CrossChainReceipt memory);
```

## Structs
### CrossChainPoolCreatedReceipt

```solidity
struct CrossChainPoolCreatedReceipt {
    address poolAddress;
    bytes32 poolId;
    address[] tokens;
    uint256[] weights;
}
```

### CrossChainDepositedReceipt

```solidity
struct CrossChainDepositedReceipt {
    bytes32 depositId;
    uint256 receivedBPT;
}
```

### CrossChainWithdrawReceipt

```solidity
struct CrossChainWithdrawReceipt {
    bytes32 withdrawId;
    uint256 receivedUSDC;
}
```

### CrossChainDepositFailedReceipt

```solidity
struct CrossChainDepositFailedReceipt {
    bytes32 depositId;
}
```

### CrossChainReceipt

```solidity
struct CrossChainReceipt {
    CrossChainReceiptType receiptType;
    uint256 chainId;
    bytes data;
}
```

## Enums
### CrossChainReceiptType

```solidity
enum CrossChainReceiptType {
    SUCCESS,
    FAILURE
}
```

### CrossChainSuccessReceiptType

```solidity
enum CrossChainSuccessReceiptType {
    POOL_CREATED,
    DEPOSITED,
    WITHDRAW
}
```

### CrossChainFailureReceiptType

```solidity
enum CrossChainFailureReceiptType {
    POOL_CREATION_FAILED,
    TOKEN_ADDITION_FAILED
}
```

