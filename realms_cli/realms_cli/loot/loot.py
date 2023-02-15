import asyncclick as click
from realms_cli.caller_invoker import wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import print_over_colums, uint, felt_to_str, convert_unix_time
from realms_cli.loot.getters import _get_loot, print_loot, print_loot_bid, print_loot_and_bid


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

    await _get_loot(loot_token_id, network)


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

    print_loot_and_bid(out)



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


@click.command()
@click.option("--network", default="goerli")
async def all_loot(network):
    """
    Get all your loot
    """
    config = Config(nile_network=network)

    print('🗡 Claiming item ...')

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi='artifacts/abis/LootMarketArcade.json',
        function="balanceOf",
        arguments=[config.USER_ADDRESS],
    )

    out = out.split(" ")


    all_items = []

    for i in range(0, int(out[0])):

        item = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_LootMarketArcade",
            abi='artifacts/abis/LootMarketArcade.json',
            function="tokenOfOwnerByIndex",
            arguments=[config.USER_ADDRESS, *uint(i)],
        )

        id = item.split(" ")

        out = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_LootMarketArcade",
            abi='artifacts/abis/LootMarketArcade.json',
            function="getItemByTokenId",
            arguments=[*uint(id[0])],
        )

        all_items.append(out)

    print_loot(all_items)

