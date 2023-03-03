import asyncio
import datetime
import dearpygui.dearpygui as dpg
import subprocess
from realms_cli.config import Config
from realms_cli.caller_invoker import wrapped_proxy_call
from realms_cli.loot.constants import ITEMS, RACES, ORDERS, STATS, BEASTS
from realms_cli.utils import uint, felt_to_str
from realms_cli.loot.getters import (
    format_array,
    _get_beast,
    _get_adventurer,
    print_loot_and_bid,
)


async def get_adventurers():
    config = Config(nile_network="goerli")

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi="artifacts/abis/Adventurer.json",
        function="balance_of",
        arguments=[config.USER_ADDRESS],
    )

    out = out.split(" ")

    all_adventurers = []

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

        # print(felt_to_str(int(out[3])))
        out = out.split(" ")
        # needing to add to get rid of weird bytecode
        if out[3].startswith("0x"):
            out = felt_to_str(int(out[3], 16))
        else:
            out = felt_to_str(int(out[3]))
        all_adventurers.append("".join(out).replace("\x00", "") + " - " + id[0])
    return all_adventurers


def get_items():
    asyncio.run(get_market_items())


async def update_adventurer_list():
    adventurers = await get_adventurers()
    dpg.configure_item("adventurer_id", items=adventurers)
    dpg.configure_item("bid_adventurer_id", items=adventurers)
    dpg.configure_item("equip_adventurer_id", items=adventurers)
    dpg.configure_item("unequip_adventurer_id", items=adventurers)
    dpg.configure_item("upgrade_adventurer_id", items=adventurers)
    dpg.configure_item("potions_adventurer_id", items=adventurers)
    dpg.configure_item("king_adventurer_id", items=adventurers)


def get_adventurer(sender, app_data, user_dat):
    dpg.add_text(
        "Getting adventurer",
        tag="get_adventurer_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    value = dpg.get_value("adventurer_id").split(" - ")[-1]
    adventurer_out = asyncio.run(_get_adventurer("goerli", value))
    update_gold(value)
    update_beast(adventurer_out[26])
    update_health(value)
    update_equipped_items(adventurer_out)
    update_stats(adventurer_out)
    dpg.delete_item("get_adventurer_load")
    dpg.delete_item("loader")


def new_adventurer(sender, app_data, user_data):
    dpg.add_text(
        "Minting Adventurer",
        tag="mint_adventurer_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    config = Config(nile_network="goerli")
    starting_weapon = dpg.get_value("starting_weapon")
    starting_weapon_id = [
        k for k, v in ITEMS.items() if v == starting_weapon.replace(" ", "")
    ][0]

    race = dpg.get_value("race")
    race_id = [k for k, v in RACES.items() if v == race][0]
    home_realm_id = dpg.get_value("home_realm")
    name = dpg.get_value("name")

    order = dpg.get_value("order")
    order_id = [k for k, v in ORDERS.items() if v == order][0]
    command = [
        "nile",
        "loot",
        "new",
        "--item",
        str(starting_weapon_id),
        "--race",
        str(race_id),
        "--home_realm",
        home_realm_id,
        "--name",
        name,
        "--order",
        str(order_id),
        "--image_hash_1",
        "1",
        "--image_hash_2",
        "1",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    out = asyncio.run(
        wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_Adventurer",
            abi="artifacts/abis/Adventurer.json",
            function="balance_of",
            arguments=[config.USER_ADDRESS],
        )
    )

    out = out.split(" ")

    item = asyncio.run(
        wrapped_proxy_call(
            network=config.nile_network,
            contract_alias="proxy_Adventurer",
            abi="artifacts/abis/Adventurer.json",
            function="token_of_owner_by_index",
            arguments=[config.USER_ADDRESS, *uint(out[-1])],
        )
    )

    id = item.split(" ")
    asyncio.run(update_adventurer_list())
    update_gold(id[-1])
    update_health(id[-1])
    dpg.delete_item("mint_adventurer_load")
    dpg.delete_item("loader")


def explore(sender, app_data, user_data):
    dpg.add_text("Exploring", tag="explore_load", pos=[700, 50], parent="adventurers")
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("adventurer_id").split(" - ")[-1]
    command = [
        "nile",
        "loot",
        "explore",
        "--adventurer_token_id",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(adventurer)
    update_health(adventurer)
    adventurer_out = asyncio.run(_get_adventurer("goerli", adventurer))
    update_beast(adventurer_out[26])
    dpg.delete_item("explore_load")
    dpg.delete_item("loader")


def attack_beast(sender, app_data, user_data):
    dpg.add_text(
        "Attacking Beast", tag="attack_load", pos=[700, 50], parent="adventurers"
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("adventurer_id").split(" - ")[-1]
    command = [
        "nile",
        "loot",
        "attack",
        "--adventurer_token_id",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(adventurer)
    update_health(adventurer)
    dpg.delete_item("attack_load")
    dpg.delete_item("loader")


def flee(sender, app_data, user_data):
    dpg.add_text(
        "Fleeing from beast", tag="flee_load", pos=[700, 50], parent="adventurers"
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("adventurer_id").split(" - ")[-1]
    command = [
        "nile",
        "loot",
        "flee",
        "--adventurer_token_id",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    adventurer_out = asyncio.run(_get_adventurer("goerli", adventurer))
    update_health(adventurer)
    update_beast(adventurer_out[26])
    dpg.delete_item("flee_load")
    dpg.delete_item("loader")


def equip_item(sender, app_data, user_data):
    dpg.add_text(
        "Equipping Item", tag="equip_load", pos=[700, 50], parent="adventurers"
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("equip_adventurer_id").split(" - ")[-1]
    item = dpg.get_value("equip_loot_token_id")
    command = [
        "nile",
        "loot",
        "equip",
        "--adventurer_token_id",
        adventurer,
        "--loot_token_id",
        item,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    adventurer_out = asyncio.run(_get_adventurer("goerli", adventurer))
    update_stats(adventurer_out)
    dpg.delete_item("equip_load")
    dpg.delete_item("loader")


def unequip_item(sender, app_data, user_data):
    dpg.add_text(
        "Unequipping Item", tag="unequip_load", pos=[700, 50], parent="adventurers"
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("unequip_adventurer_id").split(" - ")[-1]
    item = dpg.get_value("unequip_loot_token_id")
    command = [
        "nile",
        "loot",
        "unequip",
        "--adventurer_token_id",
        adventurer,
        "--loot_token_id",
        item,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    adventurer_out = asyncio.run(_get_adventurer("goerli", adventurer))
    update_stats(adventurer_out)
    dpg.delete_item("unequip_load")
    dpg.delete_item("loader")


def purchase_health(sender, app_data, user_data):
    dpg.add_text(
        "Purchasing Health",
        tag="purchase_health_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("potions_adventurer_id").split(" - ")[-1]
    number = dpg.get_value("potion_number")
    command = [
        "nile",
        "loot",
        "health",
        "--adventurer_token_id",
        adventurer,
        "--number",
        str(number),
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(adventurer)
    update_health(adventurer)
    dpg.delete_item("purchase_health_load")
    dpg.delete_item("loader")


def mint_daily_items(sender, app_data, user_data):
    dpg.add_text(
        "Minting daily items",
        tag="mint_items_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    command = [
        "nile",
        "loot",
        "mint-daily-items",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_items()
    dpg.delete_item("mint_items_load")
    dpg.delete_item("loader")


async def get_market_items():
    config = Config(nile_network="goerli")

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

    print_items = []
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

        print_items.append(out)
        items.append(f"{config.LOOT_ITEMS[int(out[1]) - 1]} - {out[-2]}")
    print_loot_and_bid(print_items)
    return items


def update_items():
    items = asyncio.run(get_market_items())
    dpg.configure_item("loot_token_id", items=items)
    dpg.configure_item("bid_loot_id", items=items)
    dpg.configure_item("equip_loot_id", items=items)
    dpg.configure_item("unequip_loot_id", items=items)


def get_item_market():
    loot_token_id = dpg.get_value("item_id")
    command = ["nile", "loot", "market", "--loot_token_id", loot_token_id]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def bid_on_item(sender, app_data, user_data):
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    loot_token_id = dpg.get_value(tag="loot_token_id")
    adventurer_id = dpg.get_value(tag="bid_adventurer_id").split(" - ")[-1]
    price = dpg.get_value("bid_price")
    command = [
        "nile",
        "loot",
        "bid",
        "--loot_token_id",
        loot_token_id,
        "--adventurer_token_id",
        adventurer_id,
        "--price",
        price,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(adventurer_id)
    dpg.delete_item("loader")


def upgrade_stat(sender, app_data, user_data):
    dpg.add_text(
        "Upgrading stat",
        tag="upgrade_stat_load",
        pos=[300, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value(tag="upgrade_adventurer_id").split(" - ")[-1]
    stat = dpg.get_value(tag="stat_id")
    stat_id = [k for k, v in STATS.items() if v == stat][0]
    command = [
        "nile",
        "loot",
        "upgrade",
        "--adventurer_token_id",
        adventurer,
        "--stat_id",
        stat_id,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    dpg.delete_item("upgrade_stat_load")
    dpg.delete_item("loader")


def get_king():
    command = [
        "nile",
        "loot",
        "get-king",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    return out


def become_king(sender, app_data, user_data):
    dpg.add_text(
        "Becoming king",
        tag="become_king_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("king_adventurer_id").split(" - ")[-1]
    command = [
        "nile",
        "loot",
        "become-king",
        "--adventurer_token_id",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_king()
    dpg.delete_item("become_king_load")
    dpg.delete_item("loader")


def pay_king_tribute(sender, app_data, user_data):
    dpg.add_text(
        "Paying the king",
        tag="paying_king_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    command = [
        "nile",
        "loot",
        "pay_king_tribute",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    dpg.delete_item("paying_king_load")
    dpg.delete_item("loader")


def update_gold(adventurer_token_id):
    command = ["nile", "loot", "balance", "--adventurer_token_id", adventurer_token_id]
    out = subprocess.check_output(command).strip().decode("utf-8")
    out = out.split(" ")
    out = out[-1].split("\n")
    print(f"💰 Gold balance is now {out[-1]}")
    dpg.set_value("gold", out[-1])
    king_out = get_king()
    king_out = king_out.split(" ")
    king_out = king_out[-3].split("\n")
    if int(king_out[-1]) == int(adventurer_token_id):
        dpg.set_value("your_gold", "You are the king!")
        dpg.configure_item("your_gold", color=[0, 128, 0])
    elif out[-1] > king_out[-1]:
        dpg.set_value("your_gold", "You have enough gold to be king!")
        dpg.configure_item("your_gold", color=[0, 128, 0])
    else:
        dpg.set_value("your_gold", "You don't have enough gold to be king.")
        dpg.configure_item("your_gold", color=[178, 34, 34])


def update_king():
    command = [
        "nile",
        "loot",
        "get-king",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    out = out.split(" ")
    king_out = out[-3].split("\n")
    gold_command = ["nile", "loot", "balance", "--adventurer_token_id", king_out[-1]]
    gold_out = subprocess.check_output(gold_command).strip().decode("utf-8")
    gold_out = gold_out.split(" ")
    gold_out = gold_out[-1].split("\n")
    reign_time = datetime.datetime.fromtimestamp(int(out[-1]))
    adventurer_out = asyncio.run(_get_adventurer("goerli", king_out[-1]))
    if adventurer_out[3].startswith("0x"):
        adventurer_out = felt_to_str(int(adventurer_out[3], 16))
    else:
        adventurer_out = felt_to_str(int(adventurer_out[3]))
    print(f"👑 King is {adventurer_out} - {king_out[-1]}")
    print(f"⛳️ Reign started at {reign_time}")
    print(f"💰 King's gold balance is now {gold_out[-1]}")
    dpg.set_value("king_adventurer", king_out[-1])
    dpg.set_value("kings_reign", reign_time)
    dpg.set_value("kings_gold", gold_out[-1])


def update_beast(beast_token_id):
    if beast_token_id != "0":
        beast_out = asyncio.run(_get_beast(beast_token_id, "goerli"))
        beast = BEASTS[str(int(beast_out[0]))]
        dpg.set_value("beast", beast)
    else:
        dpg.set_value("beast", "-")


def update_health(adventurer_token_id):
    adventurer_out = asyncio.run(_get_adventurer("goerli", adventurer_token_id))
    print(f"💚 Health is now {adventurer_out[7]}")
    dpg.set_value("health", adventurer_out[7])


def update_equipped_items(adventurer_data):
    config = Config(nile_network="goerli")

    all_items = []

    for i in adventurer_data[17:25]:
        out = asyncio.run(
            wrapped_proxy_call(
                network=config.nile_network,
                contract_alias="proxy_LootMarketArcade",
                abi="artifacts/abis/LootMarketArcade.json",
                function="get_item_by_token_id",
                arguments=[*uint(i)],
            )
        )
        out = out.split(" ")
        out.insert(0, str(int(i)))
        if int(out[1]) == 0:
            all_items.append("Nothing")
        else:
            all_items.append(config.LOOT_ITEMS[int(out[1]) - 1])

    dpg.set_value("weapon", all_items[0])
    dpg.set_value("chest", all_items[1])
    dpg.set_value("head", all_items[2])
    dpg.set_value("waist", all_items[3])
    dpg.set_value("feet", all_items[4])
    dpg.set_value("hands", all_items[5])
    dpg.set_value("neck", all_items[6])
    dpg.set_value("ring", all_items[7])


def update_stats(adventurer_data):
    dpg.set_value("strength", adventurer_data[9])
    dpg.set_value("dexterity", adventurer_data[10])
    dpg.set_value("vitality", adventurer_data[11])
    dpg.set_value("intelligence", adventurer_data[12])
    dpg.set_value("wisdom", adventurer_data[13])
    dpg.set_value("luck", adventurer_data[15])


if __name__ == "__main__":
    dpg.create_context()
    dpg.create_viewport(title="Realms GUI", width=1000, height=800)
    dpg.setup_dearpygui()
    print("Getting adventurers...")
    adventurers = asyncio.run(get_adventurers())
    items = asyncio.run(get_market_items())

    with dpg.window(tag="adventurers", label="Adventurers", width=1000, height=800):
        print("Adventurers GUI running ...")
        with dpg.group(horizontal=True):
            with dpg.group():
                dpg.add_text("Create Adventurer")
                dpg.add_combo(
                    label="Starting Weapon",
                    tag="starting_weapon",
                    items=(["Book", "Wand", "Club", "Short Sword"]),
                    width=100,
                )
                dpg.add_combo(
                    label="Race",
                    tag="race",
                    items=(
                        [
                            "Elf",
                            "Fox",
                            "Giant",
                            "Human",
                            "Orc",
                            "Demon",
                            "Goblin",
                            "Fish",
                            "Cat",
                            "Frog",
                        ]
                    ),
                    width=100,
                )
                dpg.add_input_text(
                    label="Home Realm ID",
                    tag="home_realm",
                    decimal=True,
                    hint="1 - 8000",
                    width=100,
                )
                dpg.add_input_text(
                    label="Name",
                    tag="name",
                    width=100,
                )
                dpg.add_combo(
                    label="Order",
                    tag="order",
                    items=(
                        [
                            "Power",
                            "Giants",
                            "Titans",
                            "Skill",
                            "Perfection",
                            "Brilliance",
                            "Enlightenment",
                            "Protection",
                            "Twins",
                            "Reflection",
                            "Detection",
                            "Fox",
                            "Vitriol",
                            "Fury",
                            "Rage",
                            "Anger",
                        ]
                    ),
                    width=100,
                )
                dpg.add_button(label="Mint Adventurer", callback=new_adventurer)
            # Equipped items display
            dpg.add_spacer(width=20)
            with dpg.group():
                dpg.add_text("Equipped Items")
                with dpg.group(horizontal=True):
                    dpg.add_text("Weapon - ")
                    dpg.add_text(tag="weapon", default_value="Nothing")
                with dpg.group(horizontal=True):
                    dpg.add_text("Chest - ")
                    dpg.add_text(tag="chest", default_value="Nothing")
                with dpg.group(horizontal=True):
                    dpg.add_text("Head - ")
                    dpg.add_text(tag="head", default_value="Nothing")
                with dpg.group(horizontal=True):
                    dpg.add_text("Waist - ")
                    dpg.add_text(tag="waist", default_value="Nothing")
                with dpg.group(horizontal=True):
                    dpg.add_text("Feet - ")
                    dpg.add_text(tag="feet", default_value="Nothing")
                with dpg.group(horizontal=True):
                    dpg.add_text("Hands - ")
                    dpg.add_text(tag="hands", default_value="Nothing")
                with dpg.group(horizontal=True):
                    dpg.add_text("Neck - ")
                    dpg.add_text(tag="neck", default_value="Nothing")
                with dpg.group(horizontal=True):
                    dpg.add_text("Ring - ")
                    dpg.add_text(tag="ring", default_value="Nothing")
            # Stats display
            dpg.add_spacer(width=20)
            with dpg.group():
                dpg.add_text("Adventurer Stats")
                with dpg.group(horizontal=True):
                    dpg.add_text("Strength - ")
                    dpg.add_text(tag="strength", default_value="0")
                with dpg.group(horizontal=True):
                    dpg.add_text("Dexterity - ")
                    dpg.add_text(tag="dexterity", default_value="0")
                with dpg.group(horizontal=True):
                    dpg.add_text("Vitality - ")
                    dpg.add_text(tag="vitality", default_value="0")
                with dpg.group(horizontal=True):
                    dpg.add_text("Intelligence - ")
                    dpg.add_text(tag="intelligence", default_value="0")
                with dpg.group(horizontal=True):
                    dpg.add_text("Wisdom - ")
                    dpg.add_text(tag="wisdom", default_value="0")
                with dpg.group(horizontal=True):
                    dpg.add_text("Luck - ")
                    dpg.add_text(tag="luck", default_value="0")
        dpg.add_spacer(height=4)
        dpg.add_separator()
        dpg.add_spacer(height=4)
        with dpg.group(horizontal=True):
            with dpg.group():
                dpg.add_text("Play")
                dpg.add_combo(
                    label="Adventurer ID",
                    tag="adventurer_id",
                    items=adventurers,
                    width=100,
                )
                with dpg.group(horizontal=True):
                    dpg.add_button(label="Explore", callback=explore)
                    dpg.add_button(label="Attack Beast", callback=attack_beast)
                    dpg.add_button(label="Flee from Beast", callback=flee)
                    dpg.add_button(
                        label="Get Adventurer",
                        callback=get_adventurer,
                    )
            with dpg.group():
                dpg.add_text("Health")
                dpg.add_text(tag="health", default_value="-", color=[0, 128, 0])
            with dpg.group():
                dpg.add_text("Gold")
                dpg.add_text(tag="gold", default_value="-", color=[255, 215, 0])
            with dpg.group():
                dpg.add_text("Beast")
                dpg.add_text(tag="beast", default_value="-", color=[178, 34, 34])
        dpg.add_spacer(height=4)
        dpg.add_separator()
        dpg.add_spacer(height=4)
        dpg.add_text("Items")
        with dpg.group(horizontal=True):
            dpg.add_button(label="Mint Daily Loot Items", callback=mint_daily_items)
            dpg.add_button(label="Get Market Items", callback=get_items)
            with dpg.group():
                dpg.add_text("By Token")
                dpg.add_combo(
                    label="Item Id",
                    tag="item_id",
                    items=(items),
                    width=100,
                )
                dpg.add_button(label="Get Item", callback=get_item_market)
        dpg.add_spacer(height=4)
        with dpg.group(horizontal=True):
            with dpg.group():
                dpg.add_text("Bid On Item")
                dpg.add_combo(
                    label="Adventurer ID",
                    tag="bid_adventurer_id",
                    items=adventurers,
                    width=100,
                )
                dpg.add_combo(
                    label="Loot Token ID",
                    tag="bid_loot_id",
                    items=(items),
                    width=100,
                )
                dpg.add_input_text(
                    label="Price",
                    tag="bid_price",
                    decimal=True,
                    hint="Min 3",
                    width=100,
                )
                dpg.add_button(label="Bid", callback=bid_on_item)
            with dpg.group():
                dpg.add_text("Equip Item")
                dpg.add_combo(
                    label="Adventurer ID",
                    tag="equip_adventurer_id",
                    items=adventurers,
                    width=100,
                )
                dpg.add_combo(
                    label="Loot Token ID",
                    tag="equip_loot_id",
                    items=(items),
                    width=100,
                )
                dpg.add_button(label="Equip", callback=equip_item)
            with dpg.group():
                dpg.add_text("Unequip Item")
                dpg.add_combo(
                    label="Adventurer ID",
                    tag="unequip_adventurer_id",
                    items=adventurers,
                    width=100,
                )
                dpg.add_combo(
                    label="Loot Token ID",
                    tag="unequip_loot_id",
                    items=(items),
                    width=100,
                )
                dpg.add_button(label="Unequip", callback=unequip_item)
        dpg.add_spacer(height=4)
        dpg.add_separator()
        dpg.add_spacer(height=4)
        with dpg.group(horizontal=True):
            with dpg.group():
                dpg.add_text("Upgrade Stat")
                dpg.add_combo(
                    label="Adventurer ID",
                    tag="upgrade_adventurer_id",
                    items=adventurers,
                    width=100,
                )
                dpg.add_combo(
                    label="Stat",
                    tag="stat",
                    items=[
                        "Strength",
                        "Dexterity",
                        "Vitality",
                        "Intelligence",
                        "Wisdom",
                    ],
                    width=100,
                )
                dpg.add_button(label="Upgrade", callback=upgrade_stat)
            with dpg.group():
                dpg.add_text("Purchase Health")
                dpg.add_combo(
                    label="Adventurer ID",
                    tag="potions_adventurer_id",
                    items=adventurers,
                    width=100,
                )
                dpg.add_slider_int(
                    label="Health Potions",
                    tag="potion_number",
                    min_value=1,
                    max_value=10,
                    width=100,
                )
                dpg.add_button(label="Purchase Health", callback=purchase_health)
        dpg.add_spacer(height=4)
        dpg.add_separator()
        dpg.add_spacer(height=4)
        dpg.add_text("Kings")
        dpg.add_spacer(height=4)
        with dpg.group(horizontal=True):
            with dpg.group():
                dpg.add_text("Become King")
                dpg.add_combo(
                    label="Adventurer ID",
                    tag="king_adventurer_id",
                    items=adventurers,
                    width=100,
                )
                dpg.add_button(label="Become King", callback=become_king)
            with dpg.group():
                dpg.add_button(label="Pay King Tribue", callback=pay_king_tribute)
            with dpg.group():
                dpg.add_text("King")
                with dpg.group(horizontal=True):
                    with dpg.group():
                        dpg.add_text("Adventurer")
                        dpg.add_text(
                            tag="king_adventurer",
                            default_value="-",
                            color=[205, 127, 50],
                        )
                    with dpg.group():
                        dpg.add_text("Reign Since")
                        dpg.add_text(tag="kings_reign", default_value="-")
                    with dpg.group():
                        dpg.add_text("Gold")
                        dpg.add_text(
                            tag="kings_gold", default_value="-", color=[255, 215, 0]
                        )
                    with dpg.group():
                        dpg.add_text(
                            "You don't have enough gold to be king.",
                            tag="your_gold",
                            color=[178, 34, 34],
                        )
        update_king()

    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()
