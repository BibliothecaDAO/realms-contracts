from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config


bastion_1 = [100,100]
bastion_2 = [80,80]

async def run(nre):
    config = Config(nre.network)

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_Bastions",
        function="spawn_bastions",
        arguments=[1, 100, 100, 1, 1, 1],
    )
