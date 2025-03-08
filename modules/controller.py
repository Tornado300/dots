from fabric.hyprland import Hyprland
from fabric.widgets.wayland import WaylandWindow as Window
from gi.repository import GLib

import json

class Controller(Window, Hyprland):
    def __init__(self):
        super().__init__(commands_only=True)


    def open(self, module):
        id = json.loads(self.send_command("j/activeworkspace").reply.decode("utf-8"))["id"] # gets the id currently activeworkspace from hyprland

        if id > 10 and id < 21:
            GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch0.close_notch()"')
            GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch0.open_notch(\\\"{module}\\\")"')

        elif id > 0 and id < 11:
            GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch1.close_notch()"')
            GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch1.open_notch(\\\"{module}\\\")"')


    def toggle(self, module):
        id = json.loads(self.send_command("j/activeworkspace").reply.decode("utf-8"))["id"] # gets the id currently activeworkspace from hyprland
        self.data = json.load(open("./data.json", "r"))

        if id > 10 and id < 21:
            if self.data["notch_status"] != module:
                GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch0.close_notch()"')
                GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch0.open_notch(\\\"{module}\\\")"')
            else:
                GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch0.close_notch()"')

        elif id > 0 and id < 11:
            if self.data["notch_status"] != module:
                GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch1.close_notch()"')
                GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch1.open_notch(\\\"{module}\\\")"')
            else:
                GLib.spawn_command_line_async(f'fabric-cli exec main-ui "notch1.close_notch()"')
