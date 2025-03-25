from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.button import Button
from fabric.widgets.stack import Stack
from fabric.widgets.wayland import WaylandWindow as Window
from gi.repository import GLib, Gdk
from modules.launcher import AppLauncher
from modules.dashboard.dashboard import Dashboard
from modules.wallpapers import WallpaperSelector
from modules.notification_popup import NotificationContainer
from modules.power import PowerMenu
import modules.icons as icons
from modules.corners import RoundedAngleEnd

import json


class Notch(Window):
    def __init__(self, monitor_id=None, server=None, **kwargs):
        super().__init__(
            name="notch-window",
            monitor=monitor_id,
            layer="top",
            anchor="top",
            margin="-40px 10px 10px 10px",
            keyboard_mode="none",
            exclusivity="normal",
            visible=True,
            all_visible=True,
        )
        self.monitor_id = monitor_id

        with open("./data.json", "r+") as file:
            self.data = json.load(file)
            self.data["notch_status" + str(self.monitor_id)] = "closed"
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()

        
        self.open_widget = None

        self.corners = {
            "compact": {
                "left": 
                    {"height": 39, "width":60},
                "right": 
                    {"height": 39, "width":60}
            },
            "launcher": {
                "left":
                    {"height": 220, "width": 120}, "right":
                    {"height": 220, "width": 120}
            },
            "wallpapers": {
                "left":
                    {"height": 420, "width": 120},
                "right":
                    {"height": 420, "width": 120}
            },
            "notification": {
                "left":
                    {"height": 78, "width": 60},
                "right":
                    {"height": 78, "width": 60},

            },
            "power": {
                "left":
                    {"height": 65, "width": 60},
                "right":
                    {"height": 65, "width": 60},

            },
            "dashboard": {
                "left":
                    {"height": 375, "width": 60},
                "right":
                    {"height": 375, "width": 60},

            }


        }


        self.dashboard = Dashboard()
        self.launcher = AppLauncher(monitor_id)
        self.wallpapers = WallpaperSelector(self.data["wallpapers_dir"])
        self.notification = NotificationContainer(server=server, monitor_id=monitor_id)
        self.floating_notification = NotificationContainer(server=server, monitor_id=monitor_id, h_expand=False)
        self.power = PowerMenu()

        self.compact = Button(
            name="notch-compact",
            h_expand=True,
            label=f"{self.data["username"]}@{self.data["hostname"]}",
            on_clicked=lambda *_: self.open_notch("dashboard"))

        self.stack = Stack(
            name="notch-stack",
            orientation="v",
            h_expand=True,
            transition_type="crossfade",
            transition_duration=250,
            children=[
                self.compact,
                self.launcher,
                self.dashboard,
                self.wallpapers,
                self.notification,
                self.power,
            ]
        )
        
        self.notch_box_top = CenterBox(
            name="notch-box-top",
            orientation="h",
            h_align="center",
            v_align="center",
            start_children=RoundedAngleEnd(
                name="corner-notch-left", 
                style_classes=["corner-notch"], 
                place="topleft", 
                height=self.corners["compact"]["left"]["height"], width=self.corners["compact"]["left"]["width"]),
            center_children=self.stack, 
            end_children=RoundedAngleEnd(name="corner-notch-right", style_classes=["corner-notch"], place="topright", height=self.corners["compact"]["right"]["height"], width=self.corners["compact"]["right"]["width"])
        )

        self.notch_box_bottom = Box(name="notch-box-bottom",
                                    orientation="h",
                                    h_expand=True,
                                    v_expand=True,
                                    h_align="center",
                                    v_align="center",
                                    children=[self.floating_notification]
        )


        self.notch_box = CenterBox(
            name="notch-box",
            orientation="v",
            h_align="center",
            v_align="center",
            start_children=self.notch_box_top,
            center_children=self.notch_box_bottom
        )



        self.hidden = False
        self.add(self.notch_box)
        self.show_all()
        self.wallpapers.viewport.hide()

        # Conectar evento de teclado
        self.connect("key-press-event", self.on_key_press)

    def on_key_press(self, widget, event):
        print(event.keyval)
        close = True
        match self.open_widget:
            case "launcher":
                close = self.launcher.on_key_press_event(widget, event)
            case "wallpapers":
                close = self.wallpapers.on_key_press_event(widget, event)
            case "dashboard":
                close = self.dashboard.on_key_press_event(widget, event)

        if close and event.keyval == 65307:
            self.close_notch()

    def on_button_enter(self, widget, event):
        window = widget.get_window()
        if window:
            window.set_cursor(Gdk.Cursor(Gdk.CursorType.HAND2))

    def on_button_leave(self, widget, event):
        window = widget.get_window()
        if window:
            window.set_cursor(None)

    def close_notch(self):
        self.floating_notification.remove_style_class("open")
        self.notch_box_bottom.remove_style_class("open")
        self.set_keyboard_mode("none")
        self.open_widget = None

        if self.hidden:
            self.notch_box.remove_style_class("hideshow")
            self.notch_box.add_style_class("hidden")

        # print(self.notch_box.children[0].children[0].children[0].children[0].children[0].children[0])
        # print(self.notch_box.children[0].children[0].children[0].children[0].children[2].children[0])
        self.notch_box.children[0].children[0].children[0].children[0].children[0].children[0].animate_height(self.corners["compact"]["left"]["height"], 0.25, (0.5, 0.25, 0, 1))
        self.notch_box.children[0].children[0].children[0].children[0].children[2].children[0].animate_height(self.corners["compact"]["right"]["height"], 0.25, (0.5, 0.25, 0, 1))



        for widget in [self.launcher, self.dashboard, self.wallpapers, self.notification, self.power, self.compact]:
            widget.remove_style_class("open")
        for style in ["launcher", "dashboard", "wallpapers", "notification", "power", "compact"]:
            self.stack.remove_style_class(style)

        self.wallpapers.on_close()
        self.dashboard.on_close()

        self.compact.remove_style_class("hidden")
        self.stack.set_visible_child(self.compact)

        with open("./data.json", "r+") as file:
            self.data = json.load(file)
            self.data["notch_status" + str(self.monitor_id)] = "closed"
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()

        if len(self.notch_box.children[0].children[1].children[0].children[0].children) > 0:
            self.open_notch("notification")

    def open_notch(self, widget: str):
        self.set_keyboard_mode("exclusive")
        if self.open_widget not in ["notification", None] and widget == "notification":
            return

        self.open_widget = widget

        if self.open_widget is not "notification":
            self.notch_box_bottom.add_style_class("open")
            self.floating_notification.add_style_class("open")

        if self.hidden:
            self.notch_box.remove_style_class("hidden")
            self.notch_box.add_style_class("hideshow")

        widgets = {
            "compact": self.compact,
            "launcher": self.launcher,
            "dashboard": self.dashboard,
            "wallpapers": self.wallpapers,
            "notification": self.notification,
            "power": self.power
        }



        # Limpiar clases y estados previos
        #self.compact.add_style_class("hidden")
        for style in widgets.keys():
            self.stack.remove_style_class(style)
        for w in widgets.values():
            w.remove_style_class("open")

        try:
            self.notch_box.children[0].children[0].children[0].children[0].children[0].children[0].animate_height(self.corners[widget]["left"]["height"], 0.25)
            self.notch_box.children[0].children[0].children[0].children[0].children[2].children[0].animate_height(self.corners[widget]["right"]["height"], 0.25)
        except KeyError:
            pass

        # Configurar según el widget solicitado
        if widget in widgets:
            # pass
            self.stack.add_style_class(widget)
            self.stack.set_visible_child(widgets[widget])
            widgets[widget].add_style_class("open")

            if widget == "power":
                self.power.btn_shutdown.grab_focus()

            if widget == "dashboard":
                widgets[widget].widgets.audio.update_slider()

            # Acciones específicas para el launcher
            if widget == "launcher":
                self.launcher.open_launcher()
                self.launcher.search_entry.set_text("")
                self.launcher.search_entry.grab_focus()

            if widget == "notification":
                self.set_keyboard_mode("none")

            if widget == "wallpapers":
                self.wallpapers.search_entry.set_text("")
                self.wallpapers.search_entry.grab_focus()
                GLib.timeout_add(
                    500, 
                    lambda: (
                        self.wallpapers.viewport.show(), 
                        self.wallpapers.viewport.set_property("name", "wallpaper-icons")
                    )
                )

            if widget != "wallpapers":
                self.wallpapers.viewport.hide()
                self.wallpapers.viewport.set_property("name", None)

        else:
            self.stack.set_visible_child(self.dashboard)


        with open("./data.json", "r+") as file:
            self.data = json.load(file)
            self.data["notch_status" + str(self.monitor_id)] = widget
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()


    def colorpicker(self, button, event):
        if event.button == 1:
            GLib.spawn_command_line_async(f"bash {self.data["home_dir"]}/.config/fabric/scripts/hyprpicker-hex.sh")
        elif event.button == 2:
            GLib.spawn_command_line_async(f"bash {self.data["home_dir"]}/.config/fabric/scripts/hyprpicker-hsv.sh")
        elif event.button == 3:
            GLib.spawn_command_line_async(f"bash {self.data["home_dir"]}/.config/fabric/scripts/hyprpicker-rgb.sh")

    def toggle_hidden(self):
        self.hidden = not self.hidden
        if self.hidden:
            self.notch_box.add_style_class("hidden")
        else:
            self.notch_box.remove_style_class("hidden")
