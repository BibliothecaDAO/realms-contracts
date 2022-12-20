from collections import namedtuple
from realms_cli.caller_invoker import wrapped_send, wrapped_declare, compile
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, safe_load_deployment
from realms_cli.utils import strhex_as_felt
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
        "settling_game/modules/labor/Labor", "Labor", 16)
]


async def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:

        compile(
            contract_alias="contracts/settling_game/modules/labor/Labor.cairo")

        await logged_deploy(
            nre,
            config.ADMIN_ALIAS,
            contract.alias,
            alias=contract.alias,
            calldata=[],
        )

        class_hash = await wrapped_declare(
            config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

        time.sleep(60)

        await logged_deploy(
            nre,
            config.ADMIN_ALIAS,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            calldata=[strhex_as_felt(class_hash)],
        )

    #---------------- INIT MODULES  ----------------#

    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:

        module, _ = safe_load_deployment(
            "proxy_" + contract.alias, nre.network)

        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.alias,
            function="initializer",
            arguments=[
                config.CONTROLLER_PROXY_ADDRESS, config.ADMIN_ADDRESS],
        )

        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias=config.Arbiter_alias,
            function="appoint_contract_as_module",
            arguments=[
                module,
                contract.id
            ],
        )

        # wrapped_send(
        #     network=config.nile_network,
        #     signer_alias=config.ADMIN_ALIAS,
        #     contract_alias="arbiter",
        #     function="approve_module_to_module_write_access",
        #     arguments=[6, 1]
        # )
