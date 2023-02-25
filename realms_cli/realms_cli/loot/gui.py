import asyncio
import dearpygui.dearpygui as dpg
import subprocess
from realms_cli.config import Config
from realms_cli.caller_invoker import wrapped_proxy_call
from realms_cli.loot.constants import ITEMS, RACES, ORDERS, STATS
from realms_cli.utils import uint, felt_to_str
from realms_cli.loot.getters import format_array


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


async def update_adventurer_list(id):
    config = Config(nile_network="goerli")

    global adventurers

    out = await wrapped_proxy_call(
        network=config.nile_network,
        contract_alias="proxy_Adventurer",
        abi="artifacts/abis/Adventurer.json",
        function="get_adventurer_by_id",
        arguments=[*uint(id)],
    )
    out = out.split(" ")
    # needing to add to get rid of weird bytecode
    adventurers.append(
        "".join(felt_to_str(int(out[3]))).replace("\x00", "") + " - " + id[0]
    )
    print(adventurers)


def get_adventurer(sender, app_data, user_dat):
    value = dpg.get_value("adventurer_id").split(" - ")[-1]
    command = ["nile", "loot", "adventurer", "--adventurer_token_id", value]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(value)


def new_adventurer(sender, app_data, user_data):
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
    update_adventurer_list(id[0])
    update_gold(id[0])


def explore(sender, app_data, user_data):
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


def attack_beast(sender, app_data, user_data):
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


def flee(sender, app_data, user_data):
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


def equip_item(sender, app_data, user_data):
    adventurer = dpg.get_value("equip_adventurer_id").split(" - ")[-1]
    item = dpg.get_value("equip_loot_token_id")
    command = [
        "nile",
        "loot",
        "health",
        "--adventurer_token_id",
        adventurer,
        "--loot_token_id",
        item,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def unequip_item(sender, app_data, user_data):
    adventurer = dpg.get_value("unequip_adventurer_id").split(" - ")[-1]
    item = dpg.get_value("unequip_loot_token_id")
    command = [
        "nile",
        "loot",
        "health",
        "--adventurer_token_id",
        adventurer,
        "--loot_token_id",
        item,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def purchase_health(sender, app_data, user_data):
    adventurer = dpg.get_value("potions_adventurer_id").split(" - ")[-1]
    number = dpg.get_value("potion_number")
    command = [
        "nile",
        "loot",
        "health",
        "--adventurer_token_id",
        adventurer,
        "--number",
        number,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    update_gold(adventurer)


def mint_daily_items(sender, app_data, user_data):
    command = [
        "nile",
        "loot",
        "mint-daily-items",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def get_market_items(sender, app_data, user_data):
    command = [
        "nile",
        "loot",
        "all-market",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def bid_on_item(sender, app_data, user_data):
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


def upgrade_stat(sender, app_data, user_data):
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


def become_king(sender, app_data, user_data):
    adventurer = dpg.get_value("potions_adventurer_id").split(" - ")[-1]
    command = [
        "nile",
        "loot",
        "become_king",
        "--adventurer_token_id",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def pay_king_tribute(sender, app_data, user_data):
    command = [
        "nile",
        "loot",
        "pay_king_tribute",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)


def update_gold(adventurer_token_id):
    command = ["nile", "loot", "balance", "--adventurer_token_id", adventurer_token_id]
    out = subprocess.check_output(command).strip().decode("utf-8")
    out = out.split(" ")
    out = out[-1].split("\n")
    print(out[-1])
    dpg.set_value("gold", out[-1])


if __name__ == "__main__":
    dpg.create_context()
    dpg.create_viewport(title="Realms GUI", width=800, height=800)
    dpg.setup_dearpygui()
    print("Getting adventurers...")
    global adventurers
    adventurers = asyncio.run(get_adventurers())

    with dpg.window(tag="Adventurers", label="Adventurers", width=800, height=800):
        print("Adventurers GUI running ...")
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
                dpg.add_text("Gold")
                dpg.add_text(tag="gold", default_value="0", color=[255, 215, 0])
        dpg.add_spacer(height=4)
        dpg.add_separator()
        dpg.add_spacer(height=4)
        dpg.add_text("Items")
        with dpg.group(horizontal=True):
            dpg.add_button(label="Mint Daily Loot Items", callback=mint_daily_items)
            dpg.add_button(label="Get Market Items", callback=get_market_items)
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
                dpg.add_input_text(
                    label="Loot Token ID", tag="loot_token_id", decimal=True, width=100
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
                dpg.add_input_text(
                    label="Loot Token ID",
                    tag="equip_loot_token_id",
                    decimal=True,
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
                dpg.add_input_text(
                    label="Loot Token ID",
                    tag="unequip_loot_token_id",
                    decimal=True,
                    width=100,
                )
                dpg.add_button(label="Unequip", callback=unequip_item)
        with dpg.group(horizontal=True):
            with dpg.group():
                dpg.add_spacer(height=4)
                dpg.add_separator()
                dpg.add_spacer(height=4)
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
                        "Charisma",
                        "Luck",
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

    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()
