#!/bin/bash
set -eu

# Flow:
## The Controller is the only unchangeable contract.
## First deploy Arbiter.
## Then send the Arbiter address during Controller deployment.
## Then deploy Controller address during module deployments.

# TODO: For a network_type node open a new shell and run:
# Need to incorporate this into the script.
# `nile node`

# Network:
network_type=localhost
# network_type=mainnet

# localhost is a ShardLabs devnet locally.
# mainnet is currently Goerli/StarkNet-alpha


# Wipe old deployment record if it exists.
rm $network_type.deployments.txt || $echo 'Will create one...'


get_address () {
    # TODO read deployment address from $network_type.deployments.txt
    # Find the line containing the alias $1.
    # grep -o -m 1 '\b0x\w*'
    # echo result.
}

# Public keys of wallets (dummy/placeholder)
declare -i AdminPubKey=12345678987654321
declare -i User00PubKey=456456456

# Admin account contract
AdminAccount=nile deploy Account $AdminPubKey \
    --alias AdminAccount --network $network_type
AdminAddress=$(get_address AdminAccount)

# Arbiter contract (controlled by Admin)
Arbiter=nile deploy Arbiter $AdminAddress \
    --alias Arbiter --network $network_type
ArbiterAddress=$(get_address Arbiter)

# Module controller contract (controlled by Arbiter)
ModuleController=nile deploy ModuleController $ArbiterAddress \
    --alias ModuleController --network $network_type
ModuleControllerAddress=$(get_address ModuleController)

# The constructor of each module is passed the address of the controller.
deploy_module () {
    nile deploy $1 $ModuleControllerAddress \
        --alias $1 --network $network_type
    address=$(get_address $1)
    # TODO Export this as "module$1" to be later sent to the controller.
}

# Deploy each module.
deploy_module "01_Realms"
deploy_module "02A_Settling"
deploy_module "03A_Building"
deploy_module "04A_Resources"
deploy_module "05A_Army"
deploy_module "06A_Raiding"
deploy_module "07_PseudoRandom"


# The admin account will control the Arbiter
# and will be deployed with STARK-friendly ECDSA keypair(s). The
# key(s) will then be used to sign messages that go to the Account.
# The Account checks the signature(s) then passes the transaction data
# to the Arbiter. The Arbiter may then do things like call the
# ModuleController with information about a new module address.


nile deploy Account $User00PubKey \
    --alias User00Account --network $network_type

# Save address of controller into the arbiter
nile invoke Arbiter set_address_of_controller $ModuleControllerAddress

# These could be fetched from the deployments.txt files which
# would make the above deploy commands simpler.
# Use the Arbiter to save module addresses into the ModuleController.
nile invoke ModuleController set_initial_module_addresses \
    $module_01_Realms module_02A_Settling \
    $module_03A_Building module_04A_Resources \
    $module_05A_Army module_06A_Raiding \
    $module_07_PseudoRandom

