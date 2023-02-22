import dearpygui.dearpygui as dpg
import subprocess
from realms_cli.loot.constants import ITEMS, RACES, ORDERS, STATS


def get_adventurer(sender, app_data, user_data):
    value = dpg.get_value("adventurer_id")
    command = ["nile", "loot", "adventurer", "--adventurer_token_id", value]
    # output = []
    # with dpg.window(label="Adventurer Details", width=400, height=300):
    #     # dpg.add_seperator()
    #     dpg.add_text(output)
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    # output.append(out)


def new_adventurer(sender, app_data, user_data):
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
    # with dpg.window(label="Adventurers", width=400, height=300):
    #     # dpg.add_seperator()
    #     dpg.add_text(out)


def explore(sender, app_data, user_data):
    adventurer = dpg.get_value("adventurer_id")
    command = [
        "nile",
        "loot",
        "explore",
        "--adventurer_token_id",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    # with dpg.window(label="Adventurers", width=400, height=300):
    #     # dpg.add_seperator()
    #     dpg.add_text(out)


def attack_beast(sender, app_data, user_data):
    adventurer = dpg.get_value("adventurer_id")
    command = [
        "nile",
        "loot",
        "attack",
        "--adventurer_token_id",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    # with dpg.window(label="Adventurers", width=400, height=300):
    #     # dpg.add_seperator()
    #     dpg.add_text(out)


def flee(sender, app_data, user_data):
    adventurer = dpg.get_value("adventurer_id")
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
    adventurer = dpg.get_value("equip_adventurer_id")
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
    adventurer = dpg.get_value("unequip_adventurer_id")
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
    adventurer = dpg.get_value("potions_adventurer_id")
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
    # with dpg.window(label="Adventurers", width=400, height=300):
    #     # dpg.add_seperator()
    #     dpg.add_text(out)


def mint_daily_items(sender, app_data, user_data):
    command = [
        "nile",
        "loot",
        "mint_daily_items",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    print(out)
    # with dpg.window(label="Adventurers", width=400, height=300):
    #     # dpg.add_seperator()
    #     dpg.add_text(out)


def bid_on_item(sender, app_data, user_data):
    loot_token_id = dpg.get_value(tag="loot_token_id")
    adventurer_id = dpg.get_value(tag="bid_adventurer_id")
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


def upgrade_stat(sender, app_data, user_data):
    adventurer = dpg.get_value(tag="upgrade_adventurer_id")
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


if __name__ == "__main__":
    dpg.create_context()
    dpg.create_viewport(title="Realms GUI", width=1000, height=800)
    dpg.setup_dearpygui()

    with dpg.window(label="Adventurers", width=800, height=800):
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
        dpg.add_text("Play")
        dpg.add_input_text(
            label="Adventurer ID", tag="adventurer_id", decimal=True, width=100
        )
        with dpg.group(horizontal=True):
            dpg.add_button(label="Explore", callback=explore)
            dpg.add_button(label="Attack Beast", callback=attack_beast)
            dpg.add_button(label="Flee from Beast", callback=flee)
            dpg.add_button(label="Get Adventurer", callback=get_adventurer)
        dpg.add_spacer(height=4)
        dpg.add_separator()
        dpg.add_spacer(height=4)
        dpg.add_text("Purchase Health")
        dpg.add_input_text(
            label="Adventurer ID", tag="potions_adventurer_id", decimal=True, width=100
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
        dpg.add_text("Items")
        dpg.add_button(label="Mint Daily Loot Items", callback=mint_daily_items)
        dpg.add_spacer(height=4)
        with dpg.group(horizontal=True):
            with dpg.group():
                dpg.add_text("Bid On Item")
                dpg.add_input_text(
                    label="Loot Token ID", tag="loot_token_id", decimal=True, width=100
                )
                dpg.add_input_text(
                    label="Adventurer ID",
                    tag="bid_adventurer_id",
                    decimal=True,
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
                dpg.add_input_text(
                    label="Adventurer ID",
                    tag="equip_adventurer_id",
                    decimal=True,
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
                dpg.add_input_text(
                    label="Adventurer ID",
                    tag="unequip_adventurer_id",
                    decimal=True,
                    width=100,
                )
                dpg.add_input_text(
                    label="Loot Token ID",
                    tag="unequip_loot_token_id",
                    decimal=True,
                    width=100,
                )
                dpg.add_button(label="Unequip", callback=unequip_item)
        dpg.add_spacer(height=4)
        dpg.add_separator()
        dpg.add_spacer(height=4)
        dpg.add_text("Upgrade Stat")
        dpg.add_input_text(
            label="Adventurer ID", tag="upgrade_adventurer_id", decimal=True, width=100
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

    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()
