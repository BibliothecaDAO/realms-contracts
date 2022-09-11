from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time
from realms_cli.shared import uint


def run(nre):
    compile(contract_alias="contracts/l2/bridge/Bridge.cairo")

    logged_deploy(
        nre,
        'Bridge',
        alias='proxy_Bridge',
        arguments=[],
    )

    print('🕒 Waiting for deploy before invoking... 3 minutes for testnet')
    time.sleep(180)

    config = Config(nre.network)

    wrapped_send(
        network=nre.network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Bridge",
        function="initializer",
        arguments=[strhex_as_strfelt(config.ADMIN_ADDRESS)],
    )