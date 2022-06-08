# First, import click dependency
import click

from ecdsa import SigningKey, SECP128r1

from realms_cli.caller_invoker import wrapped_send
from realms_cli.config import Config
from realms_cli.utils import parse_multi_input

@click.command()
def create_pk():
    """
    Create private key
    """
    sk = SigningKey.generate(curve=SECP128r1)
    sk_string = sk.to_string()
    sk_hex = sk_string.hex()
    print(int('0x' + sk_hex, 16))

@click.command()
@click.argument("to", nargs=1)
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def transfer_realm(to, realm_token_id, network):
    """
    Transfer realm

    to: 0x address
    """
    config = Config(nile_network=network)

    realm_token_ids = parse_multi_input(realm_token_id)
    calldata = [
        [int(config.USER_ADDRESS, 16), int(to, 16), id, 0]
        for id in realm_token_ids
    ]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_realms",
        function="transferFrom",
        arguments=calldata
    )

@click.command()
@click.argument("to", nargs=1)
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def transfer_s_realm(to, realm_token_id, network):
    """
    Transfer settled realm

    to: 0x address
    """
    config = Config(nile_network=network)

    realm_token_ids = parse_multi_input(realm_token_id)
    calldata = [
        [int(config.USER_ADDRESS, 16), int(to, 16), id, 0]
        for id in realm_token_ids
    ]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_s_realms",
        function="transferFrom",
        arguments=calldata
    )