from realms_cli.caller_invoker import wrapped_send
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt
import time

def run(nre):

    config = Config(nre.network)

    # logged_deploy(
    #     nre,
    #     "L06_Combat",
    #     alias="L06_Combat",
    #     arguments=[],
    # )

    # print('🕒 Waiting for deploy before invoking')
    # time.sleep(240)

    # set module access within realms access
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_L06_Combat",
        function="upgrade",
        arguments=[strhex_as_strfelt(config.L06_COMBAT_ADDRESS)]
    )