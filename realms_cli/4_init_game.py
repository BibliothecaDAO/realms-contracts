from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config, strhex_as_strfelt

def run(nre):

    config = Config(nre.network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="arbiter",
        function="batch_set_controller_addresses",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_ADDRESS),
            strhex_as_strfelt(config.S01_SETTLING_ADDRESS),
            strhex_as_strfelt(config.L02_RESOURCES_ADDRESS),
            strhex_as_strfelt(config.S02_RESOURCES_ADDRESS),
            strhex_as_strfelt(config.L03_BUILDINGS_ADDRESS),
            strhex_as_strfelt(config.S03_BUILDINGS_ADDRESS),
            strhex_as_strfelt(config.L04_CALCULATOR_ADDRESS),
            strhex_as_strfelt(config.L05_WONDERS_ADDRESS),
            strhex_as_strfelt(config.S05_WONDERS_ADDRESS),
        ],
    )

    # set module access within realms access
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="s_realms",
        function="Set_module_access",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_ADDRESS),
        ]
    )

    # set module access within resources contract
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="resources",
        function="Set_module_access",
        arguments=[
            strhex_as_strfelt(config.L02_RESOURCES_ADDRESS),
        ]
    )

    # Give settling address approval for manipulating realms (settling)
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="realms",
        function="setApprovalForAll",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_ADDRESS),
            "1",
        ]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="lords",
        function="approve",
        arguments=[
            strhex_as_strfelt(config.L01_SETTLING_ADDRESS),
            str(config.INITIAL_LORDS_SUPPLY), 0
        ]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="lords",
        function="approve",
        arguments=[
            strhex_as_strfelt(config.L02_RESOURCES_ADDRESS),
            str(config.INITIAL_LORDS_SUPPLY), 0
        ]
    )
