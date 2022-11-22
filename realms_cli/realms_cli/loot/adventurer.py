import click
from realms_cli.caller_invoker import wrapped_call, wrapped_send
from realms_cli.config import Config
from realms_cli.utils import print_over_colums,  uint, felt_to_str, str_to_felt


@click.command()
@click.option("--network", default="goerli")
@click.option('--race', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer race', prompt=True)
@click.option('--home_realm', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer home realm', prompt=True)
@click.option('--name', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer name', prompt=True)
@click.option('--order', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer order', prompt=True)
def mint_adventurer(network, race, home_realm, name, order):
    """
    Mint a Random Loot Item
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="mint",
        arguments=[int(config.USER_ADDRESS, 16), race,
                   home_realm, str_to_felt(name), order]
    )


@click.command()
@click.argument("adventurer_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_adventurer(adventurer_token_id, network):
    """
    Get Adventurer metadata
    """
    config = Config(nile_network=network)

    out = wrapped_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        function="get_adventurer_by_id",
        arguments=[*uint(adventurer_token_id)],
    )
    out = out.split(" ")

    pretty_out = []
    for i, key in enumerate(config.ADVENTURER):

        # Output names for item name prefix1, prefix2, and suffix
        if i in [3]:
            pretty_out.append(
                f"{key} : {felt_to_str(int(out[i]))}")
        else:
            pretty_out.append(
                f"{key} : {int(out[i])}")
    print("_____________________________________________________")
    print("_____________________*+ " +
          felt_to_str(int(out[3])) + " +*______________________")
    print("_____________________________________________________")
    print_over_colums(pretty_out)


@click.command()
@click.option("--network", default="goerli")
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id', prompt=True)
@click.option('--item', is_flag=False,
              metavar='<columns>', type=click.STRING, help='item id', prompt=True)
def equip(network, adventurer, item):
    """
    Equip loot item
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="equip_item",
        arguments=[*uint(adventurer), *uint(item)]
    )

@click.command()
@click.option("--network", default="goerli")
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id', prompt=True)
@click.option('--item', is_flag=False,
              metavar='<columns>', type=click.STRING, help='item id', prompt=True)
def unequip(network, adventurer, item):
    """
    Unequip loot item
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="unequip_item",
        arguments=[*uint(adventurer), *uint(item)]
    )

@click.command()
@click.option("--network", default="goerli")
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id', prompt=True)
def explore(network, adventurer):
    """
    Explore with adventurer
    """
    config = Config(nile_network=network)

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="explore",
        arguments=[*uint(adventurer)]
    )

