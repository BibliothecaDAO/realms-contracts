# Realms Settling Game

### The Realms Settling Game - based on the Realms derivative NFT of the Loot Project

A modular game engine architecture for the StarkNet L2 roll-up - Forked & heavily inspired by the pioneering work done by the Dope Ware RYO game [here](https://github.com/dopedao/RYO).

## What is the game?

Settling is an on-chain game of economics and Chivarly built on-top of ZK-STARKS. Earn resources by staking your Realms, raid rivals, steal loot & form on-chain alliances to crush your enemies.

Settling is entirely on-chain; the UI is purely just a client for a distributed backend. Feel free to create your own superior client if you wish.

Picture a million players all asynchronously working the blockchain; harvesting resources, building alliances, & slaying foes. This is Settling.

Settling is all open-source and we encourage people to build modules and contribute.

Requirements: To play be a Lord you require a Realm from the Lootverse. The game will support more Loot derivatives in the future to enrich the gameplay.
<hr>

## System architecture

The game mechanics are separated from the game state variables.

A controller system manages a mapping of modules to deployed addresses and a governance module may update the controller.

For example all these modules could read and write from the state modules and be connected-but-distinct game interactions:

<hr>

## Contract hierarchy

It is also worth pointing out that StarkNet has account abstraction
(see background notes [here](https://perama-v.github.io/cairo/examples/test_accounts/)).
This means that transactions are actioned by sending a payload to a personal
Account contract that holds your public key. The contract checks the payload
and forwards it on to the destination.

- Player Account
    - A Lord in the Realmverse. These are holders of Realms.
- Governance Account
    - An admin who controls the Arbiter.
    - The admin may be an L2 DAO to administer governance decisions
    voted through on L2, where voting will be cheap.
    - Governance might enable a new module to have write-access to
    and important game variable. For example, to change the location
    that a player is currently in. All other modules that read and use location
    would be affected by this.
- Arbiter (most power in the system).
    - Can update/add module mappings in ModuleController.
- ModuleController (mapping of deployments to module_ids).
    - The game 'swichboard' that connects all modules.
    - Is the reference point for all modules. Modules call this
    contract as the source of truth for the address of other modules.
    - The controller stores where modules can be found, and which modules
    have write access to other modules.
- Modules (open ended set)
    - Game mechanics (where a player would interact to play). 
    - Storage modules (game variables).
    - L1 connectors (for integrating L1 state/ownership to L2)
    - Other arbitrary contracts
    - Module logic contained in A (e.g 02A_Settling.cairo) and state in B (02B_Settling.cairo)

For more information see

- Modular [system architecture](./system_architecture.md).
- Descriptions of example modules in [module notes](/module_notes).

<hr>

## Setup

Clone this repo and use our docker shell to interact with starknet:

```
git clone git@github.com:BibliothecaForAdventurers/RealmsSettling.git
cd RealmsSettling
bin/shell starknet --version
```

The CLI allows you to deploy to StarkNet and read/write to contracts
already deployed. The CLI communicates with a server that StarkNet
runs, which bundles the requests, executes the program (contracts are
Cairo programs), creates and aggregates validity proofs, then posts them
to the Goerli Ethereum testnet. Learn more in the Cairo language and StarkNet
docs [here](https://www.cairo-lang.org/docs/), which also has instructions for manual
installation if you are not using docker.

### Development workflow

If you are using VSCode, we provide a development container with all required dependencies.
When opening VS Code, it should ask you to re-open the project in a container, if it finds
the .devcontainer folder. If not, you can open the Command Palette (`cmd + shift + p`),
and run “Remote-Containers: Rebuild and Reopen in Container”.

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
```
nile compile
```

Compile an individual contract:
```
nile compile contracts/02A_Settling.cairo
```

### Test

Run all github actions tests: `bin/test`

Run individual tests
```
bin/shell pytest -s testing/l2/01_Realms_contract_test.py
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
bin/deploy
```
<hr>

## Contributing and next steps

Module Priority
[x] Settling 
[x] Buildings
[x] Resources
[]  Army Building
[] Raiding

Building out parts to make a functional `v1`

## Binary bit encoding

To minimise storage costs (we should always do this where we can) we back felts with binary numbers

For the Realms Data we are storing all the traits, resources and wonders within a single felt.

This technique was borrowed from the Dopewars engine (credit goes to @eth_worm)

#### Define the values in binary

```
struct RealmData:
    member cities : felt  # eg: 7 citees = 111 
    member regions : felt  # eg: 4 regions = 100 
    member rivers : felt  # eg: 60 rivers = 111100 
    member harbours : felt  #  eg: 10 harbours = 1010 
    member resource_number : felt  #  eg: 5 resource_number = 101 
    member resource_1 : felt  # eg: 1 resource_1 = 1 
    member resource_2 : felt  # eg: 2 resource_2 = 10 
    member resource_3 : felt  # eg: 3 resource_3 = 11 
    member resource_4 : felt  # eg: 4 resource_4 = 100
    member resource_5 : felt  # eg: 5 resource_5 = 101
    member resource_6 : felt  # eg: 10 resource_6 = 0 (0 if no resource)
    member resource_7 : felt  # eg: 10 resource_7 = 0 (0 if no resource)
    member wonder : felt  # eg: 50 wonder = 110010 (50 wonders)  
end
```

#### Pack binary bits

Define our large the mask is needed for a value.

We will use rivers as an example since it's highest value is 60, which equates to 7 bits. So we will use an 8 bit mask on all values to keep things consistent (this could be what ever you like)

So starting from the first value, take the bit number and add on 0 to make an 8 bit number

eg: 
```
trait    bit   8 bit number

cities = 111 = 00000111
regions = 100 = 00000001
rivers = 111100 = 00111100
harbours = 1010 = 00001010
resource_number = 00000101
resource_1 = 00000001 
resource_2 = 00000010 
resource_3 = 00000011
resource_4 = 00000100
resource_5 = 00000101
resource_6 = 00000000 
resource_7 = 00000000
wonder = 00110010
order = 00000010

Then concatanate the values

0000001000110010000000000000000000000101000001000000001100000010000000010000010100001010001111000000000100000111
```

Then convert to decimal and this is the realms traits to store in the felt:

```
44526227356702393855067989737735
```

Then this function will unpack the the decimal into bits

```
unpack_realm_data()
```


Same method is used for packing the values of resources needed to upgrade a resource

```
resource_1 = 1 = 00000001
resource_2 = 2 = 00000010  
resource_3 = 3 = 00000011
resource_4 = 4 = 00000100
resource_5 = 5 = 00000101
resource_1_values = 00001010
resource_2_values = 00001010   
resource_3_values = 00001010     
resource_4_values = 00001010   
resource_5_values = 00001010

00001010000010100000101000001010000010100000010100000100000000110000001000000001

47408855671140352459265
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

# values 14 bit - max 10000
resource_1_values = 000000001010
resource_2_values = 000000001010   
resource_3_values = 000000001010     
resource_4_values = 000000001010   
resource_5_values = 000000001010

000000001010000000001010000000001010000000001010000000001010

2815437129687050
```

## Calculator Logic Module

'Storage is expensive, compute is cheap' - I wise man one said this... (@eth_worm)

Calldata will always be expensive on decentralised blockchain. StarkNet allows cheap computation, so where possible we should always compute the value rather than save in the state.

Settling of the Realms contains many computed values that get parsed around the dapp. The calculations for all these should be maintained within a central calculator logic contract. This contract contains no state at all, and can be upgraded easily.

