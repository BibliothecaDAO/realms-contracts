# Realms cli

## Prerequisites

This feature has been tested in 
```
python 3.7.12
---
cairo-lang==0.8.1
cairo-nile==0.6.0
```

1. Upgrade pip: `/usr/local/bin/python -m pip install --upgrade pip`
2. Remove *all* previous cairo nile packages: `$ pip uninstall cairo-nile` and check with `$ pip freeze` to make sure it's removed.
3. Install nile 0.6.1: `pip install cairo-nile`
4. Install the realms_cli: `$ pip install realms_cli/` (ensure you are in the realms-contracts dir)

You now should have the realms_cli commands available when you run `$ nile`.

### Create a Starknet Wallet

If you don't have a wallet yet, you'll need to [deploy one](https://www.cairo-lang.org/docs/hello_starknet/account_setup.html). You can do this via the following set of commands:
```
export STARKNET_NETWORK=alpha-goerli;
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
starknet deploy_account
```
 There are wallets (such as the [ArgentX](https://chrome.google.com/webstore/detail/argent-x/dlcobpjiigpikoobohmabehhmhfoodbb/related) chrome extension) but they do not allow you to export your private key.

You'll need to fetch the private key which is stored in ~/.starknet_accounts/starknet_open_zeppelin_accounts.json

### .env file

Create an `.env.nile` in the realms_cli/ directory with the following entries:
```
export STARKNET_PRIVATE_KEY=<A PRIVATE KEY>  # admin private key
export STARKNET_NETWORK=alpha-goerli  # different from nile_network
```

Then run `$ source realms_cli/.env.nile`

⚠️ Never commit this file!

## Deployment of the game (ADMIN ONLY)

The following scripts deploy all contracts necessairy to test and play realms on localhost/goerli.

### 1. Admin

`$ nile run --network localhost realms_cli/1_deploy_admin.py`

### 2. Deploy tokens

`$ nile run --network localhost realms_cli/2_deploy_token_contracts.py`

### 3. Deploy game contracts

`$ nile run --network localhost realms_cli/3_deploy_game_contracts.py`

### 4. Init the game

`$ nile run --network localhost realms_cli/4_init_game.py`

### Tips

If you want to check a tx hash, run either

`$ nile debug --network NETWORK TXHASH`

Or `$ starknet get_transaction_receipt --hash TXHASH` (only for non-localhost)

# New Players

`$ nile deploy account --alias player`

### Minting

`$ nile mint_realm --network localhost 1`

### Settling

`$ nile settle_realm --network localhost 1`

## Adding a plugin

Add your logic to `realms_cli/realms_cli/main.py`
Add you cli entro to `realms_cli/pyproject.toml`
Reinstall the plugin cli `pip install realms_cli/`



## TODO GAME:
- Add all building costs (should be script that pulls from json, converts to binary then sends)
- Add all resources costs (should be script that pulls from json, converts to binary then sends)

## TODO Admin:
- Add module replace 
- Add new module (deploy module, call arbiter to include)