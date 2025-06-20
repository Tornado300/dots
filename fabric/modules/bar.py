from fabric.widgets.box import Box
from fabric.widgets.datetime import DateTime
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.wayland import WaylandWindow as Window
from modules.workspaces import Workspaces
from fabric.hyprland.widgets import WorkspaceButton
from gi.repository import GLib
from modules.systemtray import SystemTray
from modules.corners import RoundedAngleEnd
from fabric.hyprland import Hyprland

import json


class Bar(Window):
    def __init__(self, server, monitor_id=None, **kwargs):
        super().__init__(name="bar", monitor=monitor_id, layer="top", anchor="left top right", margin="-4px 0px 0px 0px", exclusivity="auto", visible=True, all_visible=True)
        self.monitor_id = monitor_id

        self.workspace_container = Workspaces(
            workspace_range=[11 - 10 * (self.monitor_id), 20 - 10 * (self.monitor_id)],  # 11-20 for id 0; 1-10 for id 1
            name="workspaces",
            buttons_factory=self.workspace_factory,
            orientation="h",
            spacing=7
        )

        # activate the open workspace on startup
        monitor_raw = json.loads(Hyprland.send_command("j/monitors").reply.decode("utf-8"))
        monitor_data = {}
        for id, monitor in enumerate(monitor_raw):
            monitor_data[id] = monitor
        self.workspace_container.activate_workspace(monitor_data[self.monitor_id]["activeWorkspace"]["id"])

        self.systray = SystemTray(server)

        self.date_time = Box(name="date-time", orientation="v",
                             children=[DateTime(name="date", formatters=["%a / %d.%m.%y"], h_align="center"),
                                       DateTime(name="time", formatters=["%H:%M:%S"], h_align="end")])

        self.left_side = Box(name="bar-left", spacing=4, orientation="h", children=[self.workspace_container])
        self.right_side = Box(name="bar-right", spacing=4, orientation="h", children=[self.systray, self.date_time])

        self.bar_inner = CenterBox(name="bar-inner", orientation="h", h_align="fill", v_align="center",
                                   start_children=Box(children=[self.left_side, RoundedAngleEnd(name="corner-bar-left", style_classes=["corner-bar"], place="topright", height=40, width=120)]),
                                   end_children=Box(children=[RoundedAngleEnd(name="corner-bar-right", style_classes=["corner-bar"], place="topleft", height=40, width=120), self.right_side]))

        self.children = self.bar_inner
        self.hidden = False
        self.show_all()

    def workspace_factory(self, id):
        if id < 0:
            return None
        if id > 20:
            return WorkspaceButton(id=id, label=str(id))
        if (id < 11 and self.monitor_id == 1) or (id > 10 and self.monitor_id == 0):
            label_id = id % 10
            if label_id == 0:
                label_id = 10
            return WorkspaceButton(id=id, label=str(label_id))
        return None

    def search_apps(self):
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.open_notch(\"launcher\")'")

    def power_menu(self):
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.open_notch(\"power\")'")

    def toggle_hidden(self):
        self.hidden = not self.hidden
        if self.hidden:
            self.bar_inner.add_style_class("hidden")
        else:
            self.bar_inner.remove_style_class("hidden")
