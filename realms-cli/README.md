# Install

1. `$ cd realms-cli && pip install -e . && cd ..`
2. You can now run the commands with `$ realms ...`

If you are getting weird errors, just call the script directly:

`$ python realms-cli cli.py mint_realms`

## Account steps

https://www.cairo-lang.org/docs/hello_starknet/account_setup.html

`$ starknet deploy_account --account_dir realms-cli/hot`

Check ./deployed_wallets for wallet info.

Add testnet ETH: https://faucet.goerli.starknet.io/