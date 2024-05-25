# Swap
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/contracts/Swap.sol)


## Functions
### _swap


```solidity
function _swap(IERC20 from, uint256 amount, address swapProvider, bytes[] memory swapsData) internal;
```

### _swapUSDCOut


```solidity
function _swapUSDCOut(IERC20 from, IERC20 usdc, uint256 amount, address swapProvider, bytes[] memory swapsData)
    internal
    returns (uint256 usdcReceived);
```

## Events
### Swap__TokensSwapped
emitted when the Token is successfully swapped


```solidity
event Swap__TokensSwapped(uint256 amount, address token);
```

## Errors
### Swap__SwapFailed
thrown when the swap fails for some reason(in the callee contract)


```solidity
error Swap__SwapFailed(bytes errorData);
```

### Swap__InvalidToken
thrown when the passed Token address is invalid


```solidity
error Swap__InvalidToken(address passedAddress);
```

### Swap__InsufficientFunds
thrown when trying to swap more Tokens than available in balance


```solidity
error Swap__InsufficientFunds(uint256 balance, uint256 amount);
```

### Swap__ShouldUseAllTokens
thrown when the swap does not use all available tokens for the swaps


```solidity
error Swap__ShouldUseAllTokens(uint256 providedAmount, uint256 usedAmount);
```

### Swap__USDCAmountShouldIncrease
thrown when the USDC Balance is not greater than it was before the swap
it means that the swap provider with the passed calldata didn't gave us USDC back


```solidity
error Swap__USDCAmountShouldIncrease(uint256 amountBeforeSwap, uint256 amountAfterSwap);
```

