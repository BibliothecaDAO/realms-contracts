import dearpygui.dearpygui as dpg
import subprocess

def save_callback(sender, app_data, user_data):
  value = dpg.get_value("adventurer_id")
  command = [
      "nile",
      "get_adventurer",
      value
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
        dpg.add_input_text(tag="adventurer_id")
        dpg.add_button(label="Get Adventurer", callback=save_callback)

    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()