
import os
from nile import deployments
import logging

INITIAL_LORDS_SUPPLY = 500000000 * (10 ** 18)
NETWORK = "goerli"
admin = os.environ["ADMIN_ADDRESS"]

def run(nre):
    logging.info("deploying lords contract")
    lords_address, lords_abi = nre.deploy(
        "Lords_ERC20_Mintable",
        alias="lords",
        arguments=[
            "123",
            "1234",
            "18",
            str(INITIAL_LORDS_SUPPLY),
            "0",
            admin,
            admin,
        ],
    )
    logging.info(lords_address, lords_abi)

    logging.info("deploying lords contract")
    realms_address, realms_abi = nre.deploy(
        "Realms_ERC721_Mintable",
        alias="realms",
        arguments=[
            "1234",  # name
            "1234",  # ticker
            admin,  # contract_owner
        ],
    )
    logging.info(realms_address, realms_abi)

    logging.info("deploying s_realms contract")
    s_realms_contract, s_realms_abi = nre.deploy(
        "S_Realms_ERC721_Mintable",
        alias="s_realms",
        arguments=[
            "12345",  # name
            "12345",  # ticker
            admin,  # contract_owner
        ],
    )
    logging.info(s_realms_contract, s_realms_abi)

    logging.info("deploying resources contract")
    resources_contract, resources_abi = nre.deploy(
        "Resources_ERC1155_Mintable_Burnable",
        alias="resources",
        arguments=["1234", admin],
    )
    logging.info(resources_contract, resources_abi)
