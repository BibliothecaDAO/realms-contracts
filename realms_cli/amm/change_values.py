from nile.core.declare import declare

from realms_cli.caller_invoker import wrapped_call, wrapped_send, compile, deploy
from realms_cli.deployer import logged_deploy
from realms_cli.config import Config, strhex_as_strfelt, safe_load_deployment
import time
from realms_cli.utils import uint


async def run(nre):

    config = Config(nre.network)

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="set_royalty_info",
        arguments=[strhex_as_strfelt(module)],
    )
