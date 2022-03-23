[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/uQnjZhZPfu)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/LootRealms)

![This is an image](/realmslogo.jpg)

# Ξ L1-Solidity Contracts

### L1-Solidity - All Ethereum/Solidity Contracts

Individual L1 contracts live in this folder including $LORDS, the Journey, and other contracts.

**This folder contains L1-Solidity contracts. If you're looking for another contract, please see the [directory of our Realms Smart Contracts](/).**

### Game module overview

| Module          | Function                             | Current Status |
| --------------- | ------------------------------------ | -------------- |
| [DistillLoot](./loot/DistillLoot.sol)        | Distill a Loot bag into individual items. | In review      |
| [Bridge](./pre/Bridge.sol)        | Bridge Realms to StarKnet. | In review      |
| [Journey](./pre/Journey.sol)        | Journey (staking) contract for Realms. | Production      |
| [Vesting](./pre/Vesting.sol)        | Vesting contract for $LORDS. | Production      |
| [LootRealms](./tokens/LootRealms.sol)        | The original Realms NFT. | Production      |
| [TheLordsToken](./tokens/TheLordsToken.sol)        | The $LORDS ERC20 token. | Production      |

<hr>

## Understanding the code
<details><summary> 🤔 What are these contracts?</summary>
<p>
</p>
</details>
<details><summary>🏗️ System architecture</summary>

- TODO: Add system architecture here

</details>

<details><summary>📦 Contract hierarchy</summary>
<p>

- TODO: Add contract heirarchy here

</p>
</details>

<hr>

## Getting Setup

<details><summary>Initial Setup</summary>

<p>

Clone this repo and use our docker shell to interact with hardhat:

```
git clone git@github.com:BibliothecaForAdventurers/realms-contracts.git
cd realms-contracts
npm install
npm compile
```

</p>
</details>
<details><summary>Development Workflow</summary>

If you are using VSCode, we provide a development container with all required dependencies.
When opening VS Code, it should ask you to re-open the project in a container, if it finds
the .devcontainer folder. If not, you can open the Command Palette (`cmd + shift + p`),
and run “Remote-Containers: Rebuild and Reopen in Container”.

## Outline

Flow:

1. Compile the contract with the CLI
2. Test using `npm run test`
3. Deploy with CLI
4. Interact using the CLI or the explorer

### Compile

The compiler will check the integrity of the code locally.
It will also produce an ABI, which is a mapping of the contract functions
(used to interact with the contract).

Compile all contracts:

```
npm run compile
```

### Test

- TODO: Add test instructions here

### Deploy

</details>

<hr>

## Contributing

<details><summary>Modules in progress</summary>

- TODO: Add modules in progress here

</details>

<details><summary>How to Contribute</summary>

We encourage pull requests!

1. **Create an [issue](https://github.com/BibliothecaForAdventurers/realms-contracts/issues)** to describe the improvement you're making. Provide as much detail as possible in the beginning so the team understands your improvement.
2. **Fork the repo** so you can make and test changes in your local repository.
3. **Test your changes** Follow the procedures for testing in each contract sub-directory (e.g. [/contracts/settling_game](./contracts/settling_game/) and make sure your tests (manual and/or automated) pass.
4. **Create a pull request** and describe the changes you made. Include a reference to the Issue you created.
5. **Monitor and respond to comments** made by the team around code standards and suggestions. Most pull requests will have some back and forth.

If you have further questions, visit [#builders-chat in our discord](https://discord.gg/yP4BCbRjUs) and make sure to reference your issue number.

Thank you for taking the time to make our project better!

</details>
<hr>

## Realms Repositories

The Realms Settling Game spans a number of repositories:

| Content         | Repository       | Description                                              |
| --------------- | ---------------- | -------------------------------------------------------- |
| **contracts**       | [realms-contracts](https://github.com/BibliothecaForAdventurers/realms-contracts) | Starknet/Cairo and Ethereum/solidity contracts.          |
| **ui, atlas**       | [realms-react](https://github.com/BibliothecaForAdventurers/realms-react)     | All user-facing react code (website, Atlas, ui library). |
| **indexer**         | [starknet-indexer](https://github.com/BibliothecaForAdventurers/starknet-indexer) | A graphql endpoint for the Lootverse on Starknet.        |
| **bot**             | [squire](https://github.com/BibliothecaForAdventurers/squire)           | A Twitter/Discord bot for the Lootverse.                 |
| **subgraph**        | [loot-subgraph](https://github.com/BibliothecaForAdventurers/loot-subgraph)    | A subgraph (TheGraph) for the Lootverse on Eth Mainnet.  |
