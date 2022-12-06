import click
from realms_cli.caller_invoker import wrapped_call, wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str


@click.command()
@click.option("--network", default="goerli")
def mint_loot(network):
    """
    Mint a Random Loot Item
    """
    config = Config(nile_network=network)

    print('🎲 Minting random item ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Loot",
        function="mint",
        arguments=[config.USER_ADDRESS]
    )

    print('🎲 Minted random item ✅')


@click.command()
@click.argument("loot_token_id", nargs=1)
@click.option("--network", default="goerli")
def get_loot(loot_token_id, network):
    """
    Get Loot Item metadata
    """
    config = Config(nile_network=network)

    out = wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Loot",
        abi='artifacts/abis/Loot.json',
        function="getItemByTokenId",
        arguments=[*uint(loot_token_id)],
    )
    out = out.split(" ")
    pretty_out = []
    for i, key in enumerate(config.LOOT):

        # Output names for item name prefix1, prefix2, and suffix
        if i in [13]:
            pretty_out.append(
                f"{key} : {felt_to_str(int(out[i]))}")
        else:
            pretty_out.append(
                f"{key} : {int(out[i])}")

    print("_________ LOOT ITEM - " + str(out[0]) + "___________")
    print_over_colums(pretty_out)

@click.command()
@click.argument("loot_token_id", nargs=1)
@click.option("--network", default="goerli")
@click.option('--item', is_flag=False,
              metavar='<columns>', type=click.STRING, help='item id', prompt=True)
@click.option('--slot', is_flag=False,
              metavar='<columns>', type=click.STRING, help='slot id', prompt=True)
@click.option('--type', is_flag=False,
              metavar='<columns>', type=click.STRING, help='type id', prompt=True)
@click.option('--material', is_flag=False,
              metavar='<columns>', type=click.STRING, help='material id', prompt=True)
@click.option('--rank', is_flag=False,
              metavar='<columns>', type=click.STRING, help='rank id', prompt=True)
@click.option('--prefix', is_flag=False,
              metavar='<columns>', type=click.STRING, help='prefix id', prompt=True)
@click.option('--greatness', is_flag=False,
              metavar='<columns>', type=click.STRING, help='greatness', prompt=True)
@click.option('--xp', is_flag=False,
              metavar='<columns>', type=click.STRING, help='xp', prompt=True)
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer', prompt=True)
@click.option('--bag', is_flag=False,
              metavar='<columns>', type=click.STRING, help='bag', prompt=True)
def set_loot(loot_token_id, network):
    """
    Set Loot Item metadata
    """
    config = Config(nile_network=network)

    print('🗡 Setting item by id ...')

    wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Loot",
        function="setItemById",
        arguments=[config.USER_ADDRESS]
    )
