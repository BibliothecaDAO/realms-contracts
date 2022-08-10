# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.shared import uint


@click.command()
@click.argument("unit_id", nargs=1)
@click.option("--network", default="goerli")
def get_unit_cost(unit_id, network):
    """
    Get unit cost
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L06_Combat",
        function="get_troop_cost",
        arguments=[unit_id],
    )
    print(out)


@click.command()
@click.option('--troops', is_flag=False,
              metavar='<columns>', type=click.STRING, help='Troop Ids', prompt=True)
@click.option("--network", default="goerli")
@click.option('--realm_token_id', help='Realm Id', prompt=True)
def build_squad(network, troops, realm_token_id):
    """
    Build squad on a Realm
    """
    troops = [c.strip() for c in troops.split(',')]
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_L06_Combat",
        function="build_squad_from_troops_in_realm",
        arguments=[len(troops), *troops,
                   *uint(realm_token_id), 1],
    )


@click.command()
@click.argument("attacking_realm", nargs=1)
@click.argument("defending_realm", nargs=1)
@click.option("--network", default="goerli")
def can_attack(attacking_realm, defending_realm, network):
    """
    Check can attack Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L06_Combat",
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
    Attack a Realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_L06_Combat",
        function="initiate_combat",
        arguments=[*uint(attacking_realm), *uint(defending_realm)],
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
        contract_alias="proxy_L06_Combat",
        function="view_troops",
        arguments=[*uint(realm_id)],
    )
    print(out)


@click.command()
@click.argument("realm_id", nargs=1)
@click.option("--network", default="goerli")
def get_combat_data(realm_id, network):
    """
    Gets combat data of Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L06_Combat",
        function="get_realm_combat_data",
        arguments=[*uint(realm_id)],
    )
    print(out)


@click.command()
@click.option("--network", default="goerli")
def get_xoroshiro(network):
    """
    Gets xoroshiro random number
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_L06_Combat",
        function="get_xoroshiro",
        arguments=[1],
    )
    print(out)
