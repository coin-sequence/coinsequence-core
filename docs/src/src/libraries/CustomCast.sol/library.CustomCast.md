# CustomCast
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/libraries/CustomCast.sol)


## Functions
### toIERC20List

converts an address list to an IERC20 list

*take care when using this function, as it does not check if the
address is a valid IERC20(OpenZeppelin version), it just converts
the address to the IERC20 type*


```solidity
function toIERC20List(address[] memory tokens) internal pure returns (IERC20[] memory tokensAsIERC20);
```

### toIAssetList

converts an address list to an IAsset list

*take care when using this function, as it does not check if the
address is a valid IAsset, it just converts
the address to the IAsset type*


```solidity
function toIAssetList(address[] memory tokens) internal pure returns (IAsset[] memory tokensAsIAsset);
```

