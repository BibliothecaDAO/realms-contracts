"""Helper functions for repeating nre patterns."""

import logging
import time

def logged_deploy(nre, contract_name, alias, arguments):
    logging.info("deploying lords contract")
    address, abi = nre.deploy(
        contract_name,
        alias=alias,
        arguments=arguments,
    )
    logging.info(address, abi)
    logging.info("waiting 5 sec")
    time.sleep(5)

    return address, abi
