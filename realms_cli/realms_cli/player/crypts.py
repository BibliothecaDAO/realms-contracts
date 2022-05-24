# crypts.py
#   'Settle' a crypt and start earning resources
#
# MIT License

# First, import click dependency
import json
import click

from nile.core.account import Account
from ecdsa import SigningKey, SECP256k1

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums
from realms_cli.binary_converter import map_crypt
from realms_cli.shared import uint

@click.command()
@click.argument("crypt_token_id", nargs=1)
@click.option("--network", default="goerli")
def mint_crypt(crypt_token_id, network):
    """
    Mint Crypt
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="crypts",
        function="mint",
        arguments=[
            int(config.USER_ADDRESS, 16),  # felt
            crypt_token_id,                 # uint 1
            0,                              # uint 2
        ],
    )

@click.command()
@click.option("--network", default="goerli")
def approve_crypt(network):
    """
    Approve Crypt transfer
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="crypts",
        function="setApprovalForAll",
        arguments=[
            int(config.L07_CRYPTS_ADDRESS, 16),  # uint1
            "1",               # true
        ],
    )

@click.command()
@click.argument("crypt_token_id", nargs=1)
@click.option("--network", default="goerli")
def settle_crypt(crypt_token_id, network):
    """
    Settle Crypt
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="L07_Crypts",
        function="settle",
        arguments=[
            crypt_token_id,  # uint1
            0,               # uint2
        ],
    )

@click.command()
@click.argument("crypt_token_id", nargs=1)
@click.option("--network", default="goerli")
def set_crypt_data(crypt_token_id, network):
    """
    Set Crypt data
    """
    config = Config(nile_network=network)

    crypts = json.load(open("data/crypts.json", "r"))
    resources = json.load(open("data/resources.json", "r"))
    legendary = json.load(open("data/legendary.json", "r"))

    crypt_data_felt = map_crypt(crypts[str(crypt_token_id)], resources, legendary)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="crypts",
        function="set_crypt_data",
        arguments=[
            crypt_token_id,   # uint 1
            0,                # uint 2
            crypt_data_felt,  # felt
        ],
    )


@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_crypts(address, network):
    """
    Check Crypts balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="crypts",
        function="balanceOf",
        arguments=[address],
    )
    print(out)   

@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_s_crypts(address, network):
    """
    Check settled Crypts balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="s_crypts",
        function="balanceOf",
        arguments=[address],
    )
    print(out)   

@click.command()
@click.argument("crypt_token_id", nargs=1)
@click.option("--network", default="goerli")
def check_owner_of_crypt(crypt_token_id, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="crypts",
        function="ownerOf",
        arguments=[crypt_token_id, 0],
    )
    print(out)   

@click.command()
@click.argument("crypt_token_id", nargs=1)
@click.option("--network", default="goerli")
def check_owner_of_s_crypt(crypt_token_id, network):
    """
    Check owner of Crypt
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="s_crypts",
        function="ownerOf",
        arguments=[crypt_token_id, 0],
    )
    print(out)   

