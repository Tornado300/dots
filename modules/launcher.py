from collections.abc import Iterator
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from fabric.widgets.entry import Entry
from fabric.widgets.image import Image
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.utils import DesktopApp, get_desktop_applications, idle_add, remove_handler
from gi.repository import GLib, Gtk

from rapidfuzz import fuzz
import json


class AppLauncher(Box):
    def __init__(self, monitor_id, **kwargs):
        super().__init__(
            name="app-launcher",
            visible=False,
            all_visible=False,
            **kwargs,
        )
        with open("./data/launcher.json", "r+") as file:
            self.data = json.load(file)
            if "app_usage" not in self.data:
                self.data["app_usage"] = {}
            if "excluded_applications" not in self.data:
                self.data["excluded_applications"] = []
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()

        self.monitor_id = monitor_id
        self.custom_entrys = {"Wallpapers": f"fabric-cli exec main-ui 'notch{self.monitor_id}.open_notch(\"wallpapers\")'"}
        self._arranger_handler: int = 0
        self._all_apps = get_desktop_applications()

        self.viewport = Box(name="viewport", spacing=4, orientation="v")
        self.search_entry = Entry(
            name="search-entry",
            placeholder="Search Applications...",
            h_expand=True,
            notify_text=lambda entry, *_: self.arrange_viewport(entry.get_text()),
            on_activate=lambda entry, *_: self.on_search_entry_activate(entry.get_text()),
            on_button_press_event=self.on_key_press_event,
        )
        self.search_entry.props.xalign = 0.5
        self.scrolled_window = ScrolledWindow(
            name="scrolled-window",
            spacing=10,
            min_content_size=(450, 105),
            max_content_size=(450, 105),
            child=self.viewport,
        )

        self.header_box = Box(
            name="header-box",
            spacing=10,
            orientation="h",
            children=[self.search_entry],
        )

        self.launcher_box = Box(
            name="launcher-box",
            spacing=10,
            h_expand=True,
            orientation="v",
            children=[
                self.header_box,
                self.scrolled_window,
            ],
        )

        self.add(self.launcher_box)
        self.show_all()

    def close_launcher(self):
        self.viewport.children = []
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.close_notch()'")

    def open(self):
        self._all_apps = get_desktop_applications()
        self.arrange_viewport()
        self.search_entry.set_text("")
        self.search_entry.grab_focus()

    def on_key_press_event(self, widget, event):
        if event.keyval == 65307:  # Escape key
            self.close_launcher()
        if event.keyval == 65293 and self.search_entry.is_focus():
            self.viewport.children[self.selected_application].grab_focus()
        if event.keyval == 106 and event.state == 4:  # ctrl + j key
            self.selected_application = (self.selected_application + 1) % len(self.viewport.children)
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.NORMAL)
            self.viewport.children[self.selected_application].grab_focus()
        if event.keyval == 107 and event.state == 4:  # ctrl + k key
            self.selected_application = (self.selected_application - 1) % len(self.viewport.children)
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.NORMAL)
            self.viewport.children[self.selected_application].grab_focus()
        if event.keyval == 108 and event.state == 4:  # ctrl + l key
            self.search_entry.grab_focus()
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.FOCUSED)
        return True

    def arrange_viewport(self, query: str = ""):
        remove_handler(self._arranger_handler) if self._arranger_handler else None
        self.viewport.children = []
        self.selected_application = 0
        if query.startswith(":"):
            filtered_apps_iter = iter(self.custom_entrys)
        else:
            filtered_apps_iter = self.sort_applications(query)

        # should_resize = operator.length_hint(filtered_apps_iter) == len(self._all_apps)

        self._arranger_handler = idle_add(
            lambda *args: self.add_next_application(*args) or False, filtered_apps_iter, pin=True,
        )

        return False

    def add_next_application(self, apps_iter: Iterator[DesktopApp]):
        if not (app := next(apps_iter, None)):
            return False
        self.viewport.add(self.bake_application_slot(app))
        self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.FOCUSED)
        return True

    def bake_application_slot(self, app: DesktopApp | dict, **kwargs) -> Button:
        # print(app, self.custom_entrys[app])
        if isinstance(app, str):
            return Button(
                name="app-slot-button",
                child=Box(
                    name="app-slot-box",
                    orientation="h",
                    spacing=10,
                    children=[
                        Label(
                            name="app-label",
                            label=app,
                            ellipsization="end",
                            v_align="center",
                            h_align="center",
                        ),
                    ],
                ),
                on_clicked=lambda *_: (GLib.spawn_command_line_async(self.custom_entrys[app]), self.add_usage(app.casefold())),
                # on_clicked=lambda *_: (print("test!!!!!")),
            )
        else:
            return Button(
                name="app-slot-button",
                child=Box(
                    name="app-slot-box",
                    orientation="h",
                    spacing=10,
                    children=[
                        Image(name="app-icon", pixbuf=app.get_icon_pixbuf().scale_simple(30, 30, 1)),
                        Label(
                            name="app-label",
                            label=app.display_name or "Unknown",
                            ellipsization="end",
                            v_align="center",
                            h_align="center",
                        ),
                    ],
                ),
                tooltip_text=app.description,
                on_clicked=lambda *_: (app.launch(), self.close_launcher(), self.add_usage(app.display_name.casefold())),
                # on_clicked=lambda *_: (print("test2!!!!")),
                **kwargs,
            )

    def on_search_entry_activate(self, text):
        if text == ":wp":
            GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.open_notch(\"wallpapers\")'")

    def sort_applications(self, query):
        with open("./data/launcher.json", "r+") as file:
            self.data = json.load(file)
        pairs = []
        for app in self._all_apps:
            if app.display_name in self.data["excluded_applications"]:
                continue
            if isinstance(app, DesktopApp):
                if app.display_name.casefold() in self.data["app_usage"]:
                    pairs.append([(fuzz.WRatio(query, app.display_name.casefold()) * 0.7) + (self.data["app_usage"][app.display_name.casefold()] * 0.3), app])
                else:
                    pairs.append([(fuzz.WRatio(query, app.display_name.casefold()) * 0.7), app])

        result = sorted(pairs, key=lambda pair: pair[0], reverse=True)
        for app in result:
            print(app[0], app[1].display_name)
        result = [r[1] for r in result]
        return iter(result)

    def add_usage(_, app_name):
        with open("./data/launcher.json", "r+") as file:
            data = json.load(file)
            result = sorted(data["app_usage"], key=lambda pair: pair[0], reverse=True)
            print(result)
            if app_name in data["app_usage"]:
                data["app_usage"][app_name] += 1
            else:
                data["app_usage"][app_name] = 1
            file.seek(0)
            json.dump(data, file, indent=2)
            file.truncate()
