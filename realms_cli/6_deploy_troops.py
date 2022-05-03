from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt

def run(nre):

    config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "xoroshiro128_starstar",
    #     alias="xoroshiro128_starstar",
    #     arguments=[
    #         '0x10AF',
    #     ],
    # )

    # logged_deploy(
    #     nre,
    #     "L06_Combat",
    #     alias="L06_Combat",
    #     arguments=[
    #         strhex_as_strfelt(config.CONTROLLER_ADDRESS),
    #         strhex_as_strfelt(config.XOROSHIRO_ADDRESS)
    #     ],
    # )
    
    # logged_deploy(
    #     nre,
    #     "S06_Combat",
    #     alias="S06_Combat",
    #     arguments=[
    #         strhex_as_strfelt(config.CONTROLLER_ADDRESS),
    #     ],
    # )

    # set module access within realms access
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="arbiter",
        function="appoint_contract_as_module",
        arguments=[
            strhex_as_strfelt(config.L06_COMBAT_ADDRESS),
            11
        ]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="arbiter",
        function="appoint_contract_as_module",
        arguments=[
            strhex_as_strfelt(config.S06_COMBAT_ADDRESS),
            12
        ]
    )    