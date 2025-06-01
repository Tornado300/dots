from fabric.widgets.box import Box
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.stack import Stack
from fabric.widgets.wayland import WaylandWindow as Window
from gi.repository import Gdk
from modules.notch_widgets.launcher import Launcher
from modules.notch_widgets.dashboard.dashboard import Dashboard
from modules.notch_widgets.wallpapers import WallpaperSelector
from modules.notch_widgets.notification_popup import NotificationContainer
from modules.notch_widgets.power import PowerMenu
from modules.corners import RoundedAngleEnd
from modules.notch_widgets.colorpicker import Colorpicker
from modules.notch_widgets.project_manager import ProjectManager
from modules.notch_widgets.compact import Compact
import json


class WidgetWrapper:
    def __init__(self, widget, name, left_corner, right_corner, needs_key_events=False, on_close=False):
        self.widget = widget
        self.name = name
        self.needs_key_events = needs_key_events
        self.on_close = on_close
        self.corners = {
            "left": left_corner,
            "right": right_corner
        }


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
        self.widgets = {}
        self.open_widget = None

        with open("./data/data.json", "r+") as file:
            self.data = json.load(file)
            self.data["notch_status" + str(self.monitor_id)] = "closed"
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()

        self.floating_notification = NotificationContainer(server=server, monitor_id=monitor_id, h_expand=False)

        self.add_widget(WidgetWrapper(widget=Compact(), name="compact", left_corner={"height": 39, "width": 60}, right_corner={"height": 39, "width": 60}))
        self.add_widget(WidgetWrapper(widget=Launcher(monitor_id), name="launcher", left_corner={"height": 220, "width": 120}, right_corner={"height": 220, "width": 120}, needs_key_events=True))
        self.add_widget(WidgetWrapper(widget=WallpaperSelector(self.data["wallpapers_dir"]), name="wallpapers", left_corner={"height": 420, "width": 120}, right_corner={"height": 420, "width": 120}, on_close=True))
        self.add_widget(WidgetWrapper(widget=NotificationContainer(server=server, monitor_id=monitor_id), name="notification", left_corner={"height": 78, "width": 60}, right_corner={"height": 78, "width": 60}))
        self.add_widget(WidgetWrapper(widget=PowerMenu(), name="power", left_corner={"height": 65, "width": 60}, right_corner={"height": 65, "width": 60}))
        self.add_widget(WidgetWrapper(widget=Dashboard(), name="dashboard", left_corner={"height": 375, "width": 60}, right_corner={"height": 375, "width": 60}, on_close=True, needs_key_events=True))
        self.add_widget(WidgetWrapper(widget=Colorpicker(monitor_id), name="colorpicker", left_corner={"height": 175, "width": 60}, right_corner={"height": 175, "width": 60}))
        self.add_widget(WidgetWrapper(widget=ProjectManager(monitor_id), name="projectmanager", left_corner={"height": 220, "width": 120}, right_corner={"height": 220, "width": 120}, needs_key_events=True))

        self.stack = Stack(
            name="notch-stack",
            orientation="v",
            h_expand=True,
            transition_type="crossfade",
            transition_duration=250,
            children=[widget.widget for widget in self.widgets.values()]
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
                height=self.widgets["compact"].corners["left"]["height"],
                width=self.widgets["compact"].corners["left"]["width"],
            ),
            center_children=self.stack,
            end_children=RoundedAngleEnd(
                name="corner-notch-right",
                style_classes=["corner-notch"],
                place="topright",
                height=self.widgets["compact"].corners["right"]["height"],
                width=self.widgets["compact"].corners["right"]["width"],
            )
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

        self.notch_corner_left = self.notch_box.children[0].children[0].children[0].children[0].children[0].children[0]
        self.notch_corner_right = self.notch_box.children[0].children[0].children[0].children[0].children[2].children[0]
        self.hidden = False
        self.add(self.notch_box)
        self.show_all()
        self.widgets["wallpapers"].widget.viewport.hide()

        self.connect("key-press-event", self.on_key_press)

    def on_key_press(self, widget, event):
        print(event.keyval)
        close = True
        if self.widgets[self.open_widget].needs_key_events:
            close = self.widgets[self.open_widget].widget.on_key_press_event(widget, event)

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

        self.notch_corner_left.animate_height(self.widgets["compact"].corners["left"]["height"], 0.5, (0.5, 0.25, 0, 1))  # left notch corner
        self.notch_corner_right.animate_height(self.widgets["compact"].corners["right"]["height"], 0.5, (0.5, 0.25, 0, 1))  # right notch corner

        for widget in self.stack.children:
            widget.remove_style_class("open")
        for style in self.widgets.keys():
            self.stack.remove_style_class(style)

        for widget in self.widgets:
            if self.widgets[widget].on_close:
                self.widgets[widget].widget.on_close()

        self.widgets["compact"].widget.remove_style_class("hidden")
        self.stack.set_visible_child(self.widgets["compact"].widget)

        with open("./data/data.json", "r+") as file:
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

        if self.open_widget != "notification":
            self.notch_box_bottom.add_style_class("open")
            self.floating_notification.add_style_class("open")

        if self.hidden:
            self.notch_box.remove_style_class("hidden")
            self.notch_box.add_style_class("hideshow")

        for style in self.widgets.keys():
            self.stack.remove_style_class(style)
        for w in self.widgets.values():
            w.widget.remove_style_class("open")

        try:
            self.notch_corner_left.animate_height(self.widgets[widget].corners["left"]["height"], 0.5)
            self.notch_corner_right.animate_height(self.widgets[widget].corners["right"]["height"], 0.5)
        except KeyError:
            pass

        if widget in self.widgets.keys():
            pass

            if widget == "notification":
                self.set_keyboard_mode("none")
            elif widget == "colorpicker":
                self.set_keyboard_mode("on_demand")
                print(self.widgets[widget].widget)
                self.widgets[widget].widget.open()
            else:
                self.widgets[widget].widget.open()
                pass

            if widget != "wallpapers":
                self.widgets["wallpapers"].widget.viewport.hide()
                self.widgets["wallpapers"].widget.viewport.set_property("name", None)

            self.stack.add_style_class(widget)
            self.stack.set_visible_child(self.widgets[widget].widget)
            self.widgets[widget].widget.add_style_class("open")

        else:
            self.stack.set_visible_child(self.widgets["dashboard"].widget)

        with open("./data/data.json", "r+") as file:
            self.data = json.load(file)
            self.data["notch_status" + str(self.monitor_id)] = widget
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()

    def toggle_hidden(self):
        self.hidden = not self.hidden
        if self.hidden:
            self.notch_box.add_style_class("hidden")
        else:
            self.notch_box.remove_style_class("hidden")

    def add_widget(self, widget_wrapper):
        self.widgets[widget_wrapper.name] = widget_wrapper
