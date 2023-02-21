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
    starting_weapon = dpg.get_value("staring_weapon")
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

if __name__ == "__main__":
    dpg.create_context()
    dpg.create_viewport(title="Realms GUI", width=800, height=600)
    dpg.setup_dearpygui()

    with dpg.window(label="Adventurers", width=800, height=600):
        dpg.add_text("Adventurers")
        dpg.add_input_text(label="Adventurer ID", tag="adventurer_id")
        dpg.add_button(label="Explore", callback=explore)
        dpg.add_same_line()
        dpg.add_button(label="Attack Beast", callback=attack_beast)
        dpg.add_spacing(count=4)
        dpg.add_separator()
        dpg.add_spacing(count=4)
        dpg.add_button(label="Mint Adventurer", callback=new_adventurer)
        dpg.add_button(label="Mint Daily Loot Items", callback=mint_daily_items)

    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()