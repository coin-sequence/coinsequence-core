# CrossChainPoolManager
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/contracts/CrossChainPoolManager.sol)

**Inherits:**
CCIPReceiver, [BalancerPoolManager](/src/contracts/BalancerPoolManager.sol/abstract.BalancerPoolManager.md), Ownable2Step, [Swap](/src/contracts/Swap.sol/abstract.Swap.md)


## State Variables
### i_CTF

```solidity
address private immutable i_CTF;
```


### s_receipts

```solidity
mapping(bytes32 originMessageId => CCIPReceipt ccipReceipt) private s_receipts;
```


### s_receiptRetryAllowed

```solidity
mapping(bytes32 originMessageId => bool retryAllowed) private s_receiptRetryAllowed;
```


### s_failedWithdraws

```solidity
mapping(bytes32 withdrawId => FailedWithdraw failedWithdraw) private s_failedWithdraws;
```


### s_failedDeposits

```solidity
mapping(bytes32 depositId => FailedDeposit failedDeposit) private s_failedDeposits;
```


## Functions
### onlySelf


```solidity
modifier onlySelf();
```

### constructor


```solidity
constructor(address ctf, address admin)
    Ownable(admin)
    CCIPReceiver(NetworkHelper._getCCIPRouter())
    BalancerPoolManager(NetworkHelper._getBalancerManagedPoolFactory(), NetworkHelper._getBalancerVault());
```

### receive


```solidity
receive() external payable;
```

### withdrawETH

withdraw ETH from the Contract. Only the admin can perform this action


```solidity
function withdrawETH(uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of ETH to withdraw (with decimals)|


### retrySendReceipt

re-send a failed-to-send receipt


```solidity
function retrySendReceipt(bytes32 originMessageId) external returns (bytes32 receiptMessageId);
```

### overrideFailedWithdraw

re-send a failed withdraw at given withdraw id and override the request data. Only the admin can perform this action


```solidity
function overrideFailedWithdraw(bytes32 withdrawId, CrossChainRequest.CrossChainWithdrawRequest calldata request)
    external
    onlyOwner;
```

### overrideFailedDeposit

re-send a failed deposit at given deposit id and override the request data. Only the admin can perform this action


```solidity
function overrideFailedDeposit(bytes32 depositId, CrossChainRequest.CrossChainDepositRequest calldata request)
    external
    onlyOwner;
```

### processCCIPMessage

Process the CCIP Message received. It can only be called by the contract itself

*We use this function as external to make it possible the use of Try-Catch*


```solidity
function processCCIPMessage(Client.Any2EVMMessage calldata message)
    external
    onlySelf
    returns (RequestReceipt.CrossChainReceipt memory);
```

### sendReceipt

Send the receipt back to the CTF. It can only be called by the contract itself

*We use this function as public to make it possible to use Try-Catch*


```solidity
function sendReceipt(CCIPReceipt calldata ccipReceipt) external onlySelf returns (bytes32 messageId);
```

### getCTF

get the CTF that this pool manager is linked to


```solidity
function getCTF() external view returns (address);
```

### getFailedWithdraw

get the Failed withdraw at the given id


```solidity
function getFailedWithdraw(bytes32 withdrawId) external view returns (FailedWithdraw memory);
```

### getFailedDeposit

get the Failed deposit at the given id


```solidity
function getFailedDeposit(bytes32 depositId) external view returns (FailedDeposit memory);
```

### _ccipReceive


```solidity
function _ccipReceive(Client.Any2EVMMessage memory message) internal override;
```

### _createPool


```solidity
function _createPool(CrossChainRequest.CrossChainCreatePoolRequest memory request)
    private
    returns (RequestReceipt.CrossChainReceipt memory receipt);
```

### _deposit


```solidity
function _deposit(CrossChainRequest.CrossChainDepositRequest memory request, uint256 usdcAmountReceived, IERC20 usdc)
    private
    returns (RequestReceipt.CrossChainReceipt memory receipt);
```

### _withdraw


```solidity
function _withdraw(CrossChainRequest.CrossChainWithdrawRequest memory request)
    private
    returns (RequestReceipt.CrossChainReceipt memory receipt);
```

### _sendReceipt


```solidity
function _sendReceipt(
    Client.Any2EVMMessage memory message,
    RequestReceipt.CrossChainReceipt memory receipt,
    uint256 usdcAmount,
    address usdcAddress
) private;
```

### _rawSendReceipt


```solidity
function _rawSendReceipt(CCIPReceipt memory ccipReceipt) private returns (bytes32 messageId);
```

### _executeErrorActions


```solidity
function _executeErrorActions(Client.Any2EVMMessage memory message) private;
```

### _executeSuccessActions


```solidity
function _executeSuccessActions(Client.Any2EVMMessage memory message, RequestReceipt.CrossChainReceipt memory receipt)
    private;
```

### _getGenericErrorReceipt


```solidity
function _getGenericErrorReceipt(bytes32 ccipMessageId, CrossChainRequest.CrossChainRequestType requestType)
    private
    view
    returns (RequestReceipt.CrossChainReceipt memory receipt);
