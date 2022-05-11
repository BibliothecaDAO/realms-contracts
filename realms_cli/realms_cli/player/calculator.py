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
@click.option("--network", default="goerli")
def happiness(realm_token_id, network):
    """
    Build a building
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L04_Calculator",
        function="calculate_happiness",
        arguments=[
            realm_token_id,                 # uint 1
            0,
        ],
    )
    print(out)
