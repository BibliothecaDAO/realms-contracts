import anyio
import asyncclick as click
from realms_cli.caller_invoker import wrapped_call, wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str, convert_unix_time

@click.command()
@click.option("--network", default="goerli")
async def mint_loot(network):
    """
    Mint a Random Loot Item
    """
    config = Config(nile_network=network)

    print('🎲 Minting random item ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Loot",
        function="mint",
        arguments=[config.ADMIN_ADDRESS]
    )

    print('🎲 Minted random item ✅')


@click.command()
@click.argument("loot_token_id", nargs=1)
@click.option("--network", default="goerli")
async def get_loot(loot_token_id, network):
    """
    Get Loot Item metadata
    """
    config = Config(nile_network=network)

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi='artifacts/abis/LootMarketArcade.json',
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
            if i == 0:
                pretty_out.append(
                    f"{key} : {config.LOOT_ITEMS[int(out[0]) -1]}")
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
@click.option('--greatness', is_flag=False,
              metavar='<columns>', type=click.STRING, help='greatness', prompt=True)
@click.option('--xp', is_flag=False,
              metavar='<columns>', type=click.STRING, help='xp', prompt=True)
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer', prompt=True)
@click.option('--bag', is_flag=False,
              metavar='<columns>', type=click.STRING, help='bag', prompt=True)
async def set_loot(loot_token_id, item, greatness, xp, adventurer, bag, network):
    """
    Set Loot Item metadata
    """
    config = Config(nile_network=network)

    print('🗡 Setting item by id ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Loot",
        function="setItemById",
        arguments=[*uint(loot_token_id), item, greatness, xp, adventurer, bag]
    )


@click.command()
@click.option("--network", default="goerli")
async def mint_daily_items(network):
    """
    Set Loot Item metadata
    """
    config = Config(nile_network=network)

    print('🗡 Setting item by id ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="mintDailyItems",
        arguments=[]
    )


@click.command()
@click.argument("loot_token_id", nargs=1)
@click.option("--network", default="goerli")
async def get_unminted_loot(loot_token_id, network):
    """
    Get Loot Item metadata
    """
    config = Config(nile_network=network)

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi='artifacts/abis/LootMarketArcade.json',
        function="viewUnmintedItem",
        arguments=[*uint(loot_token_id)],
    )
    out = out.split(" ")
    pretty_out = []
    pretty_bid_out = []
    for i, key in enumerate(config.LOOT):

        # Output names for item name prefix1, prefix2, and suffix
        if i in [13]:
            pretty_out.append(
                f"{key} : {felt_to_str(int(out[i]))}")
        else:
            if i == 0:
                pretty_out.append(
                    f"{key} : {config.LOOT_ITEMS[int(out[0]) -1]}")
            else:
                pretty_out.append(
                    f"{key} : {int(out[i])}")

    print("_________ LOOT ITEM - " + str(out[0]) + "___________")
    print_over_colums(pretty_out)

    for i, key in enumerate(config.BID):
        if key == 'Expiry':
            pretty_bid_out.append(
                f"{key} : {convert_unix_time(int(out[i + 13]))}")
        else:
            pretty_bid_out.append(
                f"{key} : {int(out[i + 13])}")

    print_over_colums(pretty_bid_out)


@click.command()
@click.option("--network", default="goerli")
@click.option('--item', is_flag=False,
              metavar='<columns>', type=click.STRING, help='item id', prompt=True)
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id for the bid, you have to bid as an adventurer not a wallet', prompt=True)
@click.option('--price', is_flag=False,
              metavar='<columns>', type=click.STRING, help='price for item, must be greater than past bid or above 10', prompt=True)
async def bid_on_item(network, item, adventurer, price):
    """
    Bid on an item. You can only bid on an item that is currently for sale and has not expired in bid.
    """
    config = Config(nile_network=network)

    print('🗡 Bidding on Item ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="bidOnItem",
        arguments=[*uint(item), *uint(adventurer), price]
    )


@click.command()
@click.option("--network", default="goerli")
@click.option('--item', is_flag=False,
              metavar='<columns>', type=click.STRING, help='item id', prompt=True)
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id for the bid, you have to bid as an adventurer not a wallet', prompt=True)
async def claim_item(network, item, adventurer):
    """
    Claim item. You can only claim past the expiry time.
    """
    config = Config(nile_network=network)

    print('🗡 Claiming item ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="claimItem",
        arguments=[*uint(item), *uint(adventurer)]
    )
