import asyncio
import datetime
import dearpygui.dearpygui as dpg
import subprocess
import argparse
from realms_cli.config import Config
from realms_cli.caller_invoker import wrapped_proxy_call
from realms_cli.loot.constants import ITEMS, RACES, ORDERS, STATS, BEASTS
from realms_cli.utils import uint, felt_to_str
from realms_cli.loot.getters import (
    format_array,
    _get_beast,
    _get_adventurer,
    print_loot_and_bid,
    print_loot,
    _get_gold_balance,
)


async def get_adventurers(config):
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


def get_items(config):
    asyncio.run(get_market_items(config))


async def update_adventurer_list(config):
    adventurers = await get_adventurers(config)
    dpg.configure_item("adventurer_id", items=adventurers)
    dpg.configure_item("bid_adventurer_id", items=adventurers)
    dpg.configure_item("equip_adventurer_id", items=adventurers)
    dpg.configure_item("unequip_adventurer_id", items=adventurers)
    dpg.configure_item("upgrade_adventurer_id", items=adventurers)
    dpg.configure_item("potions_adventurer_id", items=adventurers)


def get_adventurer(config):
    dpg.add_text(
        "Getting adventurer",
        tag="get_adventurer_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    value = dpg.get_value("adventurer_id").split(" - ")[-1]
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, value))
    update_gold(config, value)
    update_beast(config, adventurer_out[26])
    update_health(config, value)
    update_equipped_items(config, adventurer_out)
    update_stats(config, adventurer_out)
    update_level_xp(config, adventurer_out)
    dpg.delete_item("get_adventurer_load")
    dpg.delete_item("loader")


def new_adventurer(config):
    dpg.add_text(
        "Minting Adventurer",
        tag="mint_adventurer_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
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
    asyncio.run(update_adventurer_list(config))
    dpg.delete_item("mint_adventurer_load")
    dpg.delete_item("loader")


def explore(config):
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
    update_gold(config, adventurer)
    update_health(config, adventurer)
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, adventurer))
    update_beast(config, adventurer_out[26])
    update_level_xp(config, adventurer_out)
    dpg.delete_item("explore_load")
    dpg.delete_item("loader")


def attack_beast(config):
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
    update_gold(config, adventurer)
    update_health(config, adventurer)
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, adventurer))
    update_beast(config, adventurer_out[26])
    update_level_xp(config, adventurer_out)
    dpg.delete_item("attack_load")
    dpg.delete_item("loader")


def flee(config):
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
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, adventurer))
    update_health(config, adventurer)
    update_beast(config, adventurer_out[26])
    dpg.delete_item("flee_load")
    dpg.delete_item("loader")


def equip_item(config):
    dpg.add_text(
        "Equipping Item", tag="equip_load", pos=[700, 50], parent="adventurers"
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("equip_adventurer_id").split(" - ")[-1]
    item = dpg.get_value("equip_loot_token_id").split(" - ")[-1]
    loot_ids = dpg.get_value("equip_multi_loot_ids")
    # Need to add logic that checks if equipped and unequips
    if loot_ids != "":
        command = [
            "nile",
            "loot",
            "equip",
            "--loot_token_id",
            loot_ids,
            "--adventurer_token_id",
            adventurer,
        ]
    else:
        command = [
            "nile",
            "loot",
            "equip",
            "--loot_token_id",
            item,
            "--adventurer_token_id",
            adventurer,
        ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, adventurer))
    update_equipped_items(config, adventurer_out)
    dpg.delete_item("equip_load")
    dpg.delete_item("loader")


def unequip_item(config):
    dpg.add_text(
        "Unequipping Item", tag="unequip_load", pos=[700, 50], parent="adventurers"
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("unequip_adventurer_id").split(" - ")[-1]
    item = dpg.get_value("unequip_loot_token_id").split(" - ")[-1]
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
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, adventurer))
    update_equipped_items(config, adventurer_out)
    dpg.delete_item("unequip_load")
    dpg.delete_item("loader")


