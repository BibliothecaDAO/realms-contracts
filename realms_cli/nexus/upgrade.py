from nile.core.declare import declare

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time
from realms_cli.shared import uint


def run(nre):

    config = Config(nre.network)

    compile(contract_alias="contracts/staking/Splitter.cairo")

    logged_deploy(
        nre,
        "Splitter",
        alias="Splitter",
        arguments=[],
    )
    module = declare("Splitter", nre.network, "Splitter")

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Splitter",
        function="upgrade",
        arguments=[strhex_as_strfelt(module)],
    )
