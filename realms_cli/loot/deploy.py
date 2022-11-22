from collections import namedtuple
from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send, wrapped_declare
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.utils import str_to_felt
import time
from enum import IntEnum

class ExternalContractIds(IntEnum):
    Lords_ERC20_Mintable = 1
    Realms_ERC721_Mintable = 2

class ModuleId(IntEnum):
    Loot = 1
    Adventurer = 2
    Beast = 3

Contracts = namedtuple('Contracts', 'alias contract_name')
ModuleContracts = namedtuple('Contracts', 'alias contract_name id')

CONTROLLER_CONTRACT_IMPLEMENTATIONS = [
    Contracts("Arbiter", "Arbiter"),
    Contracts("ModuleController", "ModuleController")
]

# token tuples
MODULE_CONTRACT_IMPLEMENTATIONS = [
    ModuleContracts("Loot", "Loot", ModuleId.Loot),
    ModuleContracts("Adventurer", "Adventurer", ModuleId.Adventurer),
    ModuleContracts("Beast", "Beast", ModuleId.Beast),
]

# Lords
LORDS = str_to_felt("Lords")
LORDS_SYMBOL = str_to_felt("LORDS")
DECIMALS = 18

# Realms
REALMS = str_to_felt("Realms")
REALMS_SYMBOL = str_to_felt("REALMS")

# Adventurer
ADVENTURER = str_to_felt("ADVENTURER")
ADVENTURER_SYMBOL = str_to_felt("ADVENTURER")

# Loot
LOOT = str_to_felt("Loot")
LOOT_SYMBOL = str_to_felt("LOOT")

def run(nre):

    config = Config(nre.network)

    #---------------- CONTROLLERS  ----------------#
    for contract in CONTROLLER_CONTRACT_IMPLEMENTATIONS:

        class_hash = wrapped_declare(
            config.ADMIN_ALIAS, contract.contract_name, nre.network, contract.alias)

        logged_deploy(
            nre,
            'PROXY_Logic',
            alias='proxy_' + contract.alias,
            arguments=[class_hash],
        )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Arbiter",
        function="initializer",
        arguments=[strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )

    # wait 120s - this will reduce on mainnet
    print('🕒 Waiting for deploy before invoking')

    module, _ = safe_load_deployment("proxy_Arbiter", nre.network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_ModuleController",
        function="initializer",
        arguments=[strhex_as_strfelt(
            module), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )

    logged_deploy(
        nre,
        "xoroshiro128_starstar",
        alias="xoroshiro128_starstar",
        arguments=[
            '0x10AF',
        ],
    )

    module, _ = safe_load_deployment("xoroshiro128_starstar", nre.network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_ModuleController",
        function="set_xoroshiro",
        arguments=[strhex_as_strfelt(module)],
    )

    #---------------- MODULE IMPLEMENTATIONS  ----------------#
    for contract in MODULE_CONTRACT_IMPLEMENTATIONS:
        logged_deploy(
            nre,
            contract.contract_name,
            alias=contract.alias,
            arguments=[],
        )
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
    time.sleep(120)

    #---------------- INIT MODULES  ----------------#
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Loot",
        function="initializer",
        arguments=[
            LOOT,
            LOOT_SYMBOL,
            strhex_as_strfelt(config.CONTROLLER_ADDRESS), 
            config.ADMIN_ADDRESS
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
            strhex_as_strfelt(config.CONTROLLER_ADDRESS), 
            config.ADMIN_ADDRESS
        ],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Beast",
        function="initializer",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS), 
            config.ADMIN_ADDRESS
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
            str(config.INITIAL_LORDS_SUPPLY),
            "0",
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
            [lords_deployment, ExternalContractIds.Lords_ERC20_Mintable.value], 
            [realms_deployment, ExternalContractIds.Realms_ERC721_Mintable.value]
        ]
    )