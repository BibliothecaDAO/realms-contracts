import asyncclick as click
from realms_cli.caller_invoker import wrapped_send, wrapped_proxy_call
from realms_cli.config import Config
from realms_cli.utils import uint, str_to_felt
from realms_cli.loot.getters import (
    _get_loot,
    print_loot,
    print_loot_and_bid,
    _get_adventurer,
    _get_beast,
    print_adventurer,
    print_beast_img,
    print_player,
)
from realms_cli.loot.constants import BEASTS
import time


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

    print("🗡 Setting item by id ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="mint_daily_items",
        arguments=[],
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
        abi="artifacts/abis/LootMarketArcade.json",
        function="view_unminted_item",
        arguments=[*uint(loot_token_id)],
    )
    out = out.split(" ")

    print_loot_and_bid([out])


@loot.command()
@click.option("--network", default="goerli")
async def all_market(network):
    """
    Get Loot Item metadata
    """
    config = Config(nile_network=network)

    current_index = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi="artifacts/abis/LootMarketArcade.json",
        function="get_mint_index",
        arguments=[],
    )

    new_items = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi="artifacts/abis/LootMarketArcade.json",
        function="get_new_items",
        arguments=[],
    )

    start = int(current_index) - int(new_items)

    items = []

    for i in range((int(current_index) + 1) - start):
        out = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_LootMarketArcade",
            abi="artifacts/abis/LootMarketArcade.json",
            function="view_unminted_item",
            arguments=[*uint(i + start)],
        )
        out = out.split(" ")
        out.insert(0, str(i + start))
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
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id for the bid, you have to bid as an adventurer not a wallet",
    prompt=True,
)
@click.option(
    "--price",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="price for item, must be greater than past bid or above 10",
    prompt=True,
)
async def bid(network, loot_token_id, adventurer, price):
    """
    Bid on an item. You can only bid on an item that is currently for sale and has not expired in bid.
    """
    config = Config(nile_network=network)

    print("🗡 Bidding on Item ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="bid_on_item",
        arguments=[*uint(loot_token_id), *uint(adventurer), price],
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
@click.option(
    "--adventurer",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id for the bid, you have to bid as an adventurer not a wallet",
    prompt=True,
)
async def claim(network, loot_token_id, adventurer):
    """
    Claim item. You can only claim past the expiry time.
    """
    config = Config(nile_network=network)

    print("🗡 Claiming item ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_LootMarketArcade",
        function="claim_item",
        arguments=[*uint(loot_token_id), *uint(adventurer)],
    )


@loot.command()
@click.option("--network", default="goerli")
async def bag(network):
    """
    Get all your loot
    """
    config = Config(nile_network=network)

    print("🗡 Claiming item ...")

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi="artifacts/abis/LootMarketArcade.json",
        function="balanceOf",
        arguments=[config.USER_ADDRESS],
    )

    out = out.split(" ")

    all_items = []

    for i in range(0, int(out[0])):
        item = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_LootMarketArcade",
            abi="artifacts/abis/LootMarketArcade.json",
            function="tokenOfOwnerByIndex",
            arguments=[config.USER_ADDRESS, *uint(i)],
        )

        id = item.split(" ")

        out = await wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_LootMarketArcade",
            abi="artifacts/abis/LootMarketArcade.json",
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
@click.option(
    "--number",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="number of health potions",
    prompt=True,
)
async def health(network, adventurer_token_id, number):
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
        arguments=[*uint(adventurer_token_id), number],
    )

    adventurer_out = await _get_adventurer(network, adventurer_token_id)

    print(f"🧪 You bought {number} potions. Your health is now {adventurer_out[7]}")


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
    "--stat_id",
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
        arguments=[*uint(adventurer_token_id), stat_id],
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
@click.pass_context
async def explore(ctx, network, adventurer_token_id):
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

    if out[25] == "1":
        print("🧌 You have discovered a beast")
        print_beast_img(out[26])
        await _get_beast(out[26], network)
    else:
        await ctx.forward(explore)
        await ctx.invoke(
            explore, ctx=ctx, network=network, adventurer_token_id=adventurer_token_id
        )
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

    print_player()
    _adventurer = await _get_adventurer(network, adventurer_token_id)

    split = _adventurer[17:25]

    all_items = []

    for i in _adventurer[17:25]:
        out = await wrapped_proxy_call(
            network=network,
            contract_alias="proxy_LootMarketArcade",
            abi="artifacts/abis/LootMarketArcade.json",
            function="get_item_by_token_id",
            arguments=[*uint(i)],
        )
        out = out.split(" ")
        out.insert(0, str(int(i)))
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
@click.option(
    "--loot_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="item id",
    prompt=True,
)
async def equip(network, adventurer_token_id, loot_token_id):
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
        arguments=[*uint(adventurer_token_id), *uint(loot_token_id)],
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
    "--loot_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="item id",
    prompt=True,
)
async def unequip(network, adventurer_token_id, loot_token_id):
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
        arguments=[*uint(adventurer_token_id), *uint(loot_token_id)],
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
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="Adventuer Id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def attack(adventurer_token_id, network):
    """
    Attack beast
    """
    config = Config(nile_network=network)

    print("🧌 Attacking beast ...")

    pre_adventurer = await _get_adventurer(network, adventurer_token_id)

    pre_beast = await _get_beast(pre_adventurer[26], network)

    if pre_adventurer[26] != "0":
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_Beast",
            function="attack",
            arguments=[*uint(pre_adventurer[26])],
        )

        print("🧌 Attacked beast ✅")

        beast_out = await _get_beast(pre_adventurer[26], network)

        adventurer_out = await _get_adventurer(network, beast_out[7])

        if beast_out[6] == "0":
            print(
                f"💀 You dealt {str(int(pre_beast[6]) - int(beast_out[6]))} damage and have killed the {BEASTS[str(int(beast_out[0]))]} 🎉"
            )
        else:
            print(
                f"👹 You did {str(int(pre_beast[6]) - int(beast_out[6]))} damage to the {BEASTS[str(int(beast_out[0]))]}, its health is now {beast_out[6]}"
            )
            if adventurer_out[4] == "0":
                print(
                    f"🪦 You took {str(int(pre_adventurer[7]) - int(adventurer_out[7]))} damage and have been killed"
                )
            else:
                print(
                    f"🤕 You didn't kill and were counterattacked losing {str(int(pre_adventurer[7]) - int(adventurer_out[7]))} health, you have {adventurer_out[7]} health remaining"
                )

    else:
        print("You are not in a battle...")


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
async def flee(adventurer_token_id, network):
    """
    Flee from beast
    """
    config = Config(nile_network=network)

    print("🏃‍♂️ Fleeing from beast ...")

    pre_adventurer = await _get_adventurer(network, adventurer_token_id)

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="flee",
        arguments=[*uint(pre_adventurer[26])],
    )

    beast_out = await _get_beast(pre_adventurer[26], network)

    adventurer_out = await _get_adventurer(network, adventurer_token_id)

    if adventurer_out[23] == "0":
        print(f"🏃‍♂️ You successfully fled from {BEASTS[str(int(beast_out[0]))]} ✅")
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
    Get the balance of gold your Adventurer owns.
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


