# First, import click dependency
import click
from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config as config

# Decorate the method that will be the command name with `click.command` 
@click.command()
@click.argument("realm_token", nargs=1)
def mint_realm(realm_token):
    # Help message to show with the command
    """
    Mint realm
    """
    # Done! Now implement your custom functionality in the command
    wrapped_send(
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="realms",
        function="mint",
        args=[
            int(config.ADMIN_ADDRESS, 16),
            realm_token,
            0,
        ],
    )

# Decorate the method that will be the command name with `click.command` 
@click.command()
@click.argument("realm_toked_id", nargs=1)
def settle_realm(realm_toked_id):
    # Help message to show with the command
    """
    Mint realm
    """
    # Done! Now implement your custom functionality in the command
    wrapped_send(
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="L01_Settling",
        function="settle",
        args=[
            int(config.ADMIN_ADDRESS, 16),
            realm_toked_id,
            0,
        ],
    )
