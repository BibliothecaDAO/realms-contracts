"""Helper functions for repeating nre patterns."""
from nile.core.types.account import Account
from realms_cli.caller_invoker import get_tx_status
import time


async def logged_deploy(network, account, contract_name, alias, calldata):
    print(f"deploying {alias} contract")

    account = await Account(account, network)

    current_time = time.time()

    tx_wrapper = await account.deploy_contract(
        contract_name=contract_name,
        salt=int(current_time),
        unique=False,
        calldata=calldata,
        alias=alias,
        max_fee=11111111111111
    )

    await tx_wrapper.execute(watch_mode='track')

    get_tx_status(network, str(tx_wrapper.hash),)

    return tx_wrapper
