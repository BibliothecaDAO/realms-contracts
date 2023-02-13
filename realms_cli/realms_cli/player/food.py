# First, import click dependency
import click

from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option('--food-type', prompt=True,
              type=click.Choice(['farms', 'fishing'], case_sensitive=False))
@click.option("--qty", prompt=True)
@click.option("--network", default="goerli")
def build_food(realm_token_id, food_type, qty, network):
    """
    Build a Farm or Fishing
    """
    config = Config(nile_network=network)

    f_type = 0

    if food_type == 'farms':
        f_type = 4
    else:
        f_type = 5

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Food",
        function="create",
        arguments=[
            realm_token_id,
            0,
            qty,
            f_type
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option('--harvest-type', prompt=True,
              type=click.Choice(['export', 'store'], case_sensitive=False))
@click.option('--food-type', prompt=True,
              type=click.Choice(['farms', 'fishing'], case_sensitive=False))
@click.option("--network", default="goerli")
def harvest(realm_token_id, harvest_type, food_type, network):
    """
    Harvest food
    """
    config = Config(nile_network=network)

    h_type = 0
    f_type = 0

    if harvest_type == 'export':
        h_type = 1
    else:
        h_type = 2

    if food_type == 'farms':
        f_type = 4
    else:
        f_type = 5

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Food",
        function="harvest",
        arguments=[
            realm_token_id,
            0,
            h_type,
            f_type
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option('--food-type', prompt=True,
              type=click.Choice(['farms', 'fishing'], case_sensitive=False))
@click.option("--network", default="goerli")
def harvests_left(realm_token_id, food_type, network):
    """
    Get harvests_left on a Realm
    """
    config = Config(nile_network=network)

    h_type = 0

    if food_type == 'farms':
        h_type = "get_farm_harvests_left"
    else:
        h_type = "get_fishing_villages_harvests_left"

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Food",
        function=h_type,
        arguments=[
            realm_token_id,                 # uint 1
            0
        ],
    )
    print(out)
    # print(out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option('--food-type', prompt=True,
              type=click.Choice(['farms', 'fishing'], case_sensitive=False))
@click.option("--network", default="goerli")
def harvests(realm_token_id, food_type, network):
    """
    Get harvests_left on a Realm
    """
    config = Config(nile_network=network)

    h_type = 0

    if food_type == 'farms':
        h_type = "get_farms_to_harvest"
    else:
        h_type = "get_fishing_villages_to_harvest"

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Food",
        function=h_type,
        arguments=[
            realm_token_id,                 # uint 1
            0
        ],
    )
    print(out)


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def store_house(realm_token_id, network):
    """
    Get harvests_left on a Realm
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Food",
        function="available_food_in_store",
        arguments=[
            realm_token_id,                 # uint 1
            0
        ],
    )
    print(int(out, 16))


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def reset(realm_token_id, network):
    """
    Get harvests_left on a Realm
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Food",
        function="reset",
        arguments=[
            realm_token_id,
            0,
        ],
    )


@click.command()
@click.argument("realm_token_id", nargs=1)
@click.option("--network", default="goerli")
def full_store_houses(realm_token_id, network):
    """
    Get full store houses 
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Food",
        function="get_full_store_houses",
        arguments=[
            realm_token_id,                 # uint 1
            0
        ],
    )
    print(int(out))
