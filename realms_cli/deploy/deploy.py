from collections import namedtuple
from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send, wrapped_declare
from realms_cli.config import Config, safe_load_deployment
from realms_cli.utils import str_to_felt
from enum import IntEnum
from nile.common import get_class_hash

# Lords
LORDS = str_to_felt("Lords")
LORDS_SYMBOL = str_to_felt("LORDS")
DECIMALS = 18

# Resources
REALMS_RESOURCES = str_to_felt("RealmsResources")

# Realms
REALMS = str_to_felt("Realms")
REALMS_SYMBOL = str_to_felt("REALMS")

# S_Realms
S_REALMS = str_to_felt("S_Realms")
S_REALMS_SYMBOL = str_to_felt("S_REALMS")


class ExternalContractIds(IntEnum):
    Lords_ERC20_Mintable = 1
    Realms_ERC721_Mintable = 2
    S_Realms_ERC721_Mintable = 3
    Resources_ERC1155_Mintable_Burnable = 4


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
    Labor = 16
    Crypts_Token = 1001
    Lords_Token = 1002
    Realms_Token = 1003
    Resources_Token = 1004
    S_Crypts_Token = 1005
    S_Realms_Token = 1006


Contracts = namedtuple('Contracts', 'name')
ModuleContracts = namedtuple('Contracts', 'name id')

CONTROLLER_CONTRACT_IMPLEMENTATIONS = [
    Contracts("Arbiter"), Contracts("ModuleController")
]

# token tuples
MODULE_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts("Settling", ModuleId.Settling),
    ModuleContracts("Resources", ModuleId.Resources),
    ModuleContracts("Buildings", ModuleId.Buildings),
    ModuleContracts("Calculator", ModuleId.Calculator),
    ModuleContracts("Combat", ModuleId.Combat),
    ModuleContracts("Travel", ModuleId.Travel),
    ModuleContracts("Food", ModuleId.Food),
    ModuleContracts("Relics", ModuleId.Relics),
    ModuleContracts("Labor", ModuleId.Labor)
]

