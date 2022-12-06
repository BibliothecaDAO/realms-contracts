"""Helper functions for repeating nre patterns."""
from nile.core.account import Account
from nile.core.deploy import deploy_contract
from realms_cli.config import Config
import time

async def logged_deploy(nre, account, contract_name, alias, calldata):
    print(f"deploying {alias} contract")

    account = await Account(account, nre.network)

    config = Config(nile_network=nre.network)

    address, tx_hash, abi = await deploy_contract(
        account=account,
        contract_name=contract_name,
        salt=0,
        unique=False,
        calldata=calldata,
        alias=alias,
        deployer_address=account.address,
        max_fee=config.MAX_FEE
    )
    print(address, tx_hash, abi)
    print("waiting 5 sec")
    time.sleep(5)

    return address, tx_hash, abi