```

### _buildReceiptCCIPMessage


```solidity
function _buildReceiptCCIPMessage(CCIPReceipt memory ccipReceipt)
    private
    view
    returns (Client.EVM2AnyMessage memory message, uint256 fee);
```

## Events
### CrossChainPoolManager__PoolCreated
emitted once the Pool for the CTF is successfully created


```solidity
event CrossChainPoolManager__PoolCreated(address indexed poolAddress, bytes32 indexed poolId, address[] tokens);
```

### CrossChainPoolManager__FailedToSendReceipt
emitted once the receipt couldn't be sent by some reason


```solidity
event CrossChainPoolManager__FailedToSendReceipt(
    bytes32 indexed originMessageId, RequestReceipt.CrossChainReceiptType indexed receiptType, bytes errorData
);
```

### CrossChainPoolManager__FailedToWithdraw
emitted once a withdraw failed for some reason


```solidity
event CrossChainPoolManager__FailedToWithdraw(bytes32 indexed withdrawId);
```

### CrossChainPoolManager__FailedToDeposit
emitted once a deposit failed for some reason


```solidity
event CrossChainPoolManager__FailedToDeposit(bytes32 indexed depositId);
```

### CrossChainPoolManager__ReceiptSent
emitted once the receipt was successfully sent


```solidity
event CrossChainPoolManager__ReceiptSent(
    bytes32 indexed originMessageId,
    bytes32 indexed receiptMessageId,
    RequestReceipt.CrossChainReceiptType indexed receiptType
);
```

### CrossChainPoolManager__Deposited
emitted once the requested deposit was successful


```solidity
event CrossChainPoolManager__Deposited(
    bytes32 indexed poolId, bytes32 indexed depositId, uint256 usdcAmount, uint256 bptreceived
);
```

### CrossChainPoolManager__Withdrawn
emitted once the requested withdrawal was successful


```solidity
event CrossChainPoolManager__Withdrawn(
    bytes32 indexed amount, bytes32 indexed withdrawId, uint256 bptIn, uint256 usdcReceived
);
```

### CrossChainPoolManager__ETHWithdrawn
emitted once the ETH was withdrawn by the Admin


```solidity
event CrossChainPoolManager__ETHWithdrawn(uint256 amount);
```

### CrossChainPoolManager__overrodeFailedWithdraw
emitted when the admin successfully overrode a failed withdraw


```solidity
event CrossChainPoolManager__overrodeFailedWithdraw(bytes32 withdrawId);
```

### CrossChainPoolManager__overrodeFailedDeposit
emitted when the admin successfully overrode a failed deposit


```solidity
event CrossChainPoolManager__overrodeFailedDeposit(bytes32 depositId);
```

## Errors
### CrossChainPoolManager__SenderIsNotCTF
thrown when the ccip received message sender is not the CTF


```solidity
error CrossChainPoolManager__SenderIsNotCTF(address sender, address ctf);
```

### CrossChainPoolManager__OnlySelf
thrown when someone else tries to call `proccessCCIPMessage` instead of the contract itself


```solidity
error CrossChainPoolManager__OnlySelf(address caller);
```

### CrossChainPoolManager__UnknownMessage
thrown when the message couldn't be processed and we don't know what it is


```solidity
error CrossChainPoolManager__UnknownMessage(bytes32 messageId, bytes messageData);
```

### CrossChainPoolManager__UnknownReceipt
thrown when the receipt couldn't be generated for the message because the request type is unknown


```solidity
error CrossChainPoolManager__UnknownReceipt(bytes32 messageId);
```

### CrossChainPoolManager__CannotRetrySendReceipt
thrown when someone tries to re-send a receipt which didn't fail


```solidity
error CrossChainPoolManager__CannotRetrySendReceipt(bytes32 originMessageId);
```

### CrossChainPoolManager__CannotRetryFailedWithdraw
thrown when someone tries to retry a failed withdraw which didn't fail


```solidity
error CrossChainPoolManager__CannotRetryFailedWithdraw(bytes32 withdrawId);
```

### CrossChainPoolManager__InvalidCTFAddress
thrown when the CTF address is invalid at the creation of the contract


```solidity
error CrossChainPoolManager__InvalidCTFAddress();
```

### CrossChainPoolManager__FailedToWithdrawETH
thrown when the ETH witdraw fails for some reason


```solidity
error CrossChainPoolManager__FailedToWithdrawETH(bytes errorData);
```

## Structs
### CCIPReceipt

```solidity
struct CCIPReceipt {
    RequestReceipt.CrossChainReceipt receipt;
    bytes sender;
    bytes32 originMessageId;
    uint256 usdcAmount;
    uint64 sourceChainSelector;
    address usdcAddress;
}
```

### FailedWithdraw

```solidity
struct FailedWithdraw {
    CrossChainRequest.CrossChainWithdrawRequest request;
    Client.Any2EVMMessage ccipMessage;
    bool retriable;
}
```

### FailedDeposit

```solidity
struct FailedDeposit {
    CrossChainRequest.CrossChainDepositRequest request;
    Client.Any2EVMMessage ccipMessage;
    bool retriable;
}
```

