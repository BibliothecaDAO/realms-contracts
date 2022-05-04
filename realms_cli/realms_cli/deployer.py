"""Helper functions for repeating nre patterns."""

import time

def logged_deploy(nre, contract_name, alias, arguments):
    print(f"deploying {alias} contract")
    address, abi = nre.deploy(
        contract_name,
        alias=alias,
        arguments=arguments,
    )
    print(address, abi)
    print("waiting 5 sec")
    time.sleep(5)

    return address, abi
