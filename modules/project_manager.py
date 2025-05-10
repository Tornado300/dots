from collections.abc import Iterator
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from fabric.widgets.entry import Entry
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.utils import idle_add, remove_handler
from gi.repository import GLib, Gtk

from rapidfuzz import fuzz
import json


class ProjectManager(Box):
    def __init__(self, monitor_id, **kwargs):
        super().__init__(
            name="project-manager",
            visible=False,
            all_visible=False,
            **kwargs,
        )
        self.monitor_id = monitor_id
        self.all_projects = {"fabirc ui": "~/.config/fabric/"}
        self._arranger_handler: int = 0

        self.viewport = Box(name="viewport", spacing=4, orientation="v")
        self.search_entry = Entry(
            name="search-entry",
            placeholder="Search Project...",
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

        self.manager_box = Box(
            name="manager-box",
            spacing=10,
            h_expand=True,
            orientation="v",
            children=[
                self.header_box,
                self.scrolled_window,
            ],
        )

        self.add(self.manager_box)
        self.show_all()

    def close_manager(self):
        self.viewport.children = []
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.close_notch()'")

    def open(self):
        self.arrange_viewport()
        self.search_entry.set_text("")
        self.search_entry.grab_focus()

    def on_key_press_event(self, widget, event):
        if event.keyval == 65307:  # Escape key
            self.close_manager()
        if event.keyval == 65293 and self.search_entry.is_focus():
            self.viewport.children[self.selected_project].grab_focus()
        if event.keyval == 106 and event.state == 4:  # ctrl + j key
            self.selected_project = (self.selected_project + 1) % len(self.viewport.children)
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.NORMAL)
            self.viewport.children[self.selected_project].grab_focus()
        if event.keyval == 107 and event.state == 4:  # ctrl + k key
            self.selected_project = (self.selected_project - 1) % len(self.viewport.children)
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.NORMAL)
            self.viewport.children[self.selected_project].grab_focus()
        if event.keyval == 108 and event.state == 4:  # ctrl + l key
            self.search_entry.grab_focus()
            self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.FOCUSED)
        return True

    def arrange_viewport(self, query: str = ""):
        remove_handler(self._arranger_handler) if self._arranger_handler else None
        self.viewport.children = []
        self.selected_project = 0
        filtered_projects_iter = self.sort_projects(query)

        self._arranger_handler = idle_add(
            lambda *args: self.add_next_project(*args) or False, filtered_projects_iter, pin=True,
        )
        return False

    def add_next_project(self, projects_iter: Iterator):
        if not (project := next(projects_iter, None)):
            return False
        self.viewport.add(self.bake_project_slot(project))
        self.viewport.children[0].get_style_context().set_state(Gtk.StateFlags.FOCUSED)
        return True

    def bake_project_slot(self, project, **kwargs) -> Button:
        return Button(
            name="project-slot-button",
            child=Box(
                name="project-slot-box",
                orientation="h",
                spacing=10,
                children=[
                    Label(
                        name="project-label",
                        label=project,
                        ellipsization="end",
                        v_align="center",
                        h_align="center",
                    ),
                    Label(
                        name="project-path",
                        label=self.all_projects[project]
                    )
                ],
            ),
            # TODO implement nvim start
            on_clicked=lambda *_: (),
        )

    def sort_projects(self, query):
        with open("./data/project_manager.json", "r+") as file:
            data = json.load(file)
            file.seek(0)
            json.dump(data, file, indent=2)
            file.truncate()
        pairs = []
        for project in self.all_projects:
            pairs.append([fuzz.WRatio(query, project.casefold()), project])

        result = sorted(pairs, key=lambda pair: pair[0], reverse=True)
        result = [r[1] for r in result]
        return iter(result)
