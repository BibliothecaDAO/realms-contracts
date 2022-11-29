import click
from realms_cli.caller_invoker import wrapped_proxy_call, wrapped_send
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

    print('🪙 Minting lords ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="mint",
        arguments=[
            config.USER_ADDRESS,
            100,           # uint 1
            0              # uint 2
        ]
    )

    print('🪙 Minted lords ✅')

    print('👍 Approving lords to be spent ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="approve",
        arguments=[
            config.ADVENTURER_PROXY_ADDRESS,
            100,              # uint 1
            0,                # uint 2
        ]
    )

    print('👍 Approved lords to be spent ✅')

    print('🤴 Minting adventurer ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="mint",
        arguments=[
            config.USER_ADDRESS,
            int(race),
            int(home_realm),
            str_to_felt(name),
            int(order)
        ]
    )

    print('🤴 Minted adventurer ✅')


@click.command()
@click.argument("adventurer_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_adventurer(adventurer_token_id, network):
    """
    Get Adventurer metadata
    """
    config = Config(nile_network=network)

    out = wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi='artifacts/abis/Adventurer.json',
        function="get_adventurer_by_id",
        arguments=[*uint(adventurer_token_id)]
    )

    out = out.split(" ")

    pretty_out = []
    for i, key in enumerate(config.ADVENTURER):

        # Output names for item name prefix1, prefix2, and suffix
        if i in [25]:
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

    print('🫴 Equiping item ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="equip_item",
        arguments=[*uint(adventurer), *uint(item)]
    )

    print('🫴 Equiped item ✅')

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

    print('🫳 Unequiping item ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="unequip_item",
        arguments=[*uint(adventurer), *uint(item)]
    )

    print('🫳 Unequiped item ...')

@click.command()
@click.option("--network", default="goerli")
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id', prompt=True)
def explore(network, adventurer):
    """
    Explore with adventurer
    """
    config = Config(nile_network=network)

    print('👣 Exploring ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="explore",
        arguments=[*uint(adventurer)]
    )

    print('👣 Explored ✅')

    out = wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi='artifacts/abis/Adventurer.json',
        function="get_adventurer_by_id",
        arguments=[*uint(adventurer)]
    )

    out = out.split(" ")

    if out[24] == '1':
        print("🧌 You have discovered a beast")
    else:
        print("🤔 You discovered nothing")
