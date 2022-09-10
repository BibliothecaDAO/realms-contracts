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
        contract_alias="proxy_Combat",
        function="get_troop_cost",
        arguments=[unit_id],
    )
    print(out)


@click.command()
# @click.option('--battalionIds', is_flag=False,
#               metavar='<columns>', type=click.STRING, help='Battalion Ids', prompt=True)
# @click.option('--battalionQty', is_flag=False,
#               metavar='<columns>', type=click.STRING, help='Battalion qty', prompt=True)
@click.option("--network", default="goerli")
@click.option('--realm_token_id', help='Realm Id', prompt=True)
# @click.option('--realm_army_id', help='Realm Army Id', prompt=True)
def build_squad(network, realm_token_id):
    """
    Build squad on a Realm
    """
    # battalionIds = [c.strip() for c in battalionIds.split(',')]
    # battalionQty = [c.strip() for c in battalionQty.split(',')]
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Combat",
        function="build_army_from_battalions",
        arguments=[*uint(realm_token_id), 1,
                   2, 1, 2,
                   2, 2, 2,
                   ],
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
        contract_alias="proxy_Combat",
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
        contract_alias="proxy_Combat",
        function="initiate_combat",
        arguments=[1, *uint(attacking_realm), 0, *uint(defending_realm)],
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
        contract_alias="proxy_Combat",
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
        contract_alias="proxy_Combat",
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
        contract_alias="proxy_Combat",
        function="get_xoroshiro",
        arguments=[1],
    )
    print(out)


@click.command()
@click.argument("realm_id", nargs=1)
@click.option("--network", default="goerli")
def get_goblins(network, realm_id):
    """
    Get goblin strength and timestamp
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_GoblinTown",
        function="get_strength_and_timestamp",
        arguments=[*uint(realm_id)],
    )
    print(out)


@click.command()
@click.argument("realm_id", nargs=1)
@click.option("--network", default="goerli")
def get_goblin_squad(network, realm_id):
    """
    Get Goblins squad on Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_GoblinTown",
        function="get_goblin_squad",
        arguments=[*uint(realm_id)],
    )
    print(out)


@click.command()
@click.argument("realm_id", nargs=1)
@click.option("--network", default="goerli")
def attack_goblins(network, realm_id):
    """
    Attack Goblins
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Combat",
        function="attack_goblin_town",
        arguments=[*uint(realm_id)],
    )
