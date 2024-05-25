# NetworkHelper
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/libraries/NetworkHelper.sol)


## Functions
### _getNetworkConfig


```solidity
function _getNetworkConfig() internal view returns (NetworkConfig memory);
```

### _getBalancerManagedPoolFactory


```solidity
function _getBalancerManagedPoolFactory() internal view returns (address balancerManagedPoolFactory);
```

### _getBalancerVault


```solidity
function _getBalancerVault() internal view returns (address balancerVault);
```

### _getCCIPRouter


```solidity
function _getCCIPRouter() internal view returns (address ccipRouter);
```

### _getUSDC


```solidity
function _getUSDC() internal view returns (address usdc);
```

### _getCCIPChainSelector


```solidity
function _getCCIPChainSelector(uint256 chainid) internal pure returns (uint64 ccipChainSelector);
```

## Errors
### UnknownChainConfig
thrown when the current block.chainid config is not defined yet


```solidity
error UnknownChainConfig(uint256 chainId);
```

## Structs
### NetworkConfig

```solidity
struct NetworkConfig {
    uint256 chainId;
    uint64 ccipChainSelector;
    address balancerManagedPoolFactory;
    address balancerVault;
    address ccipRouter;
    address usdcAddress;
}
```

