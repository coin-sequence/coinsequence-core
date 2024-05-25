# SafeChain
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/libraries/SafeChain.sol)


## State Variables
### SEPOLIA_ID

```solidity
uint256 internal constant SEPOLIA_ID = 11155111;
```


### ARBITRUM_SEPOLIA_ID

```solidity
uint256 internal constant ARBITRUM_SEPOLIA_ID = 421614;
```


### BASE_SEPOLIA_ID

```solidity
uint256 internal constant BASE_SEPOLIA_ID = 84532;
```


### OPTIMISM_SEPOLIA_ID

```solidity
uint256 internal constant OPTIMISM_SEPOLIA_ID = 11155420;
```


### ANVIL_ID

```solidity
uint256 internal constant ANVIL_ID = 31337;
```


## Functions
### isCurrent


```solidity
function isCurrent(uint256 chainId) internal view returns (bool);
```

### isSepolia


```solidity
function isSepolia(uint256 chainId) internal pure returns (bool);
```

### isArbitrumSepolia


```solidity
function isArbitrumSepolia(uint256 chainId) internal pure returns (bool);
```

### isBaseSepolia


```solidity
function isBaseSepolia(uint256 chainId) internal pure returns (bool);
```

### isOptimismSepolia


```solidity
function isOptimismSepolia(uint256 chainId) internal pure returns (bool);
```

### isAnvil


```solidity
function isAnvil(uint256 chainId) internal pure returns (bool);
```

