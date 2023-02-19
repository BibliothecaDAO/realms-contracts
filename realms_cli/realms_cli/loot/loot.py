import asyncclick as click
from realms_cli.caller_invoker import wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import uint
from realms_cli.loot.getters import _get_loot, print_loot, print_loot_bid, print_loot_and_bid,  _get_adventurer, _get_beast, print_adventurer
from realms_cli.loot.constants import BEASTS

@click.group()
def loot():
    pass


@loot.command()
@click.option(
    "--loot_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="loot_token_id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def get(loot_token_id, network):
    """
    Get Loot Item metadata
    """

    await _get_loot(loot_token_id, network)

@loot.command()
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
        function="mint_daily_items",
        arguments=[]
    )


@loot.command()
@click.option(
    "--loot_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="loot_token_id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def market(loot_token_id, network):
    """
    Get Loot Item metadata
    """
    config = Config(nile_network=network)

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi='artifacts/abis/LootMarketArcade.json',
        function="view_unminted_item",
        arguments=[*uint(loot_token_id)],
    )
    out = out.split(" ")

    print_loot_and_bid([out])

@loot.command()
@click.option(
    "--start_id",
    is_flag=False,
    metavar="<columns>",
    type=click.INT,
    help="start_id",
    prompt=True,
)
@click.option(
    "--end_id",
    is_flag=False,
    metavar="<columns>",
    type=click.INT,
    help="end_id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def all_market(start_id, end_id, network):
    """
    Get Loot Item metadata
    """
    config = Config(nile_network=network)

    items = []

    for i in range((end_id + 1) - start_id):
        out = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_LootMarketArcade",
            abi='artifacts/abis/LootMarketArcade.json',
            function="view_unminted_item",
            arguments=[*uint(i + start_id)],
        )
        out = out.split(" ")
        out.insert(0, str(i + start_id))
        print(out)
        
        items.append(out)

    # print(items)
    print_loot_and_bid(items)


@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--loot_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="loot_token_id",
    prompt=True,
)
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id for the bid, you have to bid as an adventurer not a wallet', prompt=True)
@click.option('--price', is_flag=False,
              metavar='<columns>', type=click.STRING, help='price for item, must be greater than past bid or above 10', prompt=True)
async def bid(network, loot_token_id, adventurer, price):
    """
    Bid on an item. You can only bid on an item that is currently for sale and has not expired in bid.
    """
    config = Config(nile_network=network)

    print('🗡 Bidding on Item ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="bid_on_item",
        arguments=[*uint(loot_token_id), *uint(adventurer), price]
    )


@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--loot_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="loot_token_id",
    prompt=True,
)
@click.option('--adventurer', is_flag=False,
              metavar='<columns>', type=click.STRING, help='adventurer id for the bid, you have to bid as an adventurer not a wallet', prompt=True)
async def claim(network, loot_token_id, adventurer):
    """
    Claim item. You can only claim past the expiry time.
    """
    config = Config(nile_network=network)

    print('🗡 Claiming item ...')

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="claim_item",
        arguments=[*uint(loot_token_id), *uint(adventurer)]
    )


@loot.command()
@click.option("--network", default="goerli")
async def bag(network):
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
            function="get_item_by_token_id",
            arguments=[*uint(id[0])],
        )
        out = out.split(" ")
        out.insert(0, str(int(id[0])))
        all_items.append(out)

    print_loot(all_items)


@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
async def health(network, adventurer_token_id):
    """
    Purchase health for gold
    """
    config = Config(nile_network=network)

    print("🧪 Purchasing health ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="purchase_health",
        arguments=[*uint(adventurer_token_id)],
    )

    print("🧪 Purchased health ✅")

@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option(
    "--stat",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="stat id",
    prompt=True,
)
async def upgrade(network, adventurer_token_id, stat_id):
    """
    Upgrade adventurer stat
    """
    config = Config(nile_network=network)

    print("💪 Upgrading stat ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="upgrade_stat",
        arguments=[*uint(adventurer_token_id), stat_id]
    )

    print("💪 Upgraded stat ✅")


