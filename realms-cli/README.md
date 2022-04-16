## NILE DEPLOY

``
export STARKNET_NETWORK=goerli
``


1. Create account or set an account

``bash
export STARKNET_PRIVATE_KEY=
nile setup STARKNET_PRIVATE_KEY --network goerli
``



### GAME DEPLOYS

You need to deploy all of this 

1. nile run realms-cli/mint_tokens.py --network goerli
2. nile run realms-cli/deploy_game.py --network goerli
3. nile run realms-cli/init_game.py --network goerli


### SET METADATA
1. nile run realms-cli/mint_realm.py --network goerli

