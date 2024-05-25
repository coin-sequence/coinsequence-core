# PoolManager
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/contracts/PoolManager.sol)

**Inherits:**
CCIPReceiver, AccessControlDefaultAdminRules, [BalancerPoolManager](/src/contracts/BalancerPoolManager.sol/abstract.BalancerPoolManager.md), [Swap](/src/contracts/Swap.sol/abstract.Swap.md)


## State Variables
### CREATE_POOL_GAS_LIMIT
we use 1 as gas limit, because the ccip max gas limit is
still not enough for the creation of the pool. So we need to manually
execute it in the ccip explorer, once it fail for out of gas


```solidity
uint256 private constant CREATE_POOL_GAS_LIMIT = 1;
```


### DEPOSIT_GAS_LIMIT

```solidity
uint256 private constant DEPOSIT_GAS_LIMIT = 1_100_000;
```


### WITHDRAW_GAS_LIMIT

```solidity
uint256 private constant WITHDRAW_GAS_LIMIT = 1_100_000;
```


### ADMIN_TRANSFER_DELAY

```solidity
uint48 private constant ADMIN_TRANSFER_DELAY = 7 days;
```


### TOKENS_MANAGER_ROLE

```solidity
bytes32 public constant TOKENS_MANAGER_ROLE = "TOKENS_MANAGER";
```


### i_ccipRouterClient

```solidity
IRouterClient private immutable i_ccipRouterClient;
```


### s_chainCrossChainPoolManager

```solidity
mapping(uint256 chainId => address crossChainPoolManager) private s_chainCrossChainPoolManager;
```


### s_deposits

```solidity
mapping(bytes32 depositId => mapping(uint256 chainId => ChainDeposit)) private s_deposits;
```


### s_withdrawals

```solidity
mapping(bytes32 withdrawId => mapping(uint256 chainId => ChainWithdrawal)) private s_withdrawals;
```


### s_chainPool

```solidity
mapping(uint256 chainId => ChainPool pool) private s_chainPool;
```


### s_chainsSet

```solidity
EnumerableSet.UintSet internal s_chainsSet;
```


### i_usdc

```solidity
IERC20 internal immutable i_usdc;
```


## Functions
### constructor


```solidity
constructor(address balancerManagedPoolFactory, address balancerVault, address ccipRouterClient, address admin)
    BalancerPoolManager(balancerManagedPoolFactory, balancerVault)
    AccessControlDefaultAdminRules(ADMIN_TRANSFER_DELAY, admin)
    CCIPReceiver(ccipRouterClient);
```

### receive


```solidity
receive() external payable;
```

### withdrawETH

withdraw ETH from the CTF. Only the admin can perform this action


```solidity
function withdrawETH(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of ETH to withdraw (with decimals)|


### setCrossChainPoolManager

set the Cross Cross Chain Pool Manager contract for the given chain.
Only the tokens manager can set it.


```solidity
function setCrossChainPoolManager(uint256 chainId, address crossChainPoolManager)
    external
    onlyRole(TOKENS_MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainId`|`uint256`|the chain id of the given `crossChainPoolManager` address|
|`crossChainPoolManager`|`address`|the address of the Cross Chain Pool Manager at the given chain|


### getChains

get the chains that the underlying tokens are on


```solidity
function getChains() external view returns (uint256[] memory chains);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`chains`|`uint256[]`|the array of chains without duplicates|


### getWithdrawal

get the withdrawal info for the given id at the given chain


```solidity
function getWithdrawal(bytes32 withdrawId, uint256 chainId)
    external
    view
    returns (ChainWithdrawal memory chainWithdrawal);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`chainWithdrawal`|`ChainWithdrawal`|the withdrawal info at the given chain|


### getCrossChainPoolManager

get the Cross Chain Pool Manager contract for the given chain


```solidity
function getCrossChainPoolManager(uint256 chainId) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainId`|`uint256`|the chain id that the Cross Chain Pool Manager contract is on|


### getChainPool

get the Pool info for the given chain


```solidity
function getChainPool(uint256 chainId) public view returns (ChainPool memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainId`|`uint256`|the chain id that the Pool contract is on|


### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(AccessControlDefaultAdminRules, CCIPReceiver)
    returns (bool);
```

### _ccipReceive


```solidity
function _ccipReceive(Client.Any2EVMMessage memory message) internal override;
```

### _onCreatePool


```solidity
function _onCreatePool(uint256 chainId, address[] memory tokens) internal virtual;
```

### _onDeposit


```solidity
function _onDeposit(address user, uint256 totalBPTReceived) internal virtual;
```

### _onWithdraw


```solidity
function _onWithdraw(address user, uint256 totalBPTWithdrawn, uint256 totalUSDCToSend) internal virtual;
```

### _requestPoolDeposit


```solidity
function _requestPoolDeposit(
    bytes32 depositId,
    uint256 chainId,
    address swapProvider,
    bytes[] calldata swapsCalldata,
    uint256 minBPTOut,
    uint256 depositUSDCAmount
) internal;
```

### _requestPoolWithdrawal


```solidity
function _requestPoolWithdrawal(
    bytes32 withdrawId,
    uint256 bptAmountIn,
    uint256 chainId,
    address swapProvider,
    uint256 exitTokenIndex,
    uint256 exitTokenMinAmountOut,
    bytes calldata swapData
) internal;
```

### _requestNewPoolCreation

Create a new pool with the given Tokens for the given chain


```solidity
function _requestNewPoolCreation(uint256 chainId, string memory poolName, address[] memory tokens) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainId`|`uint256`|the chain that the pool will be created on|
|`poolName`|`string`||
|`tokens`|`address[]`|the tokens that will be added to the pool|


### _handleCrossChainSuccessReceipt


```solidity
function _handleCrossChainSuccessReceipt(
    uint256 chainId,
    RequestReceipt.CrossChainSuccessReceiptType successTypeReceipt,
    RequestReceipt.CrossChainReceipt memory receipt
) private;
```

### _handleCrossChainFailureReceipt


```solidity
function _handleCrossChainFailureReceipt(
    uint256 chainId,
    RequestReceipt.CrossChainFailureReceiptType failureTypeReceipt,
    address sender
) private;
```

### _handleCrossChainPoolCreatedReceipt


```solidity
function _handleCrossChainPoolCreatedReceipt(
    uint256 chainId,
    RequestReceipt.CrossChainPoolCreatedReceipt memory receipt
) private;
```

### _handleCrossChainDepositedReceipt


```solidity
function _handleCrossChainDepositedReceipt(uint256 chainId, RequestReceipt.CrossChainDepositedReceipt memory receipt)
    private;
```

### _handleCrossChainWithdrawReceipt


```solidity
function _handleCrossChainWithdrawReceipt(uint256 chainId, RequestReceipt.CrossChainWithdrawReceipt memory receipt)
    private;
```

### _buildCrossChainMessage

*build CCIP Message to send to another chain*


```solidity
function _buildCrossChainMessage(uint256 chainId, uint256 gasLimit, uint256 usdcAmount, bytes memory data)
    private
    view
    returns (Client.EVM2AnyMessage memory message, uint256 fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainId`|`uint256`|the chain that the CrossChainPoolManager is in|
|`gasLimit`|`uint256`|the gas limit for the transaction in the other chain|
|`usdcAmount`|`uint256`|the amount of USDC to send, if zero, no usdc will be sent|
|`data`|`bytes`|the encoded data to pass to the CrossChainPoolManager|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`message`|`Client.EVM2AnyMessage`|the CCIP Message to be sent|
|`fee`|`uint256`|the ccip fee to send this message, note that the fee will be in ETH|


### _verifyPoolManagerAndChainSelector


```solidity
function _verifyPoolManagerAndChainSelector(uint256 chainId, uint256 chainSelector, address crossChainPoolManager)
    private
    pure;
```

## Events
### PoolManager__SameChainPoolCreated
emitted once the Pool for the same chain as the CTF is successfully created.


```solidity
event PoolManager__SameChainPoolCreated(bytes32 indexed poolId, address indexed poolAddress, address[] tokens);
```

### PoolManager__SameChainDeposited
emitted once a deposit is made in the same chain is made in the CTF


```solidity
event PoolManager__SameChainDeposited(address indexed forUser, bytes32 indexed depositId);
```

### PoolManager__SameChainWithdrawn

```solidity
event PoolManager__SameChainWithdrawn(address indexed forUser, bytes32 indexed withdrawId);
```

### PoolManager__CrossChainDepositRequested
emitted once a cross chain deposit is requested


```solidity
event PoolManager__CrossChainDepositRequested(
    bytes32 indexed depositId, uint256 indexed chainId, address indexed user, bytes32 messageId, uint256 usdcAmount
);
```

### PoolManager__CrossChainWithdrawRequested
emitted once a cross chain withdrawal is requested


```solidity
event PoolManager__CrossChainWithdrawRequested(
    bytes32 indexed withdrawId, uint256 indexed chainId, address indexed user, bytes32 messageId, uint256 bptAmount
);
```

### PoolManager__CrossChainPoolManagerSet
emitted once the CrossChainPoolManager for the given chain is set


```solidity
event PoolManager__CrossChainPoolManagerSet(uint256 indexed chainId, address indexed crossChainPoolManager);
```

### PoolManager__CrossChainCreatePoolRequested
emitted once the message to create a pool in another chain is sent


```solidity
event PoolManager__CrossChainCreatePoolRequested(
    address indexed crossChainPoolManager,
    bytes32 indexed messageId,
    uint256 indexed chainId,
    address[] tokens,
    string poolName
);
```

### PoolManager__CrossChainPoolCreated
emitted once the cross chain pool creation receipt is received


```solidity
event PoolManager__CrossChainPoolCreated(address indexed poolAddress, bytes32 indexed poolId, uint256 indexed chainId);
```

### PoolManager__ETHWithdrawn
emitted once an amount of ETH has been withdrawn from the Pool Manager


```solidity
event PoolManager__ETHWithdrawn(uint256 amount);
```

### PoolManager__AllDepositsConfirmed
emitted once the deposits on all pools across all chains have been confirmed


```solidity
event PoolManager__AllDepositsConfirmed(bytes32 indexed depositId, address indexed user);
```

### PoolManager__AllWithdrawalsConfirmed
emitted once the withdrawals on all pools across all chains have been confirmed


```solidity
event PoolManager__AllWithdrawalsConfirmed(bytes32 indexed withdrawId, address indexed user);
```

### PoolManager__CrossChainDepositConfirmed
emitted once one Cross Chain Deposit receipt is reived


```solidity
event PoolManager__CrossChainDepositConfirmed(uint256 chainId, address indexed user, bytes32 indexed depositId);
```

### PoolManager__CrossChainWithdrawalConfirmed
emitted once one Cross Chain Withdrawal receipt is reived


```solidity
event PoolManager__CrossChainWithdrawalConfirmed(uint256 chainId, address indexed user, bytes32 indexed withdrawId);
```

### PoolManager__FailedToCreateCrossChainPool
emitted when the Pool Manager receives the Cross Chain Pool not created receipt
from the Cross Chain Pool Manager.


```solidity
event PoolManager__FailedToCreateCrossChainPool(uint256 chainId, address crossChainPoolManager);
```

### PoolManager__FailedToDeposit
emitted when the Pool Manager receives the Cross Chain Deposit failed receipt


```solidity
event PoolManager__FailedToDeposit(address indexed forUser, bytes32 indexed depositId, uint256 usdcAmount);
```

## Errors
### PoolManager__PoolAlreadyCreated
thrown if the pool has already been created and the CTF is trying to create it again


```solidity
error PoolManager__PoolAlreadyCreated(address poolAddress, uint256 chainId);
```

### PoolManager__CrossChainPoolManagerNotFound
thrown if the CrossChain Pool manager for the given chain have not been found.
it can be due to the missing call to `setCrossChainPoolManager` or actually not existing yet


```solidity
error PoolManager__CrossChainPoolManagerNotFound(uint256 chainId);
```

### PoolManager__ChainSelectorNotFound
thrown if the ccip chain selector for the given chain have not been found.
it can be due to the missing call to `setChainSelector` or actually not existing yet


```solidity
error PoolManager__ChainSelectorNotFound(uint256 chainId);
```

### PoolManager__CannotAddCrossChainPoolManagerForTheSameChain
thrown if the admin tries to add a CrossChainPoolManager for the same chain as the CTF


```solidity
error PoolManager__CannotAddCrossChainPoolManagerForTheSameChain();
```

### PoolManager__CannotAddChainSelectorForTheSameChain
thrown if the admin tries to add a ccip chain selector for the same chain as the CTF


```solidity
error PoolManager__CannotAddChainSelectorForTheSameChain();
```

### PoolManager__CrossChainPoolManagerAlreadySet
thrown if the CrossChainPoolManager for the given chain have already been set


```solidity
error PoolManager__CrossChainPoolManagerAlreadySet(address crossChainPoolManager);
```

### PoolManager__InvalidPoolManager
thrown if the adming tries to add a CrossChainPoolManager with an invalid address


```solidity
error PoolManager__InvalidPoolManager();
```

### PoolManager__InvalidChainSelector
thrown if the admin tries to add a ccip chain selector with an invalid value


```solidity
error PoolManager__InvalidChainSelector();
```

### PoolManager__InvalidReceiptSender
thrown if the sender of the Cross Chain Receipt is not a registered Cross Chain Pool Manager


```solidity
error PoolManager__InvalidReceiptSender(address sender, address crossChainPoolManager);
```

### PoolManager__FailedToWithdrawETH
thrown when the ETH witdraw fails for some reason


```solidity
error PoolManager__FailedToWithdrawETH(bytes data);
```

### PoolManager__UnknownChain
thrown when the chainid passed is not mapped.


```solidity
error PoolManager__UnknownChain(uint256 chainId);
```

### PoolManager__PoolNotActive
thrown when the pool for the given chain is not active yet


```solidity
error PoolManager__PoolNotActive(uint256 chainId);
```

## Structs
### ChainPool

```solidity
struct ChainPool {
    address poolAddress;
    address[] poolTokens;
    uint256[] weights;
    bytes32 poolId;
    PoolStatus status;
}
```

### ChainDeposit

```solidity
struct ChainDeposit {
    DepositStatus status;
    address user;
    uint256 receivedBPT;
    uint256 usdcAmount;
}
```

### ChainWithdrawal

```solidity
struct ChainWithdrawal {
    WithdrawStatus status;
    address user;
    uint256 bptAmount;
    uint256 usdcReceived;
}
```

## Enums
### PoolStatus

```solidity
enum PoolStatus {
    NOT_CREATED,
    ACTIVE,
    CREATING
}
```

### DepositStatus

```solidity
enum DepositStatus {
    NOT_DEPOSITED,
    DEPOSITED,
    PENDING,
    FAILED
}
```

### WithdrawStatus

```solidity
enum WithdrawStatus {
    NOT_WITHDRAWN,
    WITHDRAWN,
    PENDING,
    FAILED
}
```

