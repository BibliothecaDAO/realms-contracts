# Single Sided Staking

This example builds a single-sided staking vault on top of our ERC4626 template. Inspired by
the Lords Nexus staking vault concept. A single asset (e.g, $TOKEN) is deposited to get the staked
version of this asset ($stTOKEN). New rewards can either be directly send to the vault address
or sent to a designated splitter contract. The vault can check its accumulated holdings in the
splitter contract or claim them when needed to service deposits. The splitter contract can be used
to split rewards that need to accrue into multiple staking contracts.

## :warning: WARNING! :warning:

This code is entirely experimental, changing frequently and un-audited. Please do not use it in production!

## How to use

- First make sure you understand the ERC4626 contract interface and implications as it pertains to your vault
- Develop a splitter contract (if needed) that follows the `ISplitter` interface
- If not needed, remove `ISplitter` references from the code (intelligently)
- Add tests for correctness :), this is just an illustrative example and has not been extensively tested

## Thanks to

- [Lord of a few](https://twitter.com/lordOfAFew) for creating the Nexus use case and brainstorming solutions
