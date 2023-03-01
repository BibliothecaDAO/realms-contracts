from collections import namedtuple
from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send, wrapped_declare
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time
from realms_cli.utils import str_to_felt
from enum import IntEnum

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
    # Treasury = 5
    # Storage = 6
    # Crypts = 7
    # S_Crypts = 8


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


Contracts = namedtuple('Contracts', 'contract_name alias')
ModuleContracts = namedtuple('Contracts', 'contract_name alias id')

CONTROLLER_CONTRACT_IMPLEMENTATIONS = [
    Contracts("settling_game/Arbiter", "Arbiter"),
    Contracts("settling_game/Arbiter", "ModuleController")
]

module_path = 'settling_game/modules/'
token_path = 'settling_game/tokens/'

# token tuples
MODULE_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts(module_path +
                    "/settling/Settling", "Settling", ModuleId.Settling),
    ModuleContracts(module_path +
                    "/resources/Resources", "Resources",  ModuleId.Resources),
    ModuleContracts(module_path +
                    "/buildings/Buildings", "Buildings",  ModuleId.Buildings),
    ModuleContracts(module_path +
                    "/calculator/Calculator", "Calculator",  ModuleId.Calculator),
    ModuleContracts(module_path +
                    "/combat/Combat", "Combat", ModuleId.Combat),
    ModuleContracts(module_path +
                    "/travel/Travel", "Travel", ModuleId.Travel),
    ModuleContracts(module_path +
                    "/food/Food", "Food", ModuleId.Food),
    ModuleContracts(module_path +
                    "/relics/Relics", "Relics", ModuleId.Relics)
]

TOKEN_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts(token_path +
                    "Lords_ERC20_Mintable", "Lords_ERC20_Mintable", ModuleId.Lords_Token),
    ModuleContracts(token_path +
                    "Realms_ERC721_Mintable", "Realms_ERC721_Mintable", ModuleId.Realms_Token),
    ModuleContracts(token_path + "S_Realms_ERC721_Mintable", "S_Realms_ERC721_Mintable",
                    ModuleId.S_Realms_Token),
    ModuleContracts(
        token_path + "Resources_ERC1155_Mintable_Burnable", "Resources_ERC1155_Mintable_Burnable", ModuleId.Resources_Token)
]


