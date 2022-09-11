from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
import time

# 1. Appoint new contract as Module
# 2. Give write access to specific modules


def run(nre):

    config = Config(nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="arbiter",
    #     function="appoint_contract_as_module",
    #     arguments=[strhex_as_strfelt(config.GOBLIN_TOWN_PROXY_ADDRESS), 14]
    # )

    # params: module_writing, module_writing_to
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="arbiter",
        function="approve_module_to_module_write_access",
        arguments=["6", "14"]
    )

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="arbiter",
    #     function="approve_module_to_module_write_access",
    #     arguments=[6, 2]
    # )