@loot.command()
@click.option("--network", default="goerli")
@click.option(
    "--item",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer item to start",
    prompt=True,
)
@click.option(
    "--race",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer race",
    prompt=True,
)
@click.option(
    "--home_realm",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer home realm",
    prompt=True,
)
@click.option(
    "--name",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer name",
    prompt=True,
)
@click.option(
    "--order",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer order",
    prompt=True,
)
@click.option(
    "--image_hash_1",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer image hash part 1",
    prompt=True,
)
@click.option(
    "--image_hash_2",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer image hash part 2",
    prompt=True,
)
async def new(network, item, race, home_realm, name, order, image_hash_1, image_hash_2):
    """
    Mint a Random Loot Item
    """
    config = Config(nile_network=network)

    print("🪙 Minting lords ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="mint",
        arguments=[config.USER_ADDRESS, 100 * 10**18, 0],  # uint 1  # uint 2
    )

    print("🪙 Harvesting lords ✅")

    print("👍 Approving lords to be spent ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias=config.Lords_ERC20_Mintable_alias,
        function="approve",
        arguments=[
            config.ADVENTURER_PROXY_ADDRESS,
            100 * 10**18,  # uint 1
            0,  # uint 2
        ],
    )

    print("👍 Approved lords to be spent ✅")

    print("🤴 Minting adventurer ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="mint_with_starting_weapon",
        arguments=[
            config.USER_ADDRESS,
            race,
            home_realm,
            str_to_felt(name),
            order,
            image_hash_1,
            image_hash_2,
            item,
        ],
    )

    print_player()
    print("In the void between worlds, a mighty warrior was born.")
    time.sleep(2)
    print(
        "His name was "
        + name
        + ", and he was forged from the very fabric of the ether."
    )
    time.sleep(2)
    print(
        "He emerged into the world with a sense of purpose and power, his very presence filling the air with electricity."
    )
    time.sleep(2)
    print(
        ""
        + name
        + " knew that he had been born for a reason, and he was eager to discover what that reason was."
    )
    time.sleep(2)
    print(
        "He set out into the unknown, his eyes fixed on the horizon, his heart filled with determination."
    )
    time.sleep(2)
    print(
        "As he journeyed through the strange and wondrous land, he encountered many challenges."
    )
    time.sleep(2)
    print(
        "But "
        + name
        + " was not deterred. He was a creature of the void, born to overcome any obstacle that stood in his way."
    )
    time.sleep(2)
    print(
        "And so he pushed on, through fire and ice, through darkness and light, until he reached his ultimate destination."
    )
    time.sleep(2)
    print(
        "There, in the heart of the world, he found his true purpose, his reason for being."
    )
    time.sleep(2)
    print(
        "And with a final surge of power, he fulfilled his destiny, becoming a legend that would be spoken of for generations to come."
    )


@loot.command()
@click.option(
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="Adventuer Id",
    prompt=True,
)
@click.option("--network", default="goerli")
async def become_king(network, adventurer_token_id):
    """
    Become adventurer king.
    """
    config = Config(nile_network=network)

    print("👑 Applying for king ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="become_king",
        arguments=[*uint(adventurer_token_id)],
    )

    print("👑 Became King ✅")


@loot.command()
@click.option("--network", default="goerli")
async def pay_king_tribute(network, adventurer_token_id):
    """
    Pay the king his tribute.
    """
    config = Config(nile_network=network)

    print("🪙 Paying king their tribute ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="pay_king_tribute",
        arguments=[],
    )

    print("🪙 King tribute paid ✅")
