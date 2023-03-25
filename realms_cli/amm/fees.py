from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config
from realms_cli.utils import uint


async def run(nre):

    config = Config(nre.network)

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Exchange_ERC20_1155",
        function="set_lp_info",
        arguments=[*uint(5)],
    )
