# First, import click dependency
import json
import click

from nile.core.account import Account
from ecdsa import SigningKey, SECP256k1

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums
from realms_cli.binary_converter import map_realm

def uint(a):
    return(a, 0)

@click.command()
def create_pk():
    """
    Create private key
    """
    sk = SigningKey.generate(curve=SECP256k1)
    sk_string = sk.to_string()
    sk_hex = sk_string.hex()
    print(int('0x' + sk_hex, 16))

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
            int(config.USER_ADDRESS, 16),  # felt
            realm_token_id,                 # uint 1
            0,                              # uint 2
        ],
    )

@click.command()
@click.option("--network", default="goerli")
def approve_realm(network):
    """
    Approve realm transfer
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="realms",
        function="setApprovalForAll",
        arguments=[
            int(config.L01_SETTLING_ADDRESS, 16),  # uint1
            "1",               # true
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
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_lords(address, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="lords",
        function="balanceOf",
        arguments=[address],
    )

    print(out)   

@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_realms(address, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="realms",
        function="balanceOf",
        arguments=[address],
    )
    print(out)   

@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_s_realms(address, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    if address == "":
        nile_account = Account(config.USER_ALIAS, network)
        address = nile_account.address

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="s_realms",
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
        contract_alias="realms",
        function="ownerOf",
        arguments=[realm_token_id, 0],
    )
    print(out)   

@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def check_owner_of_s_realm(realm_token_id, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="s_realms",
        function="ownerOf",
        arguments=[realm_token_id, 0],
    )
    print(out)   

@click.command()
@click.argument("unit_id", nargs=1)
@click.option("--network", default="goerli")
def get_unit_cost(unit_id, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="S06_Combat",
        function="get_troop_cost",
        arguments=[unit_id],
    )
    print(out)   

# ONLY ADMIN CAN DO THIS 
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


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def build_squad(realm_token_id, network):
    """
    Claim available resources
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="L06_Combat",
        function="build_squad_from_troops_in_realm",
        arguments=[10, 1,1,1,1,1,1,1,1,1,1,1 *uint(realm_token_id), 1],
    )

@click.command()
@click.argument("attacking_realm", nargs=1)
@click.argument("defending_realm", nargs=1)
@click.option("--network", default="goerli")
def can_attack(attacking_realm, defending_realm, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="L06_Combat",
        function="Realm_can_be_attacked",
        arguments=[*uint(attacking_realm), *uint(defending_realm)],
    )
    print(out)   

@click.command()
@click.argument("attacking_realm", nargs=1)
@click.argument("defending_realm", nargs=1)
@click.option("--network", default="goerli")
def attack_realm(attacking_realm, defending_realm, network):
    """
    Check realms balance
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="L06_Combat",
        function="initiate_combat",
        arguments=[*uint(attacking_realm), *uint(defending_realm), 1],
    )

@click.command()
@click.argument("realm_id", nargs=1)
@click.option("--network", default="goerli")
def get_troops(realm_id, network):
    """
    Gets troops on Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="L06_Combat",
        function="view_troops",
        arguments=[*uint(realm_id)],
    )
    print(out)   

@click.command()
@click.argument("realm_id", nargs=1)
@click.option("--network", default="goerli")
def get_combat_data(realm_id, network):
    """
    Gets Combat data
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="S06_Combat",
        function="get_realm_combat_data",
        arguments=[*uint(realm_id)],
    )
    print(out)   

# get happiness level of realm
# get pillageable amount