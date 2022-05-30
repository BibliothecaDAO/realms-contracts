from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
import time
from realms_cli.shared import uint
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment


def run(nre):

    config = Config(nre.network)

    logged_deploy(
        nre,
        "Bridge",
        alias="Bridge",
        arguments=[],
    )
    module, _ = safe_load_deployment('Bridge', 'goerli')

    logged_deploy(
        nre,
        "PROXY_Logic",
        alias="proxy_Bridge",
        arguments=[
            strhex_as_strfelt(module),
        ]
    )

    print('🕒 Waiting for deploy before invoking... 3 minutes for testnet')
    time.sleep(180)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Bridge",
        function="initializer",
        arguments=[
            strhex_as_strfelt(config.ADMIN_ADDRESS),
            strhex_as_strfelt(config.REALMS_PROXY_ADDRESS)
        ],
    )
