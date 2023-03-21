from collections import namedtuple
from realms_cli.caller_invoker import wrapped_send, wrapped_declare
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, safe_load_deployment
from nile.common import get_class_hash

ModuleContracts = namedtuple('Contracts', 'name id')

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
        "Bastions", 17)
]

async def deploy_proxy(name, nre):
    config = Config(nre.network)

    await wrapped_declare(config.ADMIN_ALIAS, name, nre.network,
                              name)

    class_hash = get_class_hash(name)

    await logged_deploy(
        nre.network,
        config.ADMIN_ALIAS,
        'PROXY_Logic',
        alias='proxy_' + name,
        calldata=[class_hash],
    )


async def run(nre):

    config = Config(nre.network)

    #---------------- SET MODULES  ----------------#

    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
        await deploy_proxy(contract.name, nre)

        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.name,
            function="initializer",
            arguments=[
                config.CONTROLLER_PROXY_ADDRESS, config.ADMIN_ADDRESS],
        )
        module, _ = safe_load_deployment(
            "proxy_" + contract.name, nre.network)  
            
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

        # await wrapped_send(
        #     network=config.nile_network,
        #     signer_alias=config.ADMIN_ALIAS,
        #     contract_alias="arbiter",
        #     function="approve_module_to_module_write_access",
        #     arguments=[6, 1]
        # )


