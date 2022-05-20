from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time
from realms_cli.shared import uint


def run(nre):

    config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "Exchange_ERC20_1155",
    #     alias="Exchange_ERC20_1155",
    #     arguments=[],
    # )

    # module, _ = safe_load_deployment('Exchange_ERC20_1155', 'goerli')

    # logged_deploy(
    #     nre,
    #     "PROXY_Logic",
    #     alias="proxy_Exchange_ERC20_1155",
    #     arguments=[
    #         strhex_as_strfelt(module),
    #     ]
    # )

    # print('🕒 Waiting for deploy before invoking... 3 minutes for testnet')
    # time.sleep(180)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="initializer",
        arguments=[
            strhex_as_strfelt(config.LORDS_PROXY_ADDRESS),
            strhex_as_strfelt(config.RESOURCES_PROXY_ADDRESS),
            *uint(100),
            *uint(100),
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(config.ADMIN_ADDRESS)
        ],
    )

    # wrapped_send(
    #     network=config.nile_network,
    #     signer_alias=config.ADMIN_ALIAS,
    #     contract_alias="proxy_Exchange_ERC20_1155",
    #     function="upgrade",
    #     arguments=[strhex_as_strfelt(config.Exchange_ERC20_1155_ADDRESS)],
    # )