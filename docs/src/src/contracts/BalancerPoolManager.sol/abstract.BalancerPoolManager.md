# BalancerPoolManager
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/contracts/BalancerPoolManager.sol)


## State Variables
### i_vault

```solidity
IVault private immutable i_vault;
```


### i_managedPoolFactory

```solidity
IBalancerManagedPoolFactoryV2 private immutable i_managedPoolFactory;
```


### i_queries

```solidity
IBalancerQueries private immutable i_queries;
```


### MAX_POOL_TOKENS

```solidity
uint256 private constant MAX_POOL_TOKENS = 50;
```


### NORMALIZED_WEIGHT_SUM

```solidity
uint256 private constant NORMALIZED_WEIGHT_SUM = 1e18;
```


## Functions
### constructor


```solidity
constructor(address balancerManagedPoolFactory, address balancerVault);
```

### getExitPoolData


```solidity
function getExitPoolData(bytes32 poolId, uint256 exitTokenIndex, uint256 bptAmountIn, uint256 minAmountOut)
    public
    view
    returns (IVault.ExitPoolRequest memory exitPoolRequest, OpenZeppelinIERC20 exitToken);
```

### _createPool


```solidity
function _createPool(string memory name, string memory symbol, OpenZeppelinIERC20[] memory initialTokens)
    internal
    returns (address poolAddress, bytes32 poolId, uint256[] memory weights);
```

### _joinPool


```solidity
function _joinPool(bytes32 poolId, uint256 minBPTOut) internal returns (uint256 bptAmountReceived);
```

### _exitPool


```solidity
function _exitPool(bytes32 poolId, uint256 bptAmountIn, uint256 minAmountOut, uint256 exitTokenIndex)
    internal
    returns (uint256 exitTokenAmountReceived, OpenZeppelinIERC20 exitToken);
```

### _getTokenWeight

calculate the normalized weight of the pool tokens


```solidity
function _getTokenWeight(uint256 tokensCount) private pure returns (uint256 weight);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokensCount`|`uint256`|the length of the pool tokens (without decimals)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`weight`|`uint256`|the weight of each token in the pool (with balancer decimals, 1e18 for 1)|


### _getTokensWeight

calculate the normalized weight of the pool tokens and return them as list


```solidity
function _getTokensWeight(uint256 tokensCount) private pure returns (uint256[] memory weights);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokensCount`|`uint256`|the length of the pool tokens (without decimals)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`weights`|`uint256[]`|the weight of each token in the pool (with balancer decimals, 1e18 for 1)|


## Errors
### BalancerPoolManager__ExceededMaxPoolTokens
thrown if at the creation of a pool or adding a token, the total number of tokens exceeds the MAX_POOL_TOKENS


```solidity
error BalancerPoolManager__ExceededMaxPoolTokens(uint256 tokens, uint256 maxTokens);
```

### BalancerPoolManager__JoinAssetsCountMismatch
thrown if the join kind is `INIT` and the number of join assets is not equal to the number of tokens in the pool


```solidity
error BalancerPoolManager__JoinAssetsCountMismatch(uint256 joinAssetsCount, uint256 assetsCount);
```

### BalancerPoolManager__BPTNotReceived
thrown if the contract have not received the BPT after joining the pool


```solidity
error BalancerPoolManager__BPTNotReceived();
```

## Enums
### JoinPoolKind

```solidity
enum JoinPoolKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
}
```

### ExitPoolKind

```solidity
enum ExitPoolKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
}
```

