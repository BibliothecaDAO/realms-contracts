from collections import namedtuple
from realms_cli.caller_invoker import wrapped_send, wrapped_declare, compile
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time

ModuleContracts = namedtuple('Contracts', 'contract_name alias id')

# STEPS
# 0. Set new names in array accordingly to the tuple structure
# 1. Deploy implementation
# 2. Deploy proxy
# 3. Initialise
# 4. Set module id in controller via Arbiter
# 5. Set write access if needed
# 6. Set token contract approval if needed - Resources etc


# token tuples
MODULE_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts(
        "settling_game/modules/goblintown/GoblinTown", "GoblinTown", 14)
]


def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:

        compile(
            contract_alias="contracts/settling_game/modules/goblintown/GoblinTown.cairo")

        logged_deploy(
            nre,
            contract.alias,
            alias=contract.alias,
            arguments=[],
        )

        time.sleep(150)

        class_hash = wrapped_declare(
            config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

        time.sleep(150)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[class_hash],
        )

    #---------------- INIT MODULES  ----------------#

    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:

        module, _ = safe_load_deployment(
            "proxy_" + contract.alias, nre.network)

        wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.alias,
            function="initializer",
            arguments=[
                config.CONTROLLER_PROXY_ADDRESS, config.ADMIN_ADDRESS],
        )

        # wrapped_send(x
        #     network=config.nile_network,
        #     signer_alias=config.ADMIN_ALIAS,
        #     contract_alias=config.Arbiter_alias,
        #     function="appoint_contract_as_module",
        #     arguments=[
        #         module,
        #         contract.id
        #     ],
        # )

        # wrapped_send(
        #     network=config.nile_network,
        #     signer_alias=config.ADMIN_ALIAS,
        #     contract_alias="arbiter",
        #     function="approve_module_to_module_write_access",
        #     arguments=[6, 1]
        # )
