from fabric.widgets.box import Box
from fabric.widgets.button import Button
from gi.repository import GLib

import json


class Compact(Box):
    def __init__(self):
        with open("./data/data.json", "r+") as file:
            self.data = json.load(file)

        super().__init__(
            name="notch-compact",
            h_expand=True,
            v_expand=True,
            children=[
                Button(
                    name="notch-compact-button",
                    h_expand=True,
                    v_expand=True,
                    label=f"{self.data["username"]}@{self.data["hostname"]}",
                    on_clicked=lambda *_: GLib.spawn_command_line_async("fabric-cli exec main-ui 'controller.open(\"dashboard\")'")
                )
            ]
        )
