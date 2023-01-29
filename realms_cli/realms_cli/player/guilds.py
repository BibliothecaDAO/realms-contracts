# First, import click dependency
import click

from nile.signer import from_call_to_call_array

from starkware.starknet.public.abi import get_selector_from_name
from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config, strhex_as_strfelt


@click.command()
@click.argument("role", nargs=1)
@click.option("--address", default="2459554352240017132105304682017261260442353535047744360767061026660492963784", help="Account address in hex format 0x...")
@click.option("--network", default="goerli")
def whitelist(address, role, network):
    """
    Whitelist account to guild
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildContract",
        function="whitelist_member",
        arguments=[
            address,  # felt
            role  # felt
        ],
    )


@click.command()
@click.option("--network", default="goerli")
def join_guild(network):
    """
    Join guild with whitelisted role.
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildContract",
        function="join",
        arguments=[],
    )


@click.command()
@click.option("--network", default="goerli")
def set_settle_permission(network):
    """
    Set settle permission to the guild
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildContract",
        function="initialize_permissions",
        arguments=[
            2,  # felt
            strhex_as_strfelt(config.SETTLING_ADDRESS),  # felt
            get_selector_from_name("settle"),  # felt
            strhex_as_strfelt(config.REALMS_PROXY_ADDRESS),
            get_selector_from_name("setApprovalForAll")
        ],
    )


@click.command()
@click.option("--network", default="goerli")
def approve_realm_guild(network):
    """
    Approve Realm transfer to guild
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_realms",
        function="setApprovalForAll",
        arguments=[
            int(config.GUILD_PROXY_CONTRACT, 16),  # uint1
            "1",               # true
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def deposit_realm_to_guild(realm_token_id, network):
    """
    Deposit realm to guild
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildContract",
        function="deposit",
        arguments=[
            1,                              # felt
            int(config.REALMS_PROXY_ADDRESS, 16),         # felt
            realm_token_id,                 # uint 1
            0,
            1,                              # uint 1
            0
        ],
    )


@click.command()
@click.argument("s_realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def deposit_s_realm_to_guild(s_realm_token_id, network):
    """
    Deposit s realm to guild
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildContract",
        function="deposit",
        arguments=[
            1,                              # felt
            int(config.S_REALMS_PROXY_ADDRESS, 16),         # felt
            s_realm_token_id,                 # uint 1
            0,
            1,                              # uint 1
            0
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def settle_realm_from_guild(realm_token_id, network):
    """
    Settle realm from guild
    """
    config = Config(nile_network=network)

    calls = [
        (
            int(config.REALMS_PROXY_ADDRESS, 16),
            "setApprovalForAll",
            [int(config.SETTLING_ADDRESS, 16), 1]
        ),
        (
            int(config.SETTLING_ADDRESS, 16),
            "settle",
            [realm_token_id, 0]
        )
    ]

    (call_array, calldata) = from_call_to_call_array(calls)

    print(call_array)
    print(calldata)

    nonce = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_GuildContract",
        function="get_nonce",
        arguments=[]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildContract",
        function="execute_transactions",
        arguments=[
            len(call_array), *
            [x for t in call_array for x in t], len(calldata), *calldata, 0
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def claim_resources_from_guild(realm_token_id, network):
    """
    Claim realm resources from guild
    """
    config = Config(nile_network=network)

    calls = [
        (
            int(config.SETTLING_ADDRESS, 16),
            "claim_resources",
            [realm_token_id, 0]
        )
    ]

    (call_array, calldata) = from_call_to_call_array(calls)

    print(call_array)
    print(calldata)

    nonce = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_GuildContract",
        function="get_nonce",
        arguments=[]
    )

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_GuildContract",
        function="execute_transactions",
        arguments=[
            len(call_array), *
            [x for t in call_array for x in t], len(calldata), *calldata, 0
        ],
    )
