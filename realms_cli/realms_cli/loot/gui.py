import dearpygui.dearpygui as dpg
import subprocess

def get_adventurer(sender, app_data, user_data):
  value = dpg.get_value("adventurer_id")
  command = [
      "nile",
      "loot",
      "adventurer",
      value
  ]
  out = subprocess.check_output(command).strip().decode("utf-8")
  with dpg.window(label="Adventurers", width=400, height=300):
  # dpg.add_seperator()
    dpg.add_text(out)

def new_adventurer(sender, app_data, user_data):
    starting_weapon = dpg.get_value("starting_weapon")
    race = dpg.get_value("race")
    home_realm = dpg.get_value("home_realm")
    name = dpg.get_value("name")
    order = dpg.get_value("order")
    command = [
        "nile",
        "loot",
        "new",
        starting_weapon,
        race,
        home_realm,
        name,
        order,
        1,
        1
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    with dpg.window(label="Adventurers", width=400, height=300):
    # dpg.add_seperator()
        dpg.add_text(out)

def explore(sender, app_data, user_data):
    adventurer = dpg.get_value("adventurer_id")
    command = [
        "nile",
        "loot",
        "explore",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    with dpg.window(label="Adventurers", width=400, height=300):
    # dpg.add_seperator()
        dpg.add_text(out)

def attack_beast(sender, app_data, user_data):
    adventurer = dpg.get_value("adventurer_id")
    command = [
        "nile",
        "loot",
        "attack",
        adventurer,
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    with dpg.window(label="Adventurers", width=400, height=300):
    # dpg.add_seperator()
        dpg.add_text(out)

def purchase_health(sender, app_data, user_data):
    adventurer = dpg.get_value("adventurer_id")
    number = dpg.get_value("potion_number")
    command = [
        "nile",
        "loot",
        "health",
        adventurer,
        number
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    with dpg.window(label="Adventurers", width=400, height=300):
    # dpg.add_seperator()
        dpg.add_text(out)

def mint_daily_items(sender, app_data, user_data):
    command = [
        "nile",
        "loot",
        "mint_daily_items",
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")
    with dpg.window(label="Adventurers", width=400, height=300):
    # dpg.add_seperator()
        dpg.add_text(out)

def bid_on_item(sender, app_data, user_data):
    loot_token_id = dpg.get_value(tag="loot_token_id")
    adventurer = dpg.get_value(tag="bid_adventurer_id")
    price = dpg.get_value("bid_price")
    command = [
        "nile",
        "loot",
        "bid",
        loot_token_id,
        adventurer,
        price
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")

def upgrade_stat(sender, app_data, user_data):
    adventurer = dpg.get_value(tag="upgrade_adventurer_id")
    stat_id = dpg.get_value(tag="stat_id")
    command = [
        "nile",
        "loot",
        "upgrade",
        adventurer,
        stat_id
    ]
    out = subprocess.check_output(command).strip().decode("utf-8")


if __name__ == "__main__":
    dpg.create_context()
    dpg.create_viewport(title="Realms GUI", width=1000, height=800)
    dpg.setup_dearpygui()

    with dpg.window(label="Adventurers", width=800, height=800):
        dpg.add_text("Play")
        dpg.add_input_text(label="Adventurer ID", tag="adventurer_id")
        dpg.add_button(label="Explore", callback=explore)
        dpg.add_same_line()
        dpg.add_button(label="Attack Beast", callback=attack_beast)
        dpg.add_spacing(count=4)
        dpg.add_separator()
        dpg.add_spacing(count=4)
        dpg.add_text("Purchase Health")
        dpg.add_input_text(label="Health Potions", tag="potion_number")
        dpg.add_button(label="Purchase Health", callback=purchase_health)
        dpg.add_spacing(count=4)
        dpg.add_separator()
        dpg.add_spacing(count=4)
        dpg.add_text("Create Adventurer")
        dpg.add_input_text(label="Starting Weapon ID", tag="starting_weapon")
        dpg.add_input_text(label="Race", tag="race")
        dpg.add_input_text(label="Home Realm", tag="home_realm")
        dpg.add_input_text(label="Name", tag="name")
        dpg.add_input_text(label="Order", tag="order")
        dpg.add_button(label="Mint Adventurer", callback=new_adventurer)
        dpg.add_spacing(count=4)
        dpg.add_separator()
        dpg.add_spacing(count=4)
        dpg.add_text("Items")
        dpg.add_button(label="Mint Daily Loot Items", callback=mint_daily_items)
        dpg.add_spacing(count=4)
        dpg.add_text("Bid On Item")
        dpg.add_input_text(label="Loot Token ID", tag="loot_token_id")
        dpg.add_input_text(label="Adventurer ID", tag="bid_adventurer_id")
        dpg.add_input_text(label="Price", tag="bid_price")
        dpg.add_button(label="Bid", callback=bid_on_item)
        dpg.add_spacing(count=4)
        dpg.add_separator()
        dpg.add_spacing(count=4)
        dpg.add_text("Upgrade Stat")
        dpg.add_input_text(label="Adventurer ID", tag="upgrade_adventurer_id")
        dpg.add_input_text(label="Stat ID", tag="stat_id")
        dpg.add_button(label="Upgrade", callback=upgrade_stat)


    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()