# Realms Nile CLI plugin

This repo contains a CLI plugin for nile. For more info check [https://github.com/OpenZeppelin/nile#extending-nile-with-plugins]()

## Getting Started

⚠️ Best practices in crypto dictate to never store your private key anywhere on your computer.
Be wary of the possible risks and consequences and don't use an important wallet for this.

1. Export PK from Argent or other wallet.
2. Create `$ realms_cli/.env.nile`
   ```
   export MAX_FEE=8989832783197500
   export STARKNET_NETWORK=alpha-goerli
   export STARKNET_PRIVATE_KEY={PUT YOUR PRIVATE KEY IN HERE}
   ```
3. Run `$ source realms_cli/.env.nile` to load them into your env.
4. To get your public key from your private key, run `$ python scripts/get_public_key_from_private_key.py`.
5. Save the printed public key in the `goerli.accounts.json` under `address-1`.
6. Copy your address from argent and save it in both `goerli.accounts.json` and in `goerli.deployments.txt` (replacing the account-1 address)
7. Run `$ pip install realms_cli/`

## Deployment scripts

There are also some deployment scripts in here because we have access to some handy functions.

`$ nile run --network goerli deploy/game_contracts.py`

## Adding a command

1. Add your logic to `realms_cli/realms_cli/main.py`.
2. Add you cli entro to `realms_cli/pyproject.toml`.
3. Reinstall the plugin cli `$ pip install realms_cli/`.

If you're just adding functionality to existing commands, you can hot-install the realms cli with `$ pip install -e realms_cli/`

Example

```python
@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def mint_realm(realm_token_id, network):
    """
    Mint Realm
    """
    ###
    # 1. get config for a network
    ###
    config = Config(nile_network=network)

    ###
    # 2. prepare calldata
    ###
    realm_token_ids = parse_multi_input(realm_token_id)
    calldata = [
        [int(config.USER_ADDRESS, 16), id, 0] # fetch user address from config
        for id in realm_token_ids
    ]

    ###
    # 3. execute
    ###
    wrapped_send( # helper function that gives some feedback in the CLI
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_realms",
        function="mint",
        arguments=calldata
    )
```

## Running GUI

1. Install python3.9
   - Windows: https://www.python.org/downloads/release/python-3916/
   - Mac: Intall homebrew, then `brew install python@3.9`
   - Linux: https://linuxize.com/post/how-to-install-python-3-9-on-ubuntu-20-04/?utm_content=cmp-true
2. `python3 -m venv survivorvenv` or `python -m venv survivorvenv`
3. - `source survivorvenv/bin/activate` on mac/linux
   - `survivorvenv\Scripts\activate` on windows
4. `pip3 install realms_cli/` or `pip install realms_cli/`

   If fastecdsa fails then libraries needed for fastecdsa:

   - On mac: `brew install gmp gcc`
   - On linux: `sudo apt install gmp python-dev libgmp3-dev`
   - On windows:
     - gmp: http://rstudio-pubs-static.s3.amazonaws.com/493124_a46782f9253a4b8193595b6b2a037d58.html
     - gcc: https://www.guru99.com/c-gcc-install.html
       If fastecdsa architect error then run (happens on mac sometimes):
       export ARCHFLAGS="-arch x86_64"

5. `./scripts/startup.sh`
6. `python realms_cli/realms_cli/loot/gui.py`
