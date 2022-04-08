# realms-cli

This is a temp subdir to test python-starknet cli functionality.

All commands should be run from the main dir except mentioned otherwise.

### 1. Setup env

Created .env file with:

```shell
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
export STARKNET_NETWORK=alpha-goerli
```

Then run `$ source realms-cli/.env`

### 2. Deploy new account

Run `$ starknet deploy_account --account gamer` :

```jsx
Sent deploy account contract transaction.

NOTE: This is a modified version of the OpenZeppelin account contract. The signature is computed
differently.

Contract address: 0x04e54defbbf05bc7a48b8a1a04e0ce585d56304c392d28ae63bd7085d55db529
Public key: 0x057c377338d99c433a99cb96609c63d5fd3f8e3ad0c657374f1cbd5fb6190347
Transaction hash: 0x34eec60a35863413354fb83e57826a16e5e39d0ccaafd245ae2a6b8bafabbf1
```

See the transaction: [https://goerli.voyager.online/tx/0x34eec60a35863413354fb83e57826a16e5e39d0ccaafd245ae2a6b8bafabbf1](https://goerli.voyager.online/tx/0x34eec60a35863413354fb83e57826a16e5e39d0ccaafd245ae2a6b8bafabbf1)

Print details of deployment with `$ cat ~/.starknet_accounts/starknet_open_zeppelin_accounts.json` :

```jsx
{
    "alpha-goerli": {
        "gamer": {
            "private_key": "<>",
            "public_key": "0x57c377338d99c433a99cb96609c63d5fd3f8e3ad0c657374f1cbd5fb6190347",
            "address": "0x4e54defbbf05bc7a48b8a1a04e0ce585d56304c392d28ae63bd7085d55db529"
        }
    }
}
```

### 3. Get some test eth

[https://faucet.goerli.starknet.io/](https://faucet.goerli.starknet.io/)

### 4. Compile contracts

Go into your (sub)dir and run `$ nile compile`

### 5. Deploy compiled contract

`$ starknet deploy --contract realms-cli/artifacts/lanparty.json`

```shell
Deploy transaction was sent.
Contract address: 0x059966bd2a491a7202c0300ce40e1deb846caac87d9d3ad40dd9531a64012534
Transaction hash: 0x17ca3eb9fcd0d75e53af3d82b9256468179eca3a7e1079288c81cb3a22e0678
```

[https://goerli.voyager.online/tx/0x17ca3eb9fcd0d75e53af3d82b9256468179eca3a7e1079288c81cb3a22e0678](https://goerli.voyager.online/tx/0x17ca3eb9fcd0d75e53af3d82b9256468179eca3a7e1079288c81cb3a22e0678)

### 6. Run some python tests

`$ python realms-cli/test_account_fn.py`