"""Helper functions for repeating nre patterns."""
from nile.core.account import Account
from nile.core.deploy import deploy_contract
from realms_cli.config import Config
from realms_cli.utils import strhex_as_felt
import time

async def logged_deploy(nre, account, contract_name, alias, calldata):
    print(f"deploying {alias} contract")

    account = await Account(account, nre.network)

    config = Config(nile_network=nre.network)

    # seed needs to be different for every deployment, hence use of time

    current_time = time.time()
    print(int(current_time))

    address, tx_hash, abi = await deploy_contract(
        account=account,
        contract_name=contract_name,
        salt=int(current_time),
        unique=False,
        calldata=calldata,
        alias=alias,
        deployer_address=strhex_as_felt('0x041a78e741e5af2fec34b695679bc6891742439f7afb8484ecd7766661ad02bf'),
        max_fee=config.MAX_FEE
    )
    print(address, tx_hash, abi)
    print("waiting 5 sec")
    time.sleep(5)

    return address, tx_hash, abi
