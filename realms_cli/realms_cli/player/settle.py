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
def mint_realm(realm_token_id, network):
    """
    Mint Realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_realms",
        function="mint",
        arguments=[
            int(config.USER_ADDRESS, 16),  # felt
            realm_token_id,                 # uint 1
            0,                              # uint 2
        ],
    )

@click.command()
@click.option("--network", default="goerli")
def approve_realm(network):
    """
    Approve Realm transfer
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_realms",
        function="setApprovalForAll",
        arguments=[
            int(config.L01_SETTLING_PROXY_ADDRESS, 16),  # uint1
            "1",               # true
        ],
    )

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def settle_realm(realm_token_id, network):
    """
    Settle Realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_L01_Settling",
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
    Set Realm data
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
        contract_alias="proxy_realms",
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
def check_realms(address, network):
    """
    Check Realms balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_realms",
        function="balanceOf",
        arguments=[address],
    )
    print(out)   

@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_s_realms(address, network):
    """
    Check settled Realms balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_s_realms",
        function="balanceOf",
        arguments=[address],
    )
    print(out)   

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def check_owner_of_realm(realm_token_id, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_realms",
        function="ownerOf",
        arguments=[realm_token_id, 0],
    )
    print(out)   

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def check_owner_of_s_realm(realm_token_id, network):
    """
    Check owner of Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_s_realms",
        function="ownerOf",
        arguments=[realm_token_id, 0],
    )
    print(out)   

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_realm_data(realm_token_id, network):
    """
    Check settled Realms balance
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_realms",
        function="get_realm_info",
        arguments=[realm_token_id, 0],
    )
    print(out)   