# First, import click dependency
import json
import click

from nile.core.account import Account
from ecdsa import SigningKey, SECP256k1

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums
from realms_cli.binary_converter import map_realm
from realms_cli.shared import uint


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.argument("building_id", nargs=1)
@click.option("--network", default="goerli")
def build(realm_token_id, building_id, network):
    """
    Build a building
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_L03_Buildings",
        function="build",
        arguments=[
            realm_token_id,                 # uint 1
            0,                              # uint 2
            building_id
        ],
    )
