[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/uQnjZhZPfu)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/LootRealms)

<!-- badges -->
<p>
  <a href="https://starkware.co/">
    <img src="https://img.shields.io/badge/powered_by-StarkWare-navy">
  </a>
  <a href="https://github.com/dontpanicdao/starknet-burner/blob/main/LICENSE/">
    <img src="https://img.shields.io/badge/license-MIT-black">
  </a>
</p>

![Realms x Bibliotheca header](/static/realmsxbibliotheca.jpg)

# Realmverse Contracts

## Realms is an ever-expanding on-chain permission-less gaming Lootverse built on StarkNet. 

### This monorepo contains all of the Contracts (StarkNet/Cairo Ethereum/Solidity) for Bibliotheca DAO, $LORDS, and Realms.

---

# Contracts
| Directory | Title | Description                     |
| --------- | ----- | ------------------------------- |
| [/settling_game](./contracts/settling_game) | The Realms Settling Game | A modular game engine architecture built on StarkNet. |
| [/desiege](./contracts/desiege) | Desiege | A web-based team game built on Starknet. |
| [/loot](./contracts/loot/) | Loot | Loot contracts ported to Cairo. |
| [/exchange](./contracts/exchange/) | Exchange | Allows trades between pairs of ERC20 and ERC1155 contract tokens. |
| [/nft_marketplace](./contracts/nft_marketplace/) | NFT Marketplace | A marketplace for Realms, Dungeons, etc. built on Starknet. |

---
# Learn more about Realms

## Follow these steps bring a 🔦

## 1. Visit the [Bibliotheca DAO Site](https://bibliothecadao.xyz/) for an overview of our ecosystem

## 2. The [Master Scroll](https://scroll.bibliothecadao.xyz/). This is our deep dive into everything about the game. The Master Scroll is the source of truth before this readme

## 3. Visit [The Atlas](https://atlas.bibliothecadao.xyz/) to see the Settling game in action

## 4. Get involved at the [Realms x Bibliotheca Discord](https://discord.gg/uQnjZhZPfu)

---

# Development

https://development.bibliothecadao.xyz/docs/getting-started/environment

---
## Realms Repositories

The Realms Settling Game spans a number of repositories:

| Content         | Repository       | Description                                              |
| --------------- | ---------------- | -------------------------------------------------------- |
| **contracts**       | [realms-contracts](https://github.com/BibliothecaForAdventurers/realms-contracts) | StarkNet/Cairo and Ethereum/solidity contracts.          |
| **ui, atlas**       | [realms-react](https://github.com/BibliothecaForAdventurers/realms-react)     | All user-facing react code (website, Atlas, ui library). |
| **indexer**         | [starknet-indexer](https://github.com/BibliothecaForAdventurers/starknet-indexer) | A graphql endpoint for the Lootverse on StarkNet.        |
| **bot**             | [squire](https://github.com/BibliothecaForAdventurers/squire)           | A Twitter/Discord bot for the Lootverse.                 |
| **subgraph**        | [loot-subgraph](https://github.com/BibliothecaForAdventurers/loot-subgraph)    | A subgraph (TheGraph) for the Lootverse on Eth Mainnet.  |