def run(nre):

    config = Config(nre.network)

    # #---------------- CONTROLLERS  ----------------#
    # for contract in CONTROLLER_CONTRACT_IMPLEMENTATIONS:

    #     logged_deploy(
    #         nre,
    #         contract.alias,
    #         alias=contract.alias,
    #         arguments=[],
    #     )

    #     class_hash = wrapped_declare(
    #         config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

    #     logged_deploy(
    #         nre,
    #         'PROXY_Logic',
    #         alias='proxy_' + contract.alias,
    #         arguments=[class_hash],
    #     )

    # logged_deploy(
    #     nre,
    #     "xoroshiro128_starstar",
    #     alias="xoroshiro128_starstar",
    #     arguments=[
    #         '0x10AF',
    #     ],
    # )

    # print('🕒 Waiting for deploy before invoking')
    # time.sleep(20)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="initializer",
    #     arguments=[config.ADMIN_ADDRESS],
    # )

    # xoroshiro, _ = safe_load_deployment("xoroshiro128_starstar", nre.network)
    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="set_xoroshiro",
    #     arguments=[
    #         xoroshiro,
    #     ]
    # )

    # module, _ = safe_load_deployment("proxy_ModuleController", nre.network)
    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="set_address_of_controller",
    #     arguments=[
    #         module,
    #     ]
    # )

    # module, _ = safe_load_deployment("proxy_Arbiter", nre.network)
    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_ModuleController",
    #     function="initializer",
    #     arguments=[
    #         module, config.ADMIN_ADDRESS],
    # )

    # #---------------- MODULE IMPLEMENTATIONS  ----------------#
    # for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
    #     logged_deploy(
    #         nre,
    #         contract.alias,
    #         alias=contract.alias,
    #         arguments=[],
    #     )

    #     time.sleep(20)

    #     class_hash = wrapped_declare(
    #         config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

    #     time.sleep(20)

    #     logged_deploy(
    #         nre,
    #         'PROXY_Logic',
    #         alias='proxy_' + contract.alias,
    #         arguments=[class_hash],
    #     )

    # # #---------------- TOKEN IMPLEMENTATIONS  ----------------#
    # for contract in TOKEN_CONTRACT_IMPLEMENTATIONS:
    #     logged_deploy(
    #         nre,
    #         contract.alias,
    #         alias=contract.alias,
    #         arguments=[],
    #     )

    #     time.sleep(20)

    #     class_hash = wrapped_declare(
    #         config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

    #     time.sleep(20)

    #     logged_deploy(
    #         nre,
    #         'PROXY_Logic',
    #         alias='proxy_' + contract.alias,
    #         arguments=[class_hash],
    #     )

    # #---------------- INIT MODULES  ----------------#

    # module, _ = safe_load_deployment("proxy_ModuleController", nre.network)

    # for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
    #     wrapped_send(
    #         network=config.nile_network,
    #         signer_alias=config.ADMIN_ALIAS,
    #         contract_alias="proxy_" + contract.alias,
    #         function="initializer",
    #         arguments=[
    #             module, config.ADMIN_ADDRESS],
    #     )

    # #---------------- INIT TOKENS  ----------------#

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Lords_ERC20_Mintable",
    #     function="initializer",
    #     arguments=[
    #         LORDS,
    #         LORDS_SYMBOL,
    #         DECIMALS,
    #         str(config.INITIAL_LORDS_SUPPLY),
    #         "0",
    #         config.ADMIN_ADDRESS,
    #         config.ADMIN_ADDRESS
    #     ],
    # )

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Realms_ERC721_Mintable",
    #     function="initializer",
    #     arguments=[
    #         REALMS,  # name
    #         REALMS_SYMBOL,  # ticker
    #         config.ADMIN_ADDRESS,  # contract_owner
    #     ],
    # )
    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_S_Realms_ERC721_Mintable",
    #     function="initializer",
    #     arguments=[
    #         S_REALMS,  # name
    #         S_REALMS_SYMBOL,  # ticker
    #         config.ADMIN_ADDRESS,  # contract_owner
    #         module
    #     ],
    # )

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Resources_ERC1155_Mintable_Burnable",
    #     function="initializer",
    #     arguments=[
    #         REALMS_RESOURCES,
    #         config.ADMIN_ADDRESS,  # contract_owner
    #         module
    #     ],
    # )

    # #---------------- SET MODULES ----------------#

    # module_contract_setup = []
    # for module in MODULE_CONTRACT_IMPLEMENTATIONS:
    #     deployment, _ = safe_load_deployment(
    #         "proxy_" + module.alias, nre.network)

    #     module_contract_setup.append([deployment, module.id.value])

    # for module in TOKEN_CONTRACT_IMPLEMENTATIONS:
    #     deployment, _ = safe_load_deployment(
    #         "proxy_" + module.alias, nre.network)

    #     module_contract_setup.append([deployment, module.id.value])

    # # multicall
    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="appoint_contract_as_module",
    #     arguments=module_contract_setup,
    # )

    # #---------------- WRITE LIST ----------------#

    # write_list = [
    #     [ModuleId.Settling.value, ModuleId.Resources.value],
    #     [ModuleId.Resources.value, ModuleId.Settling.value],
    #     [ModuleId.Combat.value, ModuleId.Resources.value],
    #     [ModuleId.Combat.value, ModuleId.Settling.value],
    #     [ModuleId.Combat.value, ModuleId.Resources_Token.value],
    #     [ModuleId.Settling.value, ModuleId.S_Realms_Token.value],
    #     [ModuleId.Resources.value, ModuleId.Resources_Token.value],
    #     [ModuleId.Buildings.value, ModuleId.Resources_Token.value]
    # ]

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="approve_module_to_module_write_access",
    #     arguments=write_list
    # )

    # #---------------- SET EXTERNAL CONTRACT ADDRESSES ----------------#

    # lords_deployment, _ = safe_load_deployment(
    #     "proxy_Lords_ERC20_Mintable", nre.network)

    # realms_deployment, _ = safe_load_deployment(
    #     "proxy_Realms_ERC721_Mintable", nre.network)

    # s_realms_deployment, _ = safe_load_deployment(
    #     "proxy_S_Realms_ERC721_Mintable", nre.network)

    # resources_deployment, _ = safe_load_deployment(
    #     "proxy_Resources_ERC1155_Mintable_Burnable", nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="set_external_contract_address",
    #     arguments=[[lords_deployment, ExternalContractIds.Lords_ERC20_Mintable.value], [realms_deployment, ExternalContractIds.Realms_ERC721_Mintable.value], [
    #         s_realms_deployment, ExternalContractIds.S_Realms_ERC721_Mintable.value], [resources_deployment, ExternalContractIds.Resources_ERC1155_Mintable_Burnable.value]]
    # )

    # --------- SETTLING_PROXY_ADDRESS Approvals ------- #

    deployment, _ = safe_load_deployment(
        "proxy_Settling", nre.network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Realms_ERC721_Mintable",
        function="setApprovalForAll",
        arguments=[
            deployment,
            "1",
        ]
    )
