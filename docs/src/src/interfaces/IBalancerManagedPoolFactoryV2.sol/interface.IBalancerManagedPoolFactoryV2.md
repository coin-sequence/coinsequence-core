# IBalancerManagedPoolFactoryV2
[Git Source](https://github.com/coin-sequence/coinsequence-core/blob/4fa1dfc99772407d2599ed268e3fe9c429c7e2d8/src/interfaces/IBalancerManagedPoolFactoryV2.sol)

*Interface of the Balancer Managed Pool Factory.
As they don't provide an Interface for it, We've created one
to not rely on low-level calls.
If you want to see the full implementation, please check their github:
https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/pool-weighted/contracts/managed/ManagedPoolFactory.sol*


## Functions
### create


```solidity
function create(
    ManagedPoolParams memory params,
    ManagedPoolSettingsParams memory settingsParams,
    address owner,
    bytes32 salt
) external returns (address pool);
```

## Structs
### ManagedPoolParams

```solidity
struct ManagedPoolParams {
    string name;
    string symbol;
    address[] assetManagers;
}
```

### ManagedPoolSettingsParams

```solidity
struct ManagedPoolSettingsParams {
    IERC20[] tokens;
    uint256[] normalizedWeights;
    uint256 swapFeePercentage;
    bool swapEnabledOnStart;
    bool mustAllowlistLPs;
    uint256 managementAumFeePercentage;
    uint256 aumFeeId;
}
```

