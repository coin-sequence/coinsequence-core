# CTF
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/contracts/CTF.sol)

**Inherits:**
[PoolManager](/src/contracts/PoolManager.sol/abstract.PoolManager.md), ERC20Permit


## State Variables
### s_chainUnderlyingTokens

```solidity
mapping(uint256 chainId => address[] tokens) private s_chainUnderlyingTokens;
```


### s_chainTokensToBeAdded
*we use this temporary mapping to store the tokens that we want to add
before adding to the real list. This is done because we can't have mapping
in the memory storage :(
This mapping values should be cleared after every use. Because after we just
move the tokens from this mapping to the real one `s_chainUnderlyingTokens`,
Not clearing it will lead to adding wrong tokens to `s_chainUnderlyingTokens`
and the CTF will be broken*


```solidity
mapping(uint256 chainId => address[] tokens) private s_chainTokensToBeAdded;
```


### s_underlyingTokens

```solidity
address[] private s_underlyingTokens;
```


### s_chains

```solidity
uint256[] private s_chains;
```


### s_nonce
*nonce used to generate withdraw and deposit ids*


```solidity
uint256 private s_nonce;
```


## Functions
### constructor


```solidity
constructor(string memory ctfName, string memory ctfSymbol, address admin)
    ERC20(ctfName, ctfSymbol)
    ERC20Permit(ctfName)
    PoolManager(
        NetworkHelper._getBalancerManagedPoolFactory(),
        NetworkHelper._getBalancerVault(),
        NetworkHelper._getCCIPRouter(),
        admin
    );
```

### deposit

deposit into the CTF to receive CTF Tokens


```solidity
function deposit(
    address[] calldata swapProviders,
    bytes[][] calldata swapsCalldata,
    uint256[] calldata minBPTOut,
    uint256 usdcAmountPerChain
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`swapProviders`|`address[]`|the swap contract for each chain to be used for swapping the USDC for the pool tokens.|
|`swapsCalldata`|`bytes[][]`|the swaps calldata for each chain to be passed to the swap contract.|
|`minBPTOut`|`uint256[]`|the min BPT out for each chain given the in token amount for each chain.|
|`usdcAmountPerChain`|`uint256`|the USDC Amount to send for each chain to execute the swap (with decimals)|


### withdraw

withdraw from the CTF and received USDC back


```solidity
function withdraw(
    uint256 bptAmountPerChain,
    address[] calldata swapProviders,
    uint256[] calldata exitTokenIndex,
    uint256[] calldata exitTokenMinAmountOut,
    bytes[] calldata swapsCalldata
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bptAmountPerChain`|`uint256`|the total ctf amount to withdraw divided by the number of chains|
|`swapProviders`|`address[]`|the swap contract used for swapping the exit token to usdc for each chain.|
|`exitTokenIndex`|`uint256[]`|the index of the token that will be removed in the balancer pool for each chain|
|`exitTokenMinAmountOut`|`uint256[]`|the min amount of the exit token that will be received from balancer given the bpt amount in, in each chain|
|`swapsCalldata`|`bytes[]`|the swap calldata to be passed for the swap contract for each chain.|


### addUnderlyingTokensCrossChain

Add Cross-Chain underlying tokens to the CTF.

*the @param underlyingTokens and @param chains must have the same length.
These arrays are corretaled, so they must be in the same order also.
e.g: 3 tokens from 3 different chains, the @param underlyingTokens should be:
[token1, token2, token3] and the @param chains should be [token1ChainId, token2ChainId, token3ChainId].
Not following this rule, will cause the contract to crash, and the CTF will not work as expected.*


```solidity
function addUnderlyingTokensCrossChain(address[] calldata underlyingTokens, uint256[] calldata chains)
    external
    onlyRole(TOKENS_MANAGER_ROLE);
```

### getChainUnderlyingTokens


```solidity
function getChainUnderlyingTokens(uint256 chainId) external view returns (address[] memory);
```

### getAllUnderlyingTokens


```solidity
function getAllUnderlyingTokens() external view returns (address[] memory underlyingTokens, uint256[] memory chains);
```

### addUnderlyingTokensSameChain

add underlying tokens for the same chain as the CTF.
If the pool is not created yet, it will be created.


```solidity
function addUnderlyingTokensSameChain(address[] calldata underlyingTokens) public onlyRole(TOKENS_MANAGER_ROLE);
```

### _onCreatePool


```solidity
function _onCreatePool(uint256 chainId, address[] memory tokens) internal override;
```

### _onDeposit


```solidity
function _onDeposit(address user, uint256 totalBPTReceived) internal virtual override;
```

### _onWithdraw


```solidity
function _onWithdraw(address user, uint256 totalBPTWithdrawn, uint256 totalUSDCToSend) internal virtual override;
```

## Events
### CTF__Deposited
emitted once a deposit is successfully made and CTF tokens are minted
to the user


```solidity
event CTF__Deposited(address indexed user, uint256 amount);
```

### CTF__Withdrawn
emitted once a withdraw is successfully made and CTF tokens are burned


```solidity
event CTF__Withdrawn(address indexed user, uint256 ctfAmountBurned, uint256 usdcAmountWithdrawn);
```

## Errors
### CTF__TokensAndChainsMismatch
thrown if the underlying tokens array and chains array have different lengths


```solidity
error CTF__TokensAndChainsMismatch(uint256 tokens, uint256 chains);
```

### CTF__SwapProvidersLengthMismatch
thrown when the swap providers array and chains array have different lengths


```solidity
error CTF__SwapProvidersLengthMismatch(uint256 swapProvidersLength, uint256 chainsLength);
```

### CTF__SwapsCallDataLengthMismatch
thrown when the swap calldata array and chains array have different lengths


```solidity
error CTF__SwapsCallDataLengthMismatch(uint256 swapsCalldataLength, uint256 chainsLength);
```

### CTF__MinBPTOutLengthMismatch
thrown when the min BPT out array and chains array have different lengths


```solidity
error CTF__MinBPTOutLengthMismatch(uint256 minBPTOutLength, uint256 chainsLength);
```

### CTF__MinExitTokenOutLengthMismatch
thrown when the min exit token out array and chains array have different lengths


```solidity
error CTF__MinExitTokenOutLengthMismatch(uint256 minExitTokenOutLength, uint256 chainsLength);
```

### CTF__ExitTokenIndexLengthMismatch
thrown when the exit token index array and chains array have different lengths


```solidity
error CTF__ExitTokenIndexLengthMismatch(uint256 exitTokenIndexLength, uint256 chainsLength);
```

### Pool__NotActive
thrown when trying to perform actions in a pool that is not in Active state
e.g add new underlying tokens


```solidity
error Pool__NotActive(uint256 chainId);
```

