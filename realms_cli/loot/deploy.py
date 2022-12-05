from collections import namedtuple
from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send, wrapped_declare
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.utils import str_to_felt
import time
from enum import IntEnum

class ExternalContractIds(IntEnum):
    Realms_ERC721_Mintable = 1
    Lords_ERC20_Mintable = 2
    Treasury = 3

class ModuleId(IntEnum):
    Adventurer = 1
    Loot = 2
    Beast = 3

Contracts = namedtuple('Contracts', 'contract_name alias')
ModuleContracts = namedtuple('Contracts', 'contract_name alias id')

CONTROLLER_CONTRACT_IMPLEMENTATIONS = [
    Contracts("settling_game/Arbiter", "Arbiter"),
    Contracts("loot/ModuleController", "ModuleController")
]

module_path = 'loot/'
token_path = 'settling_game/tokens/'

# token tuples
MODULE_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts(module_path + "adventurer/Adventurer", "Adventurer", ModuleId.Adventurer),
    ModuleContracts(module_path + "loot/Loot", "Loot", ModuleId.Loot),
    ModuleContracts(module_path + "beast/Beast", "Beast", ModuleId.Beast),
]

TOKEN_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts(token_path +
                    "Realms_ERC721_Mintable", "Realms_ERC721_Mintable", ExternalContractIds.Realms_ERC721_Mintable),
    ModuleContracts(token_path +
                    "Lords_ERC20_Mintable", "Lords_ERC20_Mintable", ExternalContractIds.Lords_ERC20_Mintable),
]

# Lords
LORDS = str_to_felt("Lords")
LORDS_SYMBOL = str_to_felt("LORDS")
DECIMALS = 18

# Realms
REALMS = str_to_felt("Realms")
REALMS_SYMBOL = str_to_felt("REALMS")

# Adventurer
ADVENTURER = str_to_felt("Adventurer")
ADVENTURER_SYMBOL = str_to_felt("ADVENTURER")

# Loot
LOOT = str_to_felt("Loot")
LOOT_SYMBOL = str_to_felt("LOOT")

def run(nre):

    config = Config(nre.network)

    # #---------------- CONTROLLERS  ----------------#
    # for contract in CONTROLLER_CONTRACT_IMPLEMENTATIONS:

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

    # # wait 120s - this will reduce on mainnet
    # print('🕒 Waiting for deploy before invoking')
    # time.sleep(500)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="initializer",
    #     arguments=[config.ADMIN_ADDRESS],
    # )

    # module, _ = safe_load_deployment("proxy_Arbiter", nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_ModuleController",
    #     function="initializer",
    #     arguments=[module, config.ADMIN_ADDRESS],
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

    # xoroshiro, _ = safe_load_deployment("xoroshiro128_starstar", nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Arbiter",
    #     function="set_xoroshiro",
    #     arguments=[xoroshiro],
    # )

    #---------------- MODULE IMPLEMENTATIONS  ----------------#
    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
        class_hash = wrapped_declare(
            config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[class_hash],
        )

    # #---------------- TOKEN IMPLEMENTATIONS  ----------------#
    for contract in TOKEN_CONTRACT_IMPLEMENTATIONS:
        class_hash = wrapped_declare(
            config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[class_hash],
        )

    # # wait 120s - this will reduce on mainnet
    print('🕒 Waiting for deploy before invoking')
    time.sleep(500)

    #---------------- INIT MODULES  ----------------#
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Loot",
        function="initializer",
        arguments=[
            LOOT,
            LOOT_SYMBOL,
            config.CONTROLLER_PROXY_ADDRESS,
            config.ADMIN_ADDRESS,
        ],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Adventurer",
        function="initializer",
        arguments=[
            ADVENTURER,
            ADVENTURER_SYMBOL,
            config.CONTROLLER_PROXY_ADDRESS,
            config.ADMIN_ADDRESS,
        ],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Beast",
        function="initializer",
        arguments=[
            config.CONTROLLER_PROXY_ADDRESS,
            config.ADMIN_ADDRESS,
        ],
    )

    #---------------- INIT TOKENS  ----------------#

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Lords_ERC20_Mintable",
        function="initializer",
        arguments=[
            LORDS,
            LORDS_SYMBOL,
            DECIMALS,
            config.INITIAL_LORDS_SUPPLY,
            0,
            config.ADMIN_ADDRESS,
            config.ADMIN_ADDRESS
        ],
    )

    wrapped_send(
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

    #---------------- SET MODULES ----------------#

    module_contract_setup = []
    for module in MODULE_CONTRACT_IMPLEMENTATIONS:
        deployment, _ = safe_load_deployment(
            "proxy_" + module.alias, nre.network)

        module_contract_setup.append([deployment, module.id.value])

    # multicall
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Arbiter",
        function="appoint_contract_as_module",
        arguments=module_contract_setup,
    )

    #---------------- WRITE LIST ----------------#

    write_list = [
        [ModuleId.Loot.value, ModuleId.Adventurer.value],
        [ModuleId.Adventurer.value, ModuleId.Loot.value],
        [ModuleId.Adventurer.value, ModuleId.Beast.value],
        [ModuleId.Beast.value, ModuleId.Adventurer.value],
        [ModuleId.Beast.value, ModuleId.Loot.value],
    ]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Arbiter",
        function="approve_module_to_module_write_access",
        arguments=write_list
    )

    #---------------- SET EXTERNAL CONTRACT ADDRESSES ----------------#

    lords_deployment, _ = safe_load_deployment(
        "proxy_Lords_ERC20_Mintable", nre.network)

    realms_deployment, _ = safe_load_deployment(
        "proxy_Realms_ERC721_Mintable", nre.network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Arbiter",
        function="set_external_contract_address",
        arguments=[
            [realms_deployment, ExternalContractIds.Realms_ERC721_Mintable.value],
            [lords_deployment, ExternalContractIds.Lords_ERC20_Mintable.value],
            [config.ADMIN_ADDRESS ,ExternalContractIds.Treasury.value]
        ]
    )