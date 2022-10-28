# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call
from realms_cli.config import Config


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def happiness(realm_token_id, network):
    """
    Fetch happiness of a Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Calculator",
        function="calculate_happiness",
        arguments=[
            realm_token_id,                 # uint 1
            0,
        ],
    )
    print(out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def troop_population(realm_token_id, network):
    """
    Fetch trooop population on a Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Calculator",
        function="calculate_troop_population",
        arguments=[
            realm_token_id,                 # uint 1
            0,
        ],
    )
    print(out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def culture(realm_token_id, network):
    """
    Fetch culture on a Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Calculator",
        function="calculate_culture",
        arguments=[
            realm_token_id,                 # uint 1
            0,
        ],
    )
    print(out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def population(realm_token_id, network):
    """
    Fetch population on a Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Calculator",
        function="calculate_population",
        arguments=[
            realm_token_id,  # uint 1
            0,
        ],
    )
    print(out)
