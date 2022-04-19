from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config, strhex_as_strfelt

def run(nre):

    # config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "Storage",
    #     alias="storage",
    #     arguments=[
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),
    #     ],
    # )

    # logged_deploy(
    #     nre,
    #     "Arbiter",
    #     alias="arbiter",
    #     arguments=[
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),
    #     ],
    # )

    # # we just deployed storage and arbiter and need it for the following
    # # send commands, Config has not loaded it yet so we have to force load it
    # config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "ModuleController",
    #     alias="moduleController",
    #         arguments=[
    #             strhex_as_strfelt(config.ARBITER_ADDRESS),
    #             strhex_as_strfelt(config.LORDS_ADDRESS),
    #             strhex_as_strfelt(config.RESOURCES_ADDRESS),
    #             strhex_as_strfelt(config.REALMS_ADDRESS),
    #             strhex_as_strfelt(config.ADMIN_ADDRESS),
    #             strhex_as_strfelt(config.S_REALMS_ADDRESS),
    #             strhex_as_strfelt(config.STORAGE_ADDRESS),
    #         ],
    # )

    config = Config(nre.network)

    # Set address of controller
    # TODO: loaf, can this be moved to 4_init_game.py?
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="arbiter",
        function="set_address_of_controller",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    # Settling Proxy
    # proxy_settling_logic, abi = nre.deploy(
    #     "PROXY_L01_Settling",
    #     alias="PROXY_L01_Settling",
    #     arguments=[L01_Settling],
    # )

    # Settling Init
    # nre.invoke(
    #     proxy_settling_logic,
    #     'initializer',
    #     params=[admin, controller],
    # )


    logged_deploy(
        nre,
        "L01_Settling",
        alias="L01_Settling",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )


    logged_deploy(
        nre,
        "S01_Settling",
        alias="S01_Settling",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    logged_deploy(
        nre,
        "L02_Resources",
        alias="L02_Resources",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    logged_deploy(
        nre,
        "S02_Resources",
        alias="S02_Resources",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    logged_deploy(
        nre,
        "L03_Buildings",
        alias="L03_Buildings",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    logged_deploy(
        nre,
        "S03_Buildings",
        alias="S03_Buildings",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    logged_deploy(
        nre,
        "L04_Calculator",
        alias="L04_Calculator",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    logged_deploy(
        nre,
        "L05_Wonders",
        alias="L05_Wonders",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )

    logged_deploy(
        nre,
        "S05_Wonders",
        alias="S05_Wonders",
        arguments=[
            strhex_as_strfelt(config.CONTROLLER_ADDRESS),
        ]
    )
