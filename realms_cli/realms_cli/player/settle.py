# First, import click dependency
import json
import click

from nile.core.account import Account

from realms_cli.caller_invoker import call_multi, wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import parse_multi_input
from realms_cli.binary_converter import map_realm

realms_alias = 'proxy_Realms_ERC721_Mintable'
settling_alias = 'proxy_Settling'


@click.command()
@click.argument("quantity", nargs=1)
@click.option("--network", default="goerli")
def mint_realm(quantity, network):
    """
    Mint Realm
    """
    config = Config(nile_network=network)

    calldata = [
        [config.USER_ADDRESS]
        for id in enumerate(quantity)
    ]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=realms_alias,
        function="mint",
        arguments=calldata
    )


@click.command()
@click.option("--network", default="goerli")
def approve_realm(network):
    """
    Approve Realm for transfer into Settling contract
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=realms_alias,
        function="setApprovalForAll",
        arguments=[
            config.SETTLING_PROXY_ADDRESS,
            "1",               # true
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def settle(realm_token_id, network):
    """
    Settle Realm
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
        contract_alias=settling_alias,
        function="settle",
        arguments=calldata
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def unsettle(realm_token_id, network):
    """
    Unsettle Realm
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
        contract_alias=settling_alias,
        function="unsettle",
        arguments=calldata,
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

    realm_token_ids = parse_multi_input(realm_token_id)
    calldata = [
        [id, 0, map_realm(realms[str(id)], resources, wonders, orders)]
        for id in realm_token_ids
    ]

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.ADMIN_ALIAS,
        contract_alias=realms_alias,
        function="set_realm_data",
        arguments=calldata,
    )


@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def check_realms(address, network) -> str:
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
    return out


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
    print('Ser, player has ' + out[0] + ' settled Realms...')


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
    print('Ser, owner of realm id: ' + realm_token_id + " is " + out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def check_owner_of_s_realm(realm_token_id, network):
    """
    Check owner of S Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_s_realms",
        function="ownerOf",
        arguments=[realm_token_id, 0],
    )
    print('Ser, owner of settled realm id: ' + realm_token_id + " is " + out)


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


@click.command()
@click.option("--address", default="", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def get_owned(address, network):
    """
    Get owned realms and owned settled realms.
    """
    config = Config(nile_network=network)

    # out = check_realms(address, network)
    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_realms",
        function="balanceOf",
        arguments=[int(address or config.USER_ADDRESS, 16)],
    )
    n_realms, _ = out.split(" ")

    print(f"You own {n_realms} unsettled realms.")
    print("Quering which unsettled realms you own.")

    # prepare for multi-call
    calldata = [
        [int(address or config.USER_ADDRESS, 16), i, 0]
        for i in range(int(n_realms))
    ]

    stdout = call_multi(
        network=config.nile_network,
        contract_alias="proxy_realms",
        function="tokenOfOwnerByIndex",
        calldata=calldata,
    )

    realm_ids = [int(realm_id.strip(" 0\n")) for realm_id in stdout]
    realm_ids.sort()
    print(",".join(map(str, realm_ids)))

    #
    # s_realms
    #

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_s_realms",
        function="balanceOf",
        arguments=[int(address or config.USER_ADDRESS, 16)],
    )
    n_realms, _ = out.split(" ")

    print(f"You own {n_realms} settled realms.")

    # prepare for multi-call
    calldata = [
        [int(address or config.USER_ADDRESS, 16), i, 0]
        for i in range(int(n_realms))
    ]

    stdout = call_multi(
        network=config.nile_network,
        contract_alias="proxy_s_realms",
        function="tokenOfOwnerByIndex",
        calldata=calldata,
    )

    realm_ids = [int(realm_id.strip(" 0\n")) for realm_id in stdout]
    realm_ids.sort()
    print(",".join(map(str, realm_ids)))