def purchase_health(config):
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
    update_gold(config, adventurer)
    update_health(config, adventurer)
    dpg.delete_item("purchase_health_load")
    dpg.delete_item("loader")


def mint_daily_items(config):
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
    update_market_items(config)
    dpg.delete_item("mint_items_load")
    dpg.delete_item("loader")


async def get_market_items(config):
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

        print_items.append(out)
        items.append(f"{config.LOOT_ITEMS[int(out[1]) - 1]} - {out[0]}")
    print_loot_and_bid(print_items)
    return items


async def get_owned_items(config):
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

    print_items = []

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
        print_items.append(out)
        all_items.append(f"{config.LOOT_ITEMS[int(out[1]) - 1]} - {out[0]}")

    print_loot(print_items)
    return all_items


def update_market_items(config):
    items = asyncio.run(get_market_items(config))
    dpg.configure_item("item_id", items=(items))
    dpg.configure_item("bid_loot_id", items=(items))


def update_owned_items(config):
    items = asyncio.run(get_owned_items(config))
    dpg.configure_item("equip_loot_token_id", items=(items))
    dpg.configure_item("unequip_loot_token_id", items=(items))


def get_item_market():
    loot_token_id = dpg.get_value("item_id").split(" - ")[-1]
    command = ["nile", "loot", "market", "--loot_token_id", loot_token_id]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def bid_on_item(config):
    dpg.add_text(
        "Bidding on item",
        tag="bid_item_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    loot_token_id = dpg.get_value("bid_loot_id").split(" - ")[-1]
    adventurer_id = dpg.get_value("bid_adventurer_id").split(" - ")[-1]
    loot_ids = dpg.get_value("multi_loot_ids")
    price = dpg.get_value("bid_price")
    if loot_ids == "":
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
    else:
        command = [
            "nile",
            "loot",
            "bid",
            "--loot_token_id",
            loot_ids,
            "--adventurer_token_id",
            adventurer_id,
            "--price",
            price,
        ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(config, adventurer_id)
    dpg.delete_item("bid_item_load")
    dpg.delete_item("loader")


def claim_item(config):
    dpg.add_text(
        "Claiming item",
        tag="claim_item_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    loot_token_id = dpg.get_value("bid_loot_id").split(" - ")[-1]
    adventurer_id = dpg.get_value("bid_adventurer_id").split(" - ")[-1]
    loot_ids = dpg.get_value("multi_loot_ids")
    if loot_ids != "":
        command = [
            "nile",
            "loot",
            "claim",
            "--loot_token_id",
            loot_ids,
            "--adventurer_token_id",
            adventurer_id,
        ]
    else:
        command = [
            "nile",
            "loot",
            "claim",
            "--loot_token_id",
            loot_token_id,
            "--adventurer_token_id",
            adventurer_id,
        ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(config, adventurer_id)
    update_owned_items(config)
    dpg.delete_item("claim_item_load")
    dpg.delete_item("loader")


def claim_equip_item(config):
    dpg.add_text(
        "Claiming and equipping item",
        tag="claim_equip_item_load",
        pos=[700, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    loot_token_id = dpg.get_value("bid_loot_id").split(" - ")[-1]
    adventurer_id = dpg.get_value("bid_adventurer_id").split(" - ")[-1]
    loot_ids = dpg.get_value("multi_loot_ids")
    if loot_ids != "":
        command = [
            "nile",
            "loot",
            "claim_equip",
            "--loot_token_id",
            loot_ids,
            "--adventurer_token_id",
            adventurer_id,
        ]
    else:
        command = [
            "nile",
            "loot",
            "claim_equip",
            "--loot_token_id",
            loot_token_id,
            "--adventurer_token_id",
            adventurer_id,
        ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, adventurer_id))
    update_equipped_items(config, adventurer_out)
    update_gold(config, adventurer_id)
    update_owned_items(config)
    dpg.delete_item("claim_equip_item_load")
    dpg.delete_item("loader")


def upgrade_stat(config):
    dpg.add_text(
        "Upgrading stat",
        tag="upgrade_stat_load",
        pos=[300, 50],
        parent="adventurers",
    )
    dpg.add_loading_indicator(tag="loader", parent="adventurers", pos=[850, 50])
    adventurer = dpg.get_value("upgrade_adventurer_id").split(" - ")[-1]
    stat = dpg.get_value("stat")
    stat_id = [k for k, v in STATS.items() if v == stat][0]
    command = [
        "nile",
        "loot",
        "upgrade",
        "--adventurer_token_id",
        adventurer,
        "--stat_id",
        str(stat_id),
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    adventurer_out = asyncio.run(_get_adventurer(config.nile_network, adventurer))
    update_stats(config, adventurer_out)
    dpg.delete_item("upgrade_stat_load")
    dpg.delete_item("loader")


def update_beast(config, beast_token_id):
    if beast_token_id != "0":
        beast_out = asyncio.run(_get_beast(beast_token_id, config.nile_network))
        beast = BEASTS[str(int(beast_out[0]))]
        dpg.set_value("beast", beast)
    else:
        dpg.set_value("beast", "-")


def update_health(config, adventurer_token_id):
    adventurer_out = asyncio.run(
        _get_adventurer(config.nile_network, adventurer_token_id)
    )
    print(f"💚 Health is now {adventurer_out[7]}")
    dpg.set_value("health", adventurer_out[7])


def update_level_xp(adventurer_data):
    dpg.set_value("level", adventurer_data[8])
    dpg.set_value("xp", adventurer_data[16])


def update_equipped_items(config, adventurer_data):
    config = Config(config.nile_network)

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
    parser = argparse.ArgumentParser(
        description="Gui accepts a network param to switch between"
    )
    parser.add_argument("network", help="Network of Starknet to interact the gui with.")
    args = parser.parse_args()
    print(f"Running on {args.network}")
    config = Config(nile_network=args.network)
    dpg.create_context()
    dpg.create_viewport(title="Realms GUI", width=1000, height=1000)
    dpg.setup_dearpygui()
    print("Getting adventurers...")
    adventurers = asyncio.run(get_adventurers(config))
    market_items = asyncio.run(get_market_items(config))
    owned_items = asyncio.run(get_owned_items(config))

    with dpg.window(tag="adventurers", label="Adventurers", width=1000, height=1000):
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
                dpg.add_button(label="Mint Adventurer", callback=new_adventurer(config))
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
            with dpg.group():
                dpg.add_text("Progression")
                with dpg.group(horizontal=True):
                    with dpg.group(horizontal=True):
                        dpg.add_text("Level")
                        dpg.add_text(tag="level", default_value="-")
                    with dpg.group(horizontal=True):
                        dpg.add_text("XP")
                        dpg.add_text(tag="xp", default_value="-")
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
                    items=(market_items),
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
                    items=(market_items),
                    width=100,
                )
                dpg.add_input_text(
                    label="Loot IDs",
                    tag="multi_loot_ids",
                    hint="For multiple add ID,ID...",
                    width=200,
                )
                dpg.add_input_text(
                    label="Price",
                    tag="bid_price",
                    hint="Min 3 - For multi 3,3...",
                    width=200,
                )
                with dpg.group(horizontal=True):
                    dpg.add_button(label="Bid", callback=bid_on_item)
                    dpg.add_button(label="Claim", callback=claim_item)
                    dpg.add_button(label="Claim and Equip", callback=claim_equip_item)
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
                    tag="equip_loot_token_id",
                    items=(owned_items),
                    width=100,
                )
                dpg.add_input_text(
                    label="Loot IDs",
                    tag="equip_multi_loot_ids",
                    hint="For multiple add ID,ID...",
                    width=200,
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
                    tag="unequip_loot_token_id",
                    items=(owned_items),
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

    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()
