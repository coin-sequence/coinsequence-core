# SafeCrossChainReceipt
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/libraries/SafeCrossChainReceipt.sol)


## Functions
### isSuccess


```solidity
function isSuccess(RequestReceipt.CrossChainReceiptType receiptType) internal pure returns (bool);
```

### isFailure


```solidity
function isFailure(RequestReceipt.CrossChainReceiptType receiptType) internal pure returns (bool);
```

### isPoolCreated


```solidity
function isPoolCreated(RequestReceipt.CrossChainSuccessReceiptType successReceiptType) internal pure returns (bool);
```

### isPoolNotCreated


```solidity
function isPoolNotCreated(RequestReceipt.CrossChainFailureReceiptType failureReceiptType)
    internal
    pure
    returns (bool);
```

### isDeposited


```solidity
function isDeposited(RequestReceipt.CrossChainSuccessReceiptType successReceiptType) internal pure returns (bool);
```

### isWithdrawn


```solidity
function isWithdrawn(RequestReceipt.CrossChainSuccessReceiptType successReceiptType) internal pure returns (bool);
```