@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
async def explore(network, adventurer_token_id):
    """
    Explore with adventurer
    """
    config = Config(nile_network=network)

    print("👣 Exploring ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="explore",
        arguments=[*uint(adventurer_token_id)],
    )

    print("👣 Explored ✅")

    out = await _get_adventurer(network, adventurer_token_id)

    if out[23] == "1":
        print("🧌 You have discovered a beast")
        await _get_beast(out[26], network)
    else:
        print("🤔 You discovered nothing")


@loot.command()
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def adventurer(adventurer_token_id, network):
    """
    Get Adventurer metadata
    """

    await _get_adventurer(network, adventurer_token_id)


@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option(
    "--item",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="item id",
    prompt=True,
)
async def equip(network, adventurer_token_id, item):
    """
    Equip loot item
    """
    config = Config(nile_network=network)

    print("🫴 Equiping item ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="equip_item",
        arguments=[*uint(adventurer_token_id), *uint(item)],
    )

    print("🫴 Equiped item ✅")
    await _get_adventurer(network, adventurer_token_id)


@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option(
    "--item",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="item id",
    prompt=True,
)
async def unequip(network, adventurer_token_id, item):
    """
    Unequip loot item
    """
    config = Config(nile_network=network)

    print("🫳 Unequiping item ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="unequip_item",
        arguments=[*uint(adventurer_token_id), *uint(item)],
    )

    print("🫳 Unequiped item ...")
    await _get_adventurer(network, adventurer_token_id)    


@loot.command()
@click.option("--network", default="goerli")
async def all_adventurers(network):
    """
    Get all your Adventurers you own.
    """
    config = Config(nile_network=network)

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi="artifacts/abis/Adventurer.json",
        function="balance_of",
        arguments=[config.USER_ADDRESS],
    )

    out = out.split(" ")

    all_items = []

    for i in range(0, int(out[0])):
        item = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_Adventurer",
            abi="artifacts/abis/Adventurer.json",
            function="token_of_owner_by_index",
            arguments=[config.USER_ADDRESS, *uint(i)],
        )

        id = item.split(" ")

        out = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_Adventurer",
            abi="artifacts/abis/Adventurer.json",
            function="get_adventurer_by_id",
            arguments=[*uint(id[0])],
        )

        all_items.append(out)

    print_adventurer(all_items)    
    
@loot.command()
@click.option(
    "--beast_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="beast id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def beast(beast_token_id, network):
    """
    Get Beast metadata
    """
    await _get_beast(beast_token_id, network)    

@loot.command()
@click.option(
    "--beast_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="beast id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def attack(beast_token_id, network):
    """
    Attack beast
    """
    config = Config(nile_network=network)

    print("🧌 Attacking beast ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="attack",
        arguments=[*uint(beast_token_id)],
    )

    print("🧌 Attacked beast ✅")

    beast_out = await _get_beast(beast_token_id, network)

    adventurer_out = await _get_adventurer(network, beast_out[7])

    if adventurer_out[4] == "0":
        print(f"🪦 You have been killed")
    else:
        print(
            f"🤕 You didn't kill and were counterattacked, you have {adventurer_out[7]} health remaining"
        )

    if beast_out[6] == "0":
        print(f"💀 You have killed the {BEASTS[str(int(beast_out[0]))]} 🎉")
    else:
        print(
            f"👹 You hurt the {BEASTS[str(int(beast_out[0]))]}, health is now {beast_out[6]}"
        )


@loot.command()
@click.option(
    "--beast_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="beast id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def flee(beast_token_id, network):
    """
    Flee from beast
    """
    config = Config(nile_network=network)

    print("🏃‍♂️ Fleeing from beast ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="flee",
        arguments=[*uint(beast_token_id)],
    )

    beast_out = await _get_beast(beast_token_id, network)

    adventurer_out = await _get_adventurer(network, beast_out[7])

    if adventurer_out[23] == "0":
        print(f"🏃‍♂️ You successfully fled from beast ✅")
    if adventurer_out[23] == "1":
        print(f"😫 You have been ambushed! Your health is now {adventurer_out[4]}")


@loot.command()
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def balance(network, adventurer_token_id):
    """
    Get all your Adventurers you own.
    """
    config = Config(nile_network=network)

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Beast",
        abi="artifacts/abis/Beast.json",
        function="balance_of",
        arguments=[*uint(adventurer_token_id)],
    )

    print(out)
