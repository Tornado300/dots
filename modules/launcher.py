from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from fabric.widgets.entry import Entry
from fabric.widgets.image import Image
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.utils import get_desktop_applications
from gi.repository import GLib, Gtk

from rapidfuzz import fuzz
from modules.launcher_tools import qalculate
import json


class Launcher(Box):
    def __init__(self, monitor_id, **kwargs):
        super().__init__(
            name="launcher",
            visible=False,
            all_visible=False,
            **kwargs,
        )
        with open("./data/launcher.json", "r+") as file:
            self.data = json.load(file)
            if "entry_usage" not in self.data:
                self.data["entry_usage"] = {}
            if "excluded_entrys" not in self.data:
                self.data["excluded_entrys"] = []
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()

        self.monitor_id = monitor_id
        self.all_entrys = {}

        self.viewport = Box(name="viewport", spacing=4, orientation="v")
        self.search_entry = Entry(
            name="search-entry",
            placeholder="Search Applications...",
            h_expand=True,
            notify_text=lambda entry, *_: self.update_entrys(entry.get_text()),
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

    def extract_app_data(self):
        result = []
        for app in list(get_desktop_applications()):
            result.append({"name": app.display_name, "image": app.get_icon_pixbuf().scale_simple(30, 30, 1), "description": app.description, "app": app})
        return result

    def norm_entrys(self, entrys):
        template = {"name": None, "image": None, "description": None, "command": None, "app": None, "dynamic": False}
        result = []
        if not isinstance(entrys, list):
            temp = template.copy()
            for key in entrys:
                temp[key] = entrys[key]
            return temp

        else:
            for entry in entrys:
                temp = template.copy()
                for key in entry:
                    temp[key] = entry[key]
                result.append(temp)
        return result

    def sort_entrys(self, query):
        with open("./data/launcher.json", "r+") as file:
            self.data = json.load(file)
        result = []
        for entry_list in [self.all_apps, self.all_custom_entrys, self.all_tools]:
            pairs = []
            for entry in entry_list:
                if entry["name"] in self.data["excluded_entrys"]:
                    continue

                # if entry["dynamic"] and query != "":
                    # tool_result = globals()[entry["name"]](query)
                    # entry = self.norm_entrys(tool_result["entry"])
                    # pairs.append([tool_result["weight"], entry])
                    # continue

                if entry["name"].casefold() in self.data["entry_usage"]:
                    weight = (fuzz.WRatio(query.casefold(), entry["name"].casefold()) * 0.7) + (self.data["entry_usage"][entry["name"].casefold()] * 0.3)
                else:
                    weight = (fuzz.WRatio(query.casefold(), entry["name"].casefold()) * 0.7)

                if weight >= 40 or query == "":
                    pairs.append([weight, entry])
            result.extend(sorted(pairs, key=lambda pair: pair[0], reverse=True))
        result = [r[1] for r in result]
        return result

    def add_entrys(self, entrys):
        for entry in entrys:
            self.viewport.add(self.bake_entry_slot(entry))
        if len(self.viewport.children) > 0:
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.FOCUSED)
        return True

    def bake_entry_slot(self, entry, **kwargs) -> Button:
        btn = Button(
            name="entry-slot-button",
            child=Box(
                name="entry-slot-box",
                orientation="h",
                spacing=10,
                children=[
                    Label(
                        name="entry-label",
                        label=entry["name"] or "Unknown",
                        ellipsization="end",
                        v_align="center",
                        h_align="center",
                    ),
                ],
            ),
            tooltip_text=entry["description"]
        )
        if entry["app"] is not None:
            btn.connect("clicked", lambda *_: (entry["app"].launch(), self.close_launcher(), self.add_usage(entry["name"].casefold())))
        elif entry["command"] is not None:
            btn.connect("clicked", lambda *_: (GLib.spawn_command_line_async(entry["command"]), self.add_usage(entry["name"].casefold())))

        if entry["image"] is not None:
            btn.children[0].children = [Image(name="entry-icon", pixbuf=entry["image"]), btn.children[0].children[0]]
        return btn

    def update_entrys(self, query: str = ""):
        self.viewport.children = []
        self.all_apps = self.norm_entrys(self.extract_app_data())
        self.all_custom_entrys = self.norm_entrys([
            {"name": "Wallpapers", "description": "Change wallpaper", "command": f"fabric-cli exec main-ui 'notch{self.monitor_id}.open_notch(\"wallpapers\")'"}
        ])
        self.all_tools = self.norm_entrys([
            {"name": "qalculate", "description": "smart calculator", "dynamic": True}
        ])
        sorted_entrys = self.sort_entrys(query)
        self.add_entrys(sorted_entrys)

    def close_launcher(self):
        self.viewport.children = []
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.close_notch()'")

    def open(self):
        self.viewport.children = []
        self.selected_entry = 0
        self.update_entrys()
        self.search_entry.set_text("")
        self.search_entry.grab_focus()

    def on_key_press_event(self, widget, event):
        if event.keyval == 65307:  # Escape key
            self.close_launcher()
        if event.keyval == 65293 and self.search_entry.is_focus():
            self.viewport.children[self.selected_entry].grab_focus()
        if event.keyval == 106 and event.state == 4:  # ctrl + j key
            self.selected_entry = (self.selected_entry + 1) % len(self.viewport.children)
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.NORMAL)
            self.viewport.children[self.selected_entry].grab_focus()
        if event.keyval == 107 and event.state == 4:  # ctrl + k key
            self.selected_entry = (self.selected_entry - 1) % len(self.viewport.children)
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.NORMAL)
            self.viewport.children[self.selected_entry].grab_focus()
        if event.keyval == 108 and event.state == 4:  # ctrl + l key
            self.search_entry.grab_focus()
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.FOCUSED)
            return True

    def add_usage(self, entry_name):
        with open("./data/launcher.json", "r+") as file:
            data = json.load(file)
            if entry_name in data["entry_usage"]:
                data["entry_usage"][entry_name] += 1
            else:
                data["entry_usage"][entry_name] = 1
                file.seek(0)
                json.dump(data, file, indent=2)
                file.truncate()
