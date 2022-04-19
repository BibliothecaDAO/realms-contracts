# First, import click dependency
import click
from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="127.0.0.1")
def mint_realm(realm_token_id, network):
    """
    Mint realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="realms",
        function="mint",
        arguments=[
            int(config.ADMIN_ADDRESS, 16),
            realm_token_id,
            0,
        ],
    )

@click.command()
@click.argument("realm_toked_id", nargs=1)
@click.option("--network", default="127.0.0.1")
def settle_realm(realm_toked_id, network):
    """
    Settle realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="L01_Settling",
        function="settle",
        arguments=[
            realm_toked_id,
            0,
        ],
    )