TOKEN_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts("Lords_ERC20_Mintable", ModuleId.Lords_Token),
    ModuleContracts("Realms_ERC721_Mintable", ModuleId.Realms_Token),
    ModuleContracts("S_Realms_ERC721_Mintable", ModuleId.S_Realms_Token),
    ModuleContracts("Resources_ERC1155_Mintable_Burnable",
                    ModuleId.Resources_Token)
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

    #---------------- CONTROLLERS  ----------------#
    # for contract in CONTROLLER_CONTRACT_IMPLEMENTATIONS:
    #     await deploy_proxy(contract.name, nre)

    # await wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="initializer",
    #     arguments=[config.ADMIN_ADDRESS],
    # )

    module_controller, _ = safe_load_deployment("proxy_ModuleController", nre.network)
    # await wrapped_send(network=config.nile_network,
    #                    signer_alias=config.ADMIN_ALIAS,
    #                    contract_alias="proxy_Arbiter",
    #                    function="set_address_of_controller",
    #                    arguments=[
    #                        module_controller,
    #                    ])

    # arbiter, _ = safe_load_deployment("proxy_Arbiter", nre.network)
    # await wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_ModuleController",
    #     function="initializer",
    #     arguments=[arbiter, config.ADMIN_ADDRESS],
    # )

    # #---------------- MODULE IMPLEMENTATIONS  ----------------#
    # for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
    #     await deploy_proxy(contract.name, nre)

    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.ADMIN_ALIAS,
            contract_alias="proxy_" + contract.name,
            function="initializer",
            arguments=[module_controller, config.ADMIN_ADDRESS],
        )

    # # #---------------- TOKEN IMPLEMENTATIONS  ----------------#
    for contract in TOKEN_CONTRACT_IMPLEMENTATIONS:
        await deploy_proxy(contract.name, nre)

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Lords_ERC20_Mintable",
        function="initializer",
        arguments=[
            LORDS, LORDS_SYMBOL, DECIMALS,
            str(config.INITIAL_LORDS_SUPPLY), "0", config.ADMIN_ADDRESS,
            config.ADMIN_ADDRESS
        ],
    )

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Realms_ERC721_Mintable",
        function="initializer",
        arguments=[
            REALMS,  # name
            REALMS_SYMBOL,  # ticker
            config.ADMIN_ADDRESS,  # contract_owner
        ],
    )

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_S_Realms_ERC721_Mintable",
        function="initializer",
        arguments=[
            S_REALMS,  # name
            S_REALMS_SYMBOL,  # ticker
            config.ADMIN_ADDRESS,  # contract_owner
            module_controller
        ],
    )

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Resources_ERC1155_Mintable_Burnable",
        function="initializer",
        arguments=[
            REALMS_RESOURCES,
            config.ADMIN_ADDRESS,  # contract_owner
            module_controller
        ],
    )

    # # #---------------- SET MODULES ----------------#

    module_contract_setup = []
    for module in MODULE_CONTRACT_IMPLEMENTATIONS:
        deployment, _ = safe_load_deployment("proxy_" + module.name,
                                             nre.network)

        module_contract_setup.append([deployment, module.id.value])

    for module in TOKEN_CONTRACT_IMPLEMENTATIONS:
        deployment, _ = safe_load_deployment("proxy_" + module.name,
                                             nre.network)

        module_contract_setup.append([deployment, module.id.value])

    # multicall
    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Arbiter",
        function="appoint_contract_as_module",
        arguments=module_contract_setup,
    )

    # # #---------------- WRITE LIST ----------------#

    write_list = [[ModuleId.Settling.value, ModuleId.Resources.value],
                  [ModuleId.Resources.value, ModuleId.Settling.value],
                  [ModuleId.Combat.value, ModuleId.Resources.value],
                  [ModuleId.Combat.value, ModuleId.Settling.value],
                  [ModuleId.Combat.value, ModuleId.Resources_Token.value],
                  [ModuleId.Settling.value, ModuleId.S_Realms_Token.value],
                  [ModuleId.Resources.value, ModuleId.Resources_Token.value],
                  [ModuleId.Buildings.value, ModuleId.Resources_Token.value]]

    await wrapped_send(network=config.nile_network,
                       signer_alias=config.ADMIN_ALIAS,
                       contract_alias="proxy_Arbiter",
                       function="approve_module_to_module_write_access",
                       arguments=write_list)

    # #---------------- SET EXTERNAL CONTRACT ADDRESSES ----------------#

    # redeploy lORDS TODO:
    lords_deployment, _ = safe_load_deployment("proxy_Lords_ERC20_Mintable",
                                               nre.network)

    realms_deployment, _ = safe_load_deployment("proxy_Realms_ERC721_Mintable",
                                                nre.network)

    s_realms_deployment, _ = safe_load_deployment(
        "proxy_S_Realms_ERC721_Mintable", nre.network)

    resources_deployment, _ = safe_load_deployment(
        "proxy_Resources_ERC1155_Mintable_Burnable", nre.network)

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Arbiter",
        function="set_external_contract_address",
        arguments=[
            [lords_deployment, ExternalContractIds.Lords_ERC20_Mintable.value],
            [
                realms_deployment,
                ExternalContractIds.Realms_ERC721_Mintable.value
            ],
            [
                s_realms_deployment,
                ExternalContractIds.S_Realms_ERC721_Mintable.value
            ],
            [
                resources_deployment,
                ExternalContractIds.Resources_ERC1155_Mintable_Burnable.value
            ]
        ])

    # --------- SETTLING_PROXY_ADDRESS Approvals ------- #

    deployment, _ = safe_load_deployment("proxy_Settling", nre.network)

    await wrapped_send(network=config.nile_network,
                 signer_alias=config.ADMIN_ALIAS,
                 contract_alias="proxy_Realms_ERC721_Mintable",
                 function="setApprovalForAll",
                 arguments=[
                     deployment,
                     "1",
                 ])
