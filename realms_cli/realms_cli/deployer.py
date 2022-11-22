"""Helper functions for repeating nre patterns."""
from nile.core.deploy import deploy
import time

def logged_deploy(nre, contract_name, alias, arguments):
    print(f"deploying {alias} contract")
    address, abi = deploy(
        contract_name,
        alias=alias,
        arguments=arguments,
        network=nre.network
    )
    print(address, abi)
    print("waiting 5 sec")
    time.sleep(5)

    return address, abi
