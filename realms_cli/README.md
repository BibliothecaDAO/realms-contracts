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
export STARKNET_PRIVATE_KEY=<A PRIVATE KEY>  # admin private key - see below to generate
export STARKNET_NETWORK=alpha-goerli  # different from nile_network

```
⚠️ Never commit this file!
</details>

---

## Actions


<details><summary>Create Wallet via CLI</summary>

NOTE: This is the temporary solution until native ArgentX integration

1. Create private Key via `$ nile create_pk`
2. Save in .env.nile as STARKNET_PRIVATE_KEY in the realms_cli directory 
3. Run `$ source realms_cli/.env.nile`
4. Run `$ nile setup STARKNET_PRIVATE_KEY --network goerli`
5. Your address will be saved in the goerli.accounts.json
</details>

---

<details><summary>Deployment of the full game (ADMIN ONLY) [localhost/goerli]</summary>


The following scripts deploy all contracts necessairy to test and play realms on localhost/goerli.

### 1. Admin

`$ nile run --network localhost realms_cli/1_deploy_admin.py`

### 2. Deploy tokens

`$ nile run --network localhost realms_cli/2_deploy_token_contracts.py`

### 3. Deploy game contracts

`$ nile run --network localhost realms_cli/3_deploy_game_contracts.py`

### 4. Init the game

`$ nile run --network localhost realms_cli/4_init_game.py`

### 5. Set Costs

`$ nile run --network localhost realms_cli/5_set_costs.py`

### 6. Troops (or any other new module that needs adding updating)

`$ nile run --network localhost realms_cli/6_deploy_troops.py`

### Tips

If you want to check a tx hash, run either

`$ nile debug --network NETWORK TXHASH`

Or `$ starknet get_transaction_receipt --hash TXHASH` (only for non-localhost)

### Adding a plugin

Add your logic to `realms_cli/realms_cli/main.py`
Add you cli entro to `realms_cli/pyproject.toml`
Reinstall the plugin cli `pip install realms_cli/`

</details>

---
<details><summary>Player Actions [goerli]</summary>

---

### Mint Realm

`$ nile mint_realm 1`

If your tx fails, someone has already minted this realm

---

### Set Metadata (use as temporary until production)

`$ nile set_realm_data 1`

---

### Approve your Realms for game usage

`$ nile approve_realm`

---

### Settling

`$ nile settle_realm 1`

---

### Check lords [wip]

`$ nile check_lords`

---

### check realms [wip]

`$ nile check_realms`

---

### Check resources

`$ nile check_resources`

Of another user:

`$ nile check_resources --address 0x000000`

---

### Claim resources

Claims specific realms resources

`$ nile claim_resources 1`

</details>

---

## TODO

#### Game:
- Add all building costs (should be script that pulls from json, converts to binary then sends)
- Add all resources costs (should be script that pulls from json, converts to binary then sends)

#### Admin:
- Add module replace 
- Add new module (deploy module, call arbiter to include)