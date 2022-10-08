from collections import namedtuple
from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send, declare
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time
from enum import IntEnum


class ModuleId(IntEnum):
    Settling = 1
    Resources = 2
    Buildings = 3
    Calculator = 4
    Combat = 6
    L07_Crypts = 7
    L08_Crypts_Resources = 8
    Relics = 12
    Food = 13
    GoblinTown = 14
    Travel = 15
    Crypts_Token = 1001
    Lords_Token = 1002
    Realms_Token = 1003
    Resources_Token = 1004
    S_Crypts_Token = 1005
    S_Realms_Token = 1006


Contracts = namedtuple('Contracts', 'alias contract_name')
ModuleContracts = namedtuple('Contracts', 'alias contract_name id')

CONTROLLER_CONTRACT_IMPLEMENTATIONS = [
    Contracts("Arbiter", "Arbiter"),
    Contracts("ModuleController", "ModuleController")
]

# token tuples
MODULE_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts("Settling", "Settling", ModuleId.Settling),
    ModuleContracts("Resources", "Resources", ModuleId.Resources),
    ModuleContracts("Buildings", "Buildings", ModuleId.Buildings),
    ModuleContracts("Calculator", "Calculator", ModuleId.Calculator),
    ModuleContracts("Combat", "Combat", ModuleId.Combat)
]


def run(nre):

    config = Config(nre.network)

    #---------------- CONTROLLERS  ----------------#
    for contract in CONTROLLER_CONTRACT_IMPLEMENTATIONS:

        # logged_deploy(
        #     nre,
        #     contract.contract_name,
        #     alias=contract.alias,
        #     arguments=[],
        # )

        declare(contract.contract_name, contract.alias)

        predeclared_class = nre.get_declaration(contract.alias)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[strhex_as_strfelt(predeclared_class)],
        )

    # predeclared_class = nre.get_declaration(contract.alias)
    # print(predeclared_class)

    # wait 120s - this will reduce on mainnet
    print('🕒 Waiting for deploy before invoking')
    # time.sleep(60)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="initializer",
    #     arguments=[strhex_as_strfelt(config.ADMIN_ADDRESS)],
    # )

    # module, _ = safe_load_deployment("proxy_Arbiter", nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_ModuleController",
    #     function="initializer",
    #     arguments=[strhex_as_strfelt(
    #         module), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    # )

    # logged_deploy(
    #     nre,
    #     "xoroshiro128_starstar",
    #     alias="xoroshiro128_starstar",
    #     arguments=[
    #         '0x10AF',
    #     ],
    # )

    # module, _ = safe_load_deployment("arbiter", nre.network)

    # logged_deploy(
    #     nre,
    #     "ModuleController",
    #     alias="moduleController",
    #     arguments=[
    #         strhex_as_strfelt(module),
    #         strhex_as_strfelt(config.LORDS_PROXY_ADDRESS),
    #         strhex_as_strfelt(config.RESOURCES_PROXY_ADDRESS),
    #         strhex_as_strfelt(config.REALMS_PROXY_ADDRESS),
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),
    #         strhex_as_strfelt(config.S_REALMS_PROXY_ADDRESS)
    #     ],
    # )

    # module, _ = safe_load_deployment("moduleController", nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="arbiter",
    #     function="set_address_of_controller",
    #     arguments=[
    #         strhex_as_strfelt(module),
    #     ]
    # )

    # #---------------- IMPLEMENTATIONS  ----------------#
    # for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
    #     logged_deploy(
    #         nre,
    #         contract.contract_name,
    #         alias=contract.alias,
    #         arguments=[],
    #     )
    #     declare(contract.contract_name, contract.alias)

    # #---------------- PROXY  ----------------#
    # for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
    #     predeclared_class = nre.get_declaration(contract.alias)

    #     logged_deploy(
    #         nre,
    #         'PROXY_Logic',
    #         alias='proxy_' + contract.alias,
    #         arguments=[strhex_as_strfelt(predeclared_class)],
    #     )

    # # wait 120s - this will reduce on mainnet
    # print('🕒 Waiting for deploy before invoking')
    # time.sleep(120)

    # #---------------- INIT MODULES  ----------------#
    # for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
    #     wrapped_send(
    #         network=config.nile_network,
    #         signer_alias=config.ADMIN_ALIAS,
    #         contract_alias="proxy_" + contract.contract_name,
    #         function="initializer",
    #         arguments=[strhex_as_strfelt(
    #             config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    #     )
