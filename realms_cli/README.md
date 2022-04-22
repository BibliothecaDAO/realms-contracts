# Realms cli

## Prerequisites

This feature has been tested in 
```
python 3.7.12
---
cairo-lang==0.8.1
cairo-nile==0.6.0
```

You can install the newest version of cairo-nile by pulling the [nile repo](https://github.com/OpenZeppelin/nile.git) locally and run: `$ sudo python <path>/nile/setup.py install`
Note: you have make sure *all* previous cairo-nile packages are removed. Run `$ pip uninstall cairo-nile` and check with `$ pip freeze` if it's removed.

To install realms_cli, in the realms-contracts dir run: `$ pip install realms_cli/`

You now should have the realms_cli commands available when you run `$ nile`.

### .env file

You should have a `.env.nile` file with the following entries:
```
export STARKNET_PRIVATE_KEY=<A PRIVATE KEY>  # admin private key
expost STARKNET_NETWORK=alpha-goerli  # different from nile_network
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