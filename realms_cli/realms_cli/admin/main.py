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
@click.option("--network", default="goerli")
def mint_resources(network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="resources",
        function="mintBatch",
        arguments=[int(config.ADMIN_ADDRESS, 16), 10, *uint(1), *uint(2), *uint(3), *uint(4), *uint(5), *uint(6), *uint(7), *uint(8), *uint(9), *uint(10), 10, *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500), *uint(500)
        ],
    )
