from nile.core.declare import declare

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
from realms_cli.shared import str_to_felt
import time
from realms_cli.shared import uint

AMM_RESOURCES_URI = str_to_felt("AMMResources")


def run(nre):

    config = Config(nre.network)

    compile(contract_alias="contracts/exchange/Exchange_ERC20_1155.cairo")

    logged_deploy(
        nre,
        "Exchange_ERC20_1155",
        alias="Exchange_ERC20_1155",
        arguments=[],
    )
    module = declare("Exchange_ERC20_1155", nre.network, "Exchange_ERC20_1155")

    logged_deploy(
        nre,
        "PROXY_Logic",
        alias="proxy_Exchange_ERC20_1155",
        arguments=[
            strhex_as_strfelt(module),
        ]
    )

    print('🕒 Waiting for deploy before invoking... 1 minutes for testnet')
    time.sleep(60)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="initializer",
        arguments=[
            AMM_RESOURCES_URI,
            strhex_as_strfelt(config.LORDS_PROXY_ADDRESS),
            strhex_as_strfelt(config.RESOURCES_PROXY_ADDRESS),
            *uint(100),
            *uint(100),
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(config.ADMIN_ADDRESS)
        ],
    )

    module, _ = safe_load_deployment('proxy_Exchange_ERC20_1155', 'goerli')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_resources",
        function="setApprovalForAll",
        arguments=[strhex_as_strfelt(module), 1],
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="increaseAllowance",
        arguments=[strhex_as_strfelt(module), *uint(50000000 * (10 ** 18))],
    )
