# SwapProvider
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/mocks/SwapProviderMock.sol)


## Functions
### swapFromUSDC

*the @param toToken should be a mock token with a public `mint` function without restrictions*


```solidity
function swapFromUSDC(address usdc, TokenMock toToken, uint256 usdcAmount, uint256 toTokenAmount) external;
```

### swapToUSDC

*pay attention that the @param usdcAmountToReceive should be at max the received amount when
calling `swapFromUSDC`. As this function uses the usdc received from `swapFromUSDC`*


```solidity
function swapToUSDC(address fromToken, uint256 fromTokenAmount, address usdc, uint256 usdcAmountToReceive) external;
```

