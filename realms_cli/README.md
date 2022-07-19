
---

<details><summary>Admin Actions</summary>


The following scripts deploy all contracts necessary to test and play realms on localhost/goerli (ADMIN ONLY).

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

`$ nile run --network localhost realms_cli/7_upgrade.py`

`$ nile run --network goerli realms_cli/8_deploy_AMM.py`

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
# Notes on proxy deployments 

<details><summary>Must read first</summary>

Proxy contracts have some quirks which you must understand before playing with them.

1. Proxies do not know what functions they have in them. This means you need to use the implementation abi when calling them.
2. This means when you have deployed them you must replace the .json of the proxy with the implementation .json - Seen below

```
0x0708ccaad83939596224933ffc265cf468aeaccabac7bbe6d04fee416308785d:artifacts/abis/Exchange_ERC20_1155.json:Exchange_ERC20_1155
0x01dc57f37705770448008e8083da883a06d81b28f01c6a398a010fff12703401:artifacts/abis/Exchange_ERC20_1155.json:proxy_Exchange_ERC20_1155
```

</details>

---
# Common Errors

<strong><pre>{"code": "StarknetErrorCode.UNINITIALIZED_CONTRACT", "message": "Contract with address 0x6352aa8d59cb656526162e3fd5017bcc02a8f6f1036748cb7221a8f30e89770 is not deployed."}.</pre></strong>

First - wait 30 seconds and try again as the deployment doesn't happen immediately. 

If you're still getting this error, it likely means that your goerli.deployments.txt doesn't have account-1 (user account) or is appending the account to account-2. 

Restore your goerli.deployments.txt to its original state (use `main` branch as source of truth). Next, delete the line with account-1 (and account-2 if it exists) and re-run `nile setup STARKNET_PRIVATE_KEY --network goerli` to re-add add your private key to goerli.deployments.txt.

<strong><pre>`    int(config.USER_ADDRESS, 16),  # felt
TypeError: int() can't convert non-string with explicit base`</pre></strong>

This error means that your user address (account-1) in the file goerli.deployments.txt is not being read correctly. Make sure your account-1 line is on its own line and contains the correct address. In some cases, the account-1 will be appended to an existing line so move it to its own line.


----


1. Export PK from Argent
2. Save as STARKNET_PRIVATE_KEY in env
3. `source realms_cli/.env.nile`
4. `python scripts/script.py`
5. Save the printed public key in the goerli.accounts.json in address-1
6. Copy your address from argent and save it in both goerli.accounts.json and in goerli.deployments.txt (replacing the account-1 address)
7. `pip install realms_cli/`