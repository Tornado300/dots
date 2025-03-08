from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from fabric.widgets.stack import Stack
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk
import modules.icons as icons
from modules.calendar import Calendar
from modules.dashboard.audio import AudioModule

class Widgets(Box):
    def __init__(self, **kwargs):
        super().__init__(
            name="notch-dashboard",
            orientation="v",
            h_expand=True,
            v_expand=True,
            visible=True,
            all_visible=True,
        )
        self.wifi = Box(
            name="dashboard-segment-wifi",
            style_classes=["dashboard"],
            h_expand=True,
            orientation="v",
            children=[Label(label="Wi-Fi", h_align="center", v_align="center")]
        )

        self.bluetooth = Box(
            name="dashboard-segment-bluetooth",
            style_classes=["dashboard"],
            h_expand=True,
            orientation="v",
            children=[Label(label="Bluetooth", h_align="center", v_align="start")]
        )

        self.audio = AudioModule()

        self.quickbuttons = Box(
            name="dashboard-segment-quickbuttons",
            style_classes=["dashboard"],
            children=[
                Button("X"), 
                Button("X"), 
                Button("X"), 
                Button("x")]
        )

        self.system = Box(
            name="dashboard-segment-system",
            style_classes=["dashboard"],
            orientation="v",
            v_expand=True,
            children=[
                Label(label="System", style_classes=[""], h_align="center", v_align="start"), 
                Label(label="cpu:", style_classes=["dashboard-sys-stats"], h_align="start", v_expand=True), 
                Label(label="gpu:", style_classes=["dashboard-sys-stats"], h_align="start", v_expand=True), 
                Label(label="ram:", style_classes=["dashboard-sys-stats"], h_align="start", v_expand=True), 
                Label(label="network:", style_classes=["dashboard-sys-stats"], h_align="start", v_expand=True)]
        )

        self.container_top = Box(
            name="dashboard-container-top",
            style_classes=["dashboard"],
            v_expand=False,
            h_expand=True,
            spacing=10,
            children=[self.wifi, self.bluetooth]
        )



        self.container_bottom_right = Box(
            name="dashboard-container-bottom-right",
            style_classes=["dashboard"],
            v_expand=True,
            orientation="v",
            spacing=10,
            children=[self.quickbuttons, self.system]
        )

        self.container_bottom = Box(
            name="dashboard-container-bottom",
            style_classes=["dashboard"],
            v_expand=True,
            h_expand=True,
            spacing=10,
            children=[self.audio, self.container_bottom_right]
        )

        self.add(self.container_top)
        self.add(self.container_bottom)

        self.show_all()
    
    def audio_slider_changed(self, value):
        print(value.value)

    def format_slider_value(widget, scale, value):
        return f"{int(value)}%"




class Dashboard(Box):
    def __init__(self, **kwargs):
        super().__init__(
            name="dashboard",
            orientation="v",
            spacing=8,
            h_expand=True,
            v_expand=True,
            visible=True,
            all_visible=True,
        )

        self.widgets = Widgets()

        self.calendar = Calendar()

        self.stack = Stack(
            name="stack",
            transition_type="slide-left-right",
            transition_duration=500,
            v_expand=True,
        )

        self.switcher = Gtk.StackSwitcher(
            name="switcher",
            spacing=8,
        )


        self.stack.add_titled(self.widgets, "widgets", "Widgets")
        self.stack.add_titled(self.calendar, "calendar", "Calendar")

        self.switcher.set_stack(self.stack)
        self.switcher.set_hexpand(True)
        self.switcher.set_homogeneous(True)
        self.switcher.set_can_focus(True)

        self.add(self.switcher)
        self.add(self.stack)

        self.show_all()

    def go_to_next_child(self):
        children = self.stack.get_children()
        current_index = self.get_current_index(children)
        next_index = (current_index + 1) % len(children)
        self.stack.set_visible_child(children[next_index])

    def go_to_previous_child(self):
        children = self.stack.get_children()
        current_index = self.get_current_index(children)
        previous_index = (current_index - 1 + len(children)) % len(children)
        self.stack.set_visible_child(children[previous_index])

    def get_current_index(self, children):
        current_child = self.stack.get_visible_child()
        return children.index(current_child) if current_child in children else -1
