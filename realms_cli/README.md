# Realms cli

## Prerequisites

This feature has been tested in 
```
python 3.7.12
---
cairo-lang==0.8.1
cairo-nile==0.6.1
```

<details><summary>Python Setup</summary>

1. Upgrade pip: `/usr/local/bin/python -m pip install --upgrade pip`
2. Remove *all* previous cairo nile packages: `$ pip uninstall cairo-nile` and check with `$ pip freeze` to make sure it's removed.
3. Install nile 0.6.1: `pip install cairo-nile`
4. Install the realms_cli: `$ pip install realms_cli/` (ensure you are in the realms-contracts dir)

You now should have the realms_cli commands available when you run `$ nile`. 

</details>

<details><summary>Enviroment Setup</summary>

Create an `.env.nile` in the realms_cli/ directory with the following entries:

```
export STARKNET_PRIVATE_KEY=<A PRIVATE KEY>  # admin private key
export STARKNET_NETWORK=alpha-goerli  # different from nile_network

```
⚠️ Never commit this file!
</details>



---

## Actions


<details><summary>Create Wallet via CLI</summary>
1. Create private Key via XYZ
2. Save in .env.nile as STARKNET_PRIVATE_KEY
3. `$ source realms_cli/.env.nile`
4. Run `$ nile setup STARKNET_PRIVATE_KEY --network goerli`
5. Your address will be saved in the goerli.accounts.json
</details>

---

<details><summary>Deployment of the full game (ADMIN ONLY)</summary>


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

</details>

---
<details><summary>Player Actions</summary>


### Deploy account

`$ nile deploy account`

### Minting

`$ nile mint_realm --network localhost 1`

### Settling

`$ nile settle_realm --network localhost 1`

## Adding a plugin

Add your logic to `realms_cli/realms_cli/main.py`
Add you cli entro to `realms_cli/pyproject.toml`
Reinstall the plugin cli `pip install realms_cli/`

</details>

---

# TODO

#### Game:
- Add all building costs (should be script that pulls from json, converts to binary then sends)
- Add all resources costs (should be script that pulls from json, converts to binary then sends)

#### Admin:
- Add module replace 
- Add new module (deploy module, call arbiter to include)