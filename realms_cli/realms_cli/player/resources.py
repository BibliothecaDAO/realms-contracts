# First, import click dependency
import json
import click

from nile.core.account import Account
from ecdsa import SigningKey, SECP256k1

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, parse_multi_input


@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_resources(address, network):
    """
    Check address resources
    If no account is specified, it uses the env account.
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    n_resources = len(config.RESOURCES)

    uints = []
    for i in range(n_resources - 2):
        uints.append(str(i+1))
        uints.append("0")

    # WHEAT
    uints.append("10000")
    uints.append("0")

    # FISH
    uints.append("10001")
    uints.append("0")

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_resources",
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
        pretty_out.append(
            f"{resource} : {int(out[i*2+1], 16) / 1000000000000000000}")

    print_over_colums(pretty_out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def claim_resources(realm_token_id, network):
    """
    Claim available resources & lords
    """
    config = Config(nile_network=network)

    realm_token_ids = parse_multi_input(realm_token_id)
    calldata = [
        [id, 0]
        for id in realm_token_ids
    ]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_L02_Resources",
        function="claim_resources",
        arguments=calldata
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def days_available(realm_token_id, network):
    """
    Claim available resources & lords
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L02_Resources",
        function="days_accrued",
        arguments=[
            realm_token_id,   # uint 1
            0,                # uint 2
        ],
    )
    print(out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.argument("resource_id", nargs=1)
@click.option("--network", default="goerli")
def upgrade_resource(realm_token_id, resource_id, network):
    """
    Upgrade resource
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_L02_Resources",
        function="upgrade_resource",
        arguments=[
            realm_token_id,   # uint 1
            0,                # uint 2
            resource_id
        ],
    )


@click.command()
@click.option("--network", default="goerli")
def approve_resource_module(network):
    """
    Approve module to use resources
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_resources",
        function="setApprovalForAll",
        arguments=[
            int(config.L02_RESOURCES_PROXY_ADDRESS, 16),  # uint1
            "1",               # true
        ],
    )


@click.command()
@click.argument("resource_id", nargs=1)
@click.option("--network", default="goerli")
def get_resource_upgrade_cost(resource_id, network):
    """
    Check resource costs
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L02_Resources",
        function="get_resource_upgrade_cost",
        arguments=[resource_id],
    )
    print(out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_vault(realm_token_id, network):
    """
    Check resource costs
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L02_Resources",
        function="get_all_vault_raidable",
        arguments=[
            realm_token_id,
            0,
        ],
    )
    print(out)
