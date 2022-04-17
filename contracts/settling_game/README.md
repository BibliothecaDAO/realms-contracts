[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/uQnjZhZPfu)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/LootRealms)

![This is an image](/static/realmsxbibliotheca.jpg)

# 🏰 Realms Settling Game

### The Realms Settling Game - based on the Realms derivative NFT of the Loot Project

A modular game engine architecture for the StarkNet L2 roll-up - Forked & heavily inspired by the pioneering work done by the Dope Ware RYO game [here](https://github.com/dopedao/RYO).

**This folder contains Settling Game contracts. If you're looking for another contract, please see the [directory of our Realms Smart Contracts](/).**

### Game module overview

| Module          | Function                             | Current Status |
| --------------- | ------------------------------------ | -------------- |
| [Settling](./L01_Settling.cairo)        | Manages Settling (staking functions) | In review      |
| [Resources](./L02_Resources.cairo)       | Resource management                  | In review      |
| [Buildings](./L03_Buildings.cairo)       | Buildings management                 | In review      |
| [Calculator](./L04_Calculator.cairo)      | Calculator management                | In review      |
| [Combat](./L06_Combat.cairo)          | Combat simulator                     | In review      |
| Wonder Tax      | Wonder tax calculator                | In review      |
| Crafting        | Crafting                             | Draft          |
| Barbarian Horde | Characters can summon                | Planned        |
| Guilds          | p2g trading                          | Planned        |

<hr>

## Understanding the code
<details><summary> 🤔 What is the game?</summary>

<hr>

### Picture a million players all asynchronously working the blockchain; harvesting resources, building alliances, & slaying foes.

*Step one* -> Read the [Master Scroll](https://docs.bibliothecadao.xyz/lootverse-master-scroll/
). This is our deep dive into everything about the game. The Master Scroll is the source of truth before this readme.

tldr; <br>
Settling is an on-chain game of economics and Chivarly built on-top of ZK-STARKS. Earn resources by staking your Realms, raid rivals, steal loot & form on-chain alliances to crush your enemies.

Settling is entirely on-chain; the UI is purely just a client for a distributed backend. Feel free to create your own superior client if you wish.

The game is all open-source and we encourage people to build modules and contribute.

</details>

<details><summary>📦 Contract hierarchy</summary>

### Player Account
  - A player with a wallet
  
### Governance Account
  - An admin who controls the Arbiter.
  - The admin may be an L2 DAO to administer governance decisions
    voted through on L2, where voting will be cheap.
  - Governance might enable a new module to have write-access to
    and important game variable. For example, to change the location
    that a player is currently in. All other modules that read and use location
    would be affected by this.
### Arbiter (most power in the system).
  - Can update/add module mappings in ModuleController.
### ModuleController (mapping of deployments to module_ids).
  - The game 'swichboard' that connects all modules.
  - Is the reference point for all modules. Modules call this
    contract as the source of truth for the address of other modules.
  - The controller stores where modules can be found, and which modules
    have write access to other modules.
### Modules (open ended set)
  - Game mechanics (where a player would interact to play).
  - Storage modules (game variables).
  - L1 connectors (for integrating L1 state/ownership to L2)
  - Other arbitrary contracts
  - Module logic contained in L (e.g L_Settling.cairo) and state in S (S_Settling.cairo)

</details>

<hr>

## Getting Setup

<details><summary>Initial Setup</summary>


Clone this repo and use our docker shell to interact with starknet:

``` bash
git clone git@github.com:BibliothecaForAdventurers/realms-contracts.git
cd realms-contracts
scripts/shell starknet --version
```

The CLI allows you to deploy to StarkNet and read/write to contracts
already deployed. The CLI communicates with a server that StarkNet
runs, which bundles the requests, executes the program (contracts are
Cairo programs), creates and aggregates validity proofs, then posts them
to the Goerli Ethereum testnet. Learn more in the Cairo language and StarkNet
docs [here](https://www.cairo-lang.org/docs/), which also has instructions for manual
installation if you are not using docker.


</details>

**For details on the development workflow and using our development container with VSCode, view the [main project README](/README.md).**

If you need to authenticate in your container, we recommend using [GitHub command line](https://github.com/cli/cli/blob/trunk/docs/install_linux.md). Install the cli and use the command `gh auth login` to generate an ssh keypair and login in your container. This will _not_ be shared outside of your local computer.

## Outline

Flow:

1. Compile the contract with the CLI
2. Test using pytest
3. Deploy with CLI
4. Interact using the CLI or the explorer

### Compile

The compiler will check the integrity of the code locally.
It will also produce an ABI, which is a mapping of the contract functions
(used to interact with the contract).

Compile all contracts:

```bash
bash scripts/compile
```

Compile an individual contract:

```bash
export CAIRO_PATH=/workspaces/realms-contracts/openzeppelin/src
nile compile contracts/02A_Settling.cairo
```

### Test

Run all github actions tests: `scripts/test`

Run individual tests

```
scripts/shell pytest -s testing/l2/01_Realms_contract_test.py
```

### Deploy

Start up a local StarkNet devnet with:

```
nile node
```

Then run the deployment of all the contracts. This uses nile
and handles passing addresses between the modules to create a
permissions system.

```
scripts/deploy
```

### Common Issues

**Issue: Module Not Found when running tests**
```ModuleNotFoundError: No module named 'starkware.starknet.business_logic.execution'```

Solution: Dependencies are missing. Run `pip install requirements.txt` and report this issue in #builders as the container should take care of this automagically.

**Issue: Unable to run `git pull`**
```git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.```

Solution: Install the [Github CLI](https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt), run `gh auth login` and make sure you **re-authenticate.** 

When you see this prompt, select **Yes**: `? You're already logged into github.com. Do you want to re-authenticate?`

This will update the private key in your ~/.ssh file.



</details>

<hr>

## Contributing

<details><summary>Modules in progress</summary>

- [x] Settling
- [x] Buildings
- [x] Resources
- [x] Army Building
- [x] Raiding
- [] Crafting
- [] Guilds

</details>

<details><summary>How to Contribute</summary>

We encourage pull requests!

</details>
<hr>

## Logic Patterns

<details><summary>Binary bit encoding</summary>
To minimise storage costs (we should always do this where we can) we back felts with binary numbers

For the Realms Data we are storing all the traits, resources and wonders within a single felt.

This technique was borrowed from the Dopewars engine (credit goes to @eth_worm)

#### Define the values in binary

```
struct RealmData:
    member cities : felt  # eg: 7 cities = 111
    member regions : felt  # eg: 4 regions = 100
    member rivers : felt  # eg: 60 rivers = 111100
    member harbours : felt  #  eg: 10 harbours = 1010
    member resource_number : felt  #  eg: 5 resource_number = 101
    member resource_1 : felt  # eg: 1 resource_1 = 1
    member resource_2 : felt  # eg: 2 resource_2 = 10
    member resource_3 : felt  # eg: 3 resource_3 = 11
    member resource_4 : felt  # eg: 4 resource_4 = 100
    member resource_5 : felt  # eg: 5 resource_5 = 101
    member resource_6 : felt  # eg: 0 resource_6 = 0 (0 if no resource)
    member resource_7 : felt  # eg: 0 resource_7 = 0 (0 if no resource)
    member wonder : felt  # eg: 50 wonder = 110010 (50 wonders)
    member order : felt # eg: 3 = 11
end
```

#### Pack binary bits

Define how large the mask is needed for a value.

We will use rivers as an example since it's highest value is 60, which equates to 6 bits. We will use an 8 bit mask on all values to keep things consistent (this could be what ever you like).

Next, take the binary values and create their 8 bit representations, e.g.:

| trait           | decimal | binary | 8 bit      |
| --------------- | ------- | ------ | ---------- |
| cities          | 7       | 111    | `00000111` |
| regions         | 4       | 100    | `00000100` |
| rivers          | 60      | 111100 | `00111100` |
| harbours        | 10      | 1010   | `00001010` |
| resource_number | 5       | 101    | `00000101` |
| resource_1      | 1       | 1      | `00000001` |
| resource_2      | 2       | 10     | `00000010` |
| resource_3      | 3       | 11     | `00000011` |
| resource_4      | 4       | 100    | `00000100` |
| resource_5      | 5       | 101    | `00000101` |
| resource_6      | 0       | 0      | `00000000` |
| resource_7      | 0       | 0      | `00000000` |
| wonder          | 50      | 110010 | `00110010` |
| order           | 3       | 10     | `00000011` |

Then concatenate the 8 bit values. This way, you'll get a 112 bit number (14 values \* 8 bits for each value). The value for cities (`00000111`) will be the least significant ("rightmost") and the value for order (`00000011`) will be the most significant ("leftmost") position:

```
0000001100110010000000000000000000000101000001000000001100000010000000010000010100001010001111000000010000000111
```

Then convert to decimal and this is the realms traits to store in the felt:

```
64808636960354064279015241024519
```

Then this function will unpack the the decimal into bits

```
unpack_data()
```

Same method is used for packing the values of resources needed to build

```
# ids - 8 bit
resource_1 = 5 = 00000001
resource_2 = 10 = 00000010
resource_3 = 12 = 00000011
resource_4 = 21 = 00000100
resource_5 = 9 = 00000101

0000010100000100000000110000001000000001

21542142465

# values 14 bit - max 10000 = 0b10011100010000
resource_1_values = 00000000001010
resource_2_values = 00000000001010
resource_3_values = 00000000001010
resource_4_values = 00000000001010
resource_5_values = 00000000001010

0000000000101000000000001010000000000010100000000000101000000000001010

720619923528908810
```

</details>

<details><summary>Calculator logic</summary>
<p>

'Storage is expensive, compute is cheap' - I wise man once said this... (@eth_worm)

Calldata will always be expensive on decentralised blockchain. StarkNet allows cheap computation, so where possible we should always compute the value rather than save in the state.

Settling of the Realms contains many computed values that get parsed around the dapp. The calculations for all these should be maintained within a central calculator logic contract. This contract contains no state at all, and can be upgraded easily.

</p>
</details>

<hr>

## External Reading Sources

StarkNet is very new. Best practices are being discovered. We have amalgamated the best resources we think to guide you on your journey.

<details><summary>Guides & Docs</summary>

- https://perama-v.github.io/cairo/intro/
- https://hackmd.io/@RoboTeddy/BJZFu56wF
- https://starknet.io/docs/
</details>
<details><summary>Discords to Join</summary>

- [Bibliotheca DAO](https://discord.gg/uQnjZhZPfu)
- [StarkNet](https://discord.gg/XzvgKTTptb)
- [MatchBox DAO](https://discord.gg/uj7wMxsmYw)
</details>
<hr>

## Realms Repositories

The Realms Settling Game spans a number of repositories:

**[View the list of repositories in /README.md](/README.md#realms-repositories)**