import asyncclick as click
from realms_cli.caller_invoker import (
    wrapped_send,
    wrapped_proxy_call,
    parse_send,
    get_transaction_result,
)
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
    _get_gold_balance,
)
from realms_cli.loot.constants import (
    BEASTS,
    OBSTACLES,
    DISCOVERY_TYPES,
    ITEM_DISCOVERY_TYPES,
)
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

    print("🗡 Daily items minted ✅")


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
    out.insert(0, "0")

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
    help="price for item, must be greater than past bid or above 2",
    prompt=True,
)
async def bid(network, loot_token_id, adventurer_token_id, price):
    """
    Bid on an item. You can only bid on an item that is currently for sale and has not expired in bid.
    """
    config = Config(nile_network=network)

    print("🗡 Bidding on Item ...")

    token_ids = [c.strip() for c in loot_token_id.split(",")]
    prices = [c.strip() for c in price.split(",")]

    print(len(token_ids))

    if len(token_ids) > 1:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_LootMarketArcade",
            function="bid_on_item",
            arguments=[
                [*uint(token_id), *uint(adventurer_token_id), price]
                for token_id, price in zip(token_ids, prices)
            ],
        )
    else:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_LootMarketArcade",
            function="bid_on_item",
            arguments=[*uint(token_ids[0]), *uint(adventurer_token_id), prices[0]],
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
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id for the bid, you have to bid as an adventurer not a wallet",
    prompt=True,
)
async def claim(network, loot_token_id, adventurer_token_id):
    """
    Claim item. You can only claim past the expiry time.
    """
    config = Config(nile_network=network)

    print("🗡 Claiming item ...")

    token_ids = [c.strip() for c in loot_token_id.split(",")]

    if len(token_ids) > 1:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_LootMarketArcade",
            function="claim_item",
            arguments=[
                [*uint(token_id), *uint(adventurer_token_id)] for token_id in token_ids
            ],
        )
    else:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_LootMarketArcade",
            function="claim_item",
            arguments=[*uint(token_ids[0]), *uint(adventurer_token_id)],
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
    "--adventurer_token_id",
    is_flag=False,
    metavar="<columns>",
    type=click.STRING,
    help="adventurer id for the bid, you have to bid as an adventurer not a wallet",
    prompt=True,
)
async def claim_equip(network, loot_token_id, adventurer_token_id):
    """
    Claim and equip item. You can only claim past the expiry time.
    """
    config = Config(nile_network=network)

    # print("🗡 Claiming item ...")

    token_ids = [c.strip() for c in loot_token_id.split(",")]

    if len(token_ids) > 1:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_LootMarketArcade",
            function="claim_item",
            arguments=[
                [*uint(token_id), *uint(adventurer_token_id)] for token_id in token_ids
            ],
        )
    else:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_LootMarketArcade",
            function="claim_item",
            arguments=[*uint(token_ids[0]), *uint(adventurer_token_id)],
        )

    print("🗡 Claimed item ✅")

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_LootMarketArcade",
        abi="artifacts/abis/LootMarketArcade.json",
        function="totalSupply",
        arguments=[],
    )

    out = out.split(" ")

    start_token = int(out[0]) - int(len(token_ids))

    equipping_tokens = []

    for i in range(start_token, int(out[0])):
        equipping_tokens.append(i)

    print("🫴 Equiping item ...")

    if len(equipping_tokens) > 1:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_Adventurer",
            function="equip_item",
            arguments=[
                [*uint(adventurer_token_id), *uint(token_id)]
                for token_id in equipping_tokens
            ],
        )
    else:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_Adventurer",
            function="equip_item",
            arguments=[*uint(adventurer_token_id), *uint(int(out[0]))],
        )

    print("🫴 Equiped item ✅")


