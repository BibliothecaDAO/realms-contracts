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
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_lords(address, network):
    """
    Check $LORDS balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_lords",
        function="balanceOf",
        arguments=[address],
    )

    print(out)


@click.command()
@click.option("--address", default="2391140167327979619938051357136306508268704638528932947906243138584057924271", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def transfer_lords(address, network):
    """
    Transfer Lords  2391140167327979619938051357136306508268704638528932947906243138584057924271
    """
    config = Config(nile_network=network)
    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="proxy_lords",
        function="transfer",
        arguments=[
            address,
            100000 * 10 ** 18,   # uint 1
            0,                # uint 2
        ],
    )
