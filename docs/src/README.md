## Coin Sequence Core

This repository contains all the source code of the Core Smart Contracts for the Coin Sequence App

## Dependencies

- **Git**

  - To know if Git is installed, run `git --version` you should see a response like `git version x.x.x`.
  - If Git is not installed, head over to [Installing Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

- **Foundry**

  - To know if Foundry is installed, run `forge --version` you should see a response like `forge x.x.x`.
  - If Foundry is not installed, head over to [Foundry Installation](https://book.getfoundry.sh/getting-started/installation)

- **Node.js**

  - To know if Node.js is installed, run `node --version` you should see a response like `vX.X.X`.
  - If Node.js is not installed, head over to [How to install Node.js](https://nodejs.org/en/learn/getting-started/how-to-install-nodejs)

- **npm**

  - To know if npm is installed, run `npm --version` you should see a response like `x.x.x`.
  - If npm is not installed, head over to [Downloading and installing Node.js and npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

- **Slither**

  - To know if Slither is installed, run `slither --version` you should see a response like `x.x.x`.
  - If Slither is not installed, head over to [How to install Slither](https://github.com/crytic/slither?tab=readme-ov-file#how-to-install)

## Getting Started

1. Clone the repository
2. Run `npm install` to install all dependencies

### Running Tests

You can run all tests by running

```shell
npm run test
```

### Linting

You can run the solhint linter by running

```shell
npm run lint
```

### Slither

You can run the slither static analysis by running

```shell
npm run analyze
```

### Deploy

We use thirdweb CLI tools to deploy most of our contracts. Just run

```shell
npm run deploy
```

And choose the contract that you want to deploy.

### Verify

Sometimes the Thirdweb CLI tools can't verify your contract, you can manually
verify it by running

```shell
npm run verify
```

It will ask you some arguments: `address`, `contract`, `chain` and `rpc`.

- Address: The address of the contract you want to verify
- Contract: The name of the contract you want to verify or the path to the contract
- Chain: The chain you want to verify the contract on
- RPC: The RPC URL you want to use to verify the contract

**Your verify command should look like this**

```shell
npm run verify --address={ContractAddress} --contract={Contract} --chain={ChainNameOrId} --rpc={RPCUrl}
```

**Real Example**

```shell
npm run verify --address=0x6c23B5382b47EF1e91c59ac48D53a595Fd49a70A --contract=CTF --chain=11155420 --rpc=https://optimism-sepolia-rpc.publicnode.com
```