@loot.command()
@click.option("--network", default="goerli")
async def bag(network):
    """
    Get all your loot
    """
    config = Config(nile_network=network)

    print("🗡 Getting owned items ...")

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

    pre_adventurer = await _get_adventurer(network, adventurer_token_id)

    pre_gold = await _get_gold_balance(network, adventurer_token_id)

    send_out = await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="explore",
        arguments=[*uint(adventurer_token_id)],
    )

    _, tx_hash = parse_send(send_out)

    result = await get_transaction_result(network, tx_hash)

    print("👣 Explored ✅")

    adventurer_out = await _get_adventurer(network, adventurer_token_id)

    gold_out = await _get_gold_balance(network, adventurer_token_id)

    if int(result[0], 16) == 0:
        print(
            f"🤔 You discovered nothing, but got {str(int(adventurer_out[16]) - int(pre_adventurer[16]))} xp anyway!"
        )
    if int(result[0], 16) == 1:
        print("🧌 You have discovered a beast")
        print_beast_img(adventurer_out[26])
        await _get_beast(adventurer_out[26], network)
    if int(result[0], 16) == 2:
        if int(pre_adventurer[7]) - int(adventurer_out[7]) == 0:
            print(f"🥷 You discovered {OBSTACLES[int(result[1],16)]}, but avoided it!")
        else:
            print(
                f"🪤 You were hit by {OBSTACLES[int(result[1],16)]} and took {str(int(pre_adventurer[7]) - int(adventurer_out[7]))} damage!"
            )
    if int(result[0], 16) == 3:
        print(f"🎉 You discovered loot!")
        if int(result[1], 16) == 0:
            print(f"🤑 You discovered {str(int(gold_out) - int(pre_gold))} gold")
        if int(result[1], 16) == 1:
            print(f"🗡️ You discovered an item!")
        if int(result[1], 16) == 2:
            print(
                f"🧪 You discovered a potion for {str(int(adventurer_out[7]) - int(pre_adventurer[7]))} health!"
            )


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
    help="Loot item ids seperated by a comma",
    prompt=True,
)
async def equip(network, adventurer_token_id, loot_token_id):
    """
    Equip loot item
    """
    config = Config(nile_network=network)

    print("🫴 Equiping item ...")

    token_ids = [c.strip() for c in loot_token_id.split(",")]

    if len(token_ids) > 1:
        await wrapped_send(
            network=config.nile_network,
            signer_alias=config.USER_ALIAS,
            contract_alias="proxy_Adventurer",
            function="equip_item",
            arguments=[
                [*uint(adventurer_token_id), *uint(token_id)] for token_id in token_ids
            ],
        )
    else:
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
            if int(pre_beast[6]) - int(beast_out[6]) == 0:
                print(
                    f"😖 The {BEASTS[str(int(beast_out[0]))]}'s armor is too strong, you do no damage."
                )
            else:
                print(
                    f"👹 You did {str(int(pre_beast[6]) - int(beast_out[6]))} damage to the {BEASTS[str(int(beast_out[0]))]}, its health is now {beast_out[6]}"
                )
            if adventurer_out[7] == "0":
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

    send_out = await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Beast",
        function="flee",
        arguments=[*uint(pre_adventurer[26])],
    )

    _, tx_hash = parse_send(send_out)

    result = await get_transaction_result(network, tx_hash)

    beast_out = await _get_beast(pre_adventurer[26], network)

    adventurer_out = await _get_adventurer(network, adventurer_token_id)

    if int(result[0], 16) == 1:
        print(f"🏃‍♂️ You successfully fled from the {BEASTS[str(int(beast_out[0]))]} ✅")
    else:
        if int(pre_adventurer[7]) > int(adventurer_out[7]):
            print(
                f"😫 You have been ambushed by the {BEASTS[str(int(beast_out[0]))]} and took {str(int(pre_adventurer[7]) - int(adventurer_out[7]))} damage!"
            )
        else:
            print(f"😮 You did not flee from the {BEASTS[str(int(beast_out[0]))]}!")


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
    Mint a new adventurer
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
            config.USER_ADDRESS,
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
@click.option("--network", default="goerli")
async def get_thief(network):
    """
    Get information about the thief
    """
    config = Config(nile_network=network)

    print("♔ Getting thief info ...")

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi="artifacts/abis/Adventurer.json",
        function="get_thief",
        arguments=[],
    )
    print(out)


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
async def rob_king(network, adventurer_token_id):
    """
    Attempt to rob the king
    """
    config = Config(nile_network=network)

    print("👑 Attempting to rob the king ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="rob_king",
        arguments=[*uint(adventurer_token_id)],
    )

    print("👑 heist in progress ✅")


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
async def kill_thief(network, adventurer_token_id):
    """
    Kill the thief
    """
    config = Config(nile_network=network)

    print("👑 Kill the thief ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="kill_thief",
        arguments=[*uint(adventurer_token_id)],
    )

    print("👑 successfully killed the thief ✅")


@loot.command()
@click.option("--network", default="goerli")
async def claim_king_loot(network):
    """
    Claim loot from robbing the king
    """
    config = Config(nile_network=network)

    print("🪙 Claiming loot from king ...")

    await wrapped_send(
        network=config.nile_network,
        signer_alias=config.USER_ALIAS,
        contract_alias="proxy_Adventurer",
        function="claim_king_loot",
        arguments=[],
    )

    print("🪙 Loot claimed ✅")
