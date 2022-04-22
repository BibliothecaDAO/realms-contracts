# First, import click dependency
import json
import click
from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums

from realms_cli.binary_converter import map_realm

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="127.0.0.1")
def mint_realm(realm_token_id, network):
    """
    Mint realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
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
@click.option("--network", default="127.0.0.1")
def settle_realm(realm_token_id, network):
    """
    Settle realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="L01_Settling",
        function="settle",
        arguments=[
            realm_token_id,  # uint1
            0,               # uint2
        ],
    )

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="127.0.0.1")
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
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="realms",
        function="set_realm_data",
        arguments=[
            realm_token_id,   # uint 1
            0,                # uint 2
            realm_data_felt,  # felt
        ],
    )



@click.command()
@click.argument("account", nargs=1)
@click.option("--network", default="127.0.0.1")
def check_resources(account, network):
    """
    Check claimable resources
    """
    config = Config(nile_network=network)

    # if isinstance(account, str):
    #     if "0x" in account:
    #         account = int(account, 16)
    #     else:
    #         account = int(account)

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
            *[account for _ in range(n_resources)],
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
@click.option("--network", default="127.0.0.1")
def claim_resources(realm_token_id, network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias="L02_Resources",
        function="claim_resources",
        arguments=[
            realm_token_id,   # uint 1
            0,                # uint 2
        ],
    )
