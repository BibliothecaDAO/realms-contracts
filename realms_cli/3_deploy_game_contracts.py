from realms_cli.deployer import logged_deploy
from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config, strhex_as_strfelt
import time

def run(nre):

    config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "Arbiter",
    #     alias="arbiter",
    #     arguments=[
    #         strhex_as_strfelt(config.ADMIN_ADDRESS),
    #     ],
    # )

    # logged_deploy(
    #     nre,
    #     "xoroshiro128_starstar",
    #     alias="xoroshiro128_starstar",
    #     arguments=[
    #         '0x10AF',
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
    #             strhex_as_strfelt(config.LORDS_PROXY_ADDRESS),
    #             strhex_as_strfelt(config.RESOURCES_PROXY_ADDRESS),
    #             strhex_as_strfelt(config.REALMS_PROXY_ADDRESS),
    #             strhex_as_strfelt(config.ADMIN_ADDRESS),
    #             strhex_as_strfelt(config.S_REALMS_PROXY_ADDRESS)
    #         ],
    # )

    # config = Config(nre.network)

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="arbiter",
    #     function="set_address_of_controller",
    #     arguments=[
    #         strhex_as_strfelt(config.CONTROLLER_ADDRESS),
    #     ]
    # )

    # logged_deploy(
    #     nre,
    #     "L01_Settling",
    #     alias="L01_Settling",
    #     arguments=[]
    # )

    # logged_deploy(
    #     nre,
    #     "L02_Resources",
    #     alias="L02_Resources",
    #     arguments=[]
    # )

    # logged_deploy(
    #     nre,
    #     "L03_Buildings",
    #     alias="L03_Buildings",
    #     arguments=[]
    # )

    # logged_deploy(
    #     nre,
    #     "L04_Calculator",
    #     alias="L04_Calculator",
    #     arguments=[]
    # )

    # logged_deploy(
    #     nre,
    #     "L05_Wonders",
    #     alias="L05_Wonders",
    #     arguments=[]
    # )

    # logged_deploy(
    #     nre,
    #     "L06_Combat",
    #     alias="L06_Combat",
    #     arguments=[]
    # )

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_L01_Settling",
    #     arguments=[strhex_as_strfelt(config.L01_SETTLING_ADDRESS)]
    # )

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_L02_Resources",
    #     arguments=[strhex_as_strfelt(config.L02_RESOURCES_ADDRESS)]
    # )

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_L03_Buildings",
    #     arguments=[strhex_as_strfelt(config.L03_BUILDINGS_ADDRESS)]
    # )

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_L04_Calculator",
    #     arguments=[strhex_as_strfelt(config.L04_CALCULATOR_ADDRESS)]
    # )

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_L05_Wonders",
    #     arguments=[strhex_as_strfelt(config.L05_WONDERS_ADDRESS)]
    # )

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_L06_Combat",
    #     arguments=[strhex_as_strfelt(config.L06_COMBAT_ADDRESS)]
    # )

    print('🕒 Waiting for deploy before invoking')
    time.sleep(240)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L01_Settling",
        function="initializer",
        arguments=[strhex_as_strfelt(config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L02_Resources",
        function="initializer",
        arguments=[strhex_as_strfelt(config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L03_Buildings",
        function="initializer",
        arguments=[strhex_as_strfelt(config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L04_Calculator",
        function="initializer",
        arguments=[strhex_as_strfelt(config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )   

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L05_Wonders",
        function="initializer",
        arguments=[strhex_as_strfelt(config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L06_Combat",
        function="initializer",
        arguments=[strhex_as_strfelt(config.CONTROLLER_ADDRESS), strhex_as_strfelt(config.XOROSHIRO_ADDRESS), strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )        