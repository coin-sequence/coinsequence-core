## CTF Core

This repository contains all the source code of the Smart Contracts for the CTF Tokens

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

- **NPM**

  - To know if NPM is installed, run `npm --version` you should see a response like `x.x.x`.
  - If NPM is not installed, head over to [Downloading and installing Node.js and npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

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

⚠️ If all tests pass, it will also open the coverage report.

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

In case of more complex deployments, we use Foundry Scripts.
One of them is the Engine, to deploy the Engine just run:

```shell
npm run deploy-engine
```
