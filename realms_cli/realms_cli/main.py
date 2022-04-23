# First, import click dependency
import json
import click

from nile.core.account import Account

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums

from realms_cli.binary_converter import map_realm


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def mint_realm(realm_token_id, network):
    """
    Mint realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="realms",
        function="mint",
        arguments=[
            int(config.ADMIN_ADDRESS, 16),  # felt
            realm_token_id,                 # uint 1
            0,                              # uint 2
        ],
    )

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def settle_realm(realm_token_id, network):
    """
    Settle realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="L01_Settling",
        function="settle",
        arguments=[
            realm_token_id,  # uint1
            0,               # uint2
        ],
    )

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def set_realm_data(realm_token_id, network):
    """
    Set realm data
    """
    config = Config(nile_network=network)

    realms = json.load(open("data/realms.json", "r"))
    resources = json.load(open("data/resources.json", "r"))
    orders = json.load(open("data/orders.json", "r"))
    wonders = json.load(open("data/wonders.json", ))

    realm_data_felt = map_realm(realms[str(realm_token_id)], resources, wonders, orders)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="realms",
        function="set_realm_data",
        arguments=[
            realm_token_id,   # uint 1
            0,                # uint 2
            realm_data_felt,  # felt
        ],
    )



@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_resources(address, network):
    """
    Check claimable resources.
    If no account is specified, it uses the env account.
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    n_resources = len(config.RESOURCES)

    uints = []
    for i in range(n_resources):
        uints.append(str(i+1))
        uints.append("0")

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="resources",
        function="balanceOfBatch",
        arguments=[
            n_resources,
            *[address for _ in range(n_resources)],
            n_resources,
            *uints,
        ],
    )

    out = out.split(" ")
    pretty_out = []
    for i, resource in enumerate(config.RESOURCES):
        pretty_out.append(f"{resource} : {out[i*2+1]}")

    print_over_colums(pretty_out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def claim_resources(realm_token_id, network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="L02_Resources",
        function="claim_resources",
        arguments=[
            realm_token_id,   # uint 1
            0,                # uint 2
        ],
    )

@click.command()
@click.option("--network", default="goerli")
def check_lords(network):
    """
    Check balance
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="lords",
        function="balanceOf",
        arguments=[],
    )

@click.command()
@click.option("--network", default="goerli")
def check_realms(network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="realms",
        function="balanceOf",
        arguments=[],
    )

# get happiness level
# get pillageable amount