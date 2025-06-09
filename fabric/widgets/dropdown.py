from gi.repository import Gtk
from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.stack import Stack
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.widget import Widget
from fabric.widgets.overlay import Overlay

import gi
import cairo

gi.require_version("Gtk", "3.0")


class DropdownFade(Gtk.DrawingArea, Widget):
    def __init__(self):
        super().__init__(
            h_expand=True,
            v_expand=True
        )
        self.connect("draw", self.on_draw)

    def on_draw(self, widget, cr):
        width = self.get_allocated_width()
        height = self.get_allocated_height()

        # Create gradient
        gradient = cairo.LinearGradient(0, 0, 0, height)
        gradient.add_color_stop_rgba(0, 0, 0, 0, 0.5)  # dark at top
        gradient.add_color_stop_rgba(0.1, 0, 0, 0, 0)  # transparent at middle
        gradient.add_color_stop_rgba(0.9, 0, 0, 0, 0)  # transparent at middle
        gradient.add_color_stop_rgba(1, 0, 0, 0, 0.5)  # dark at bottom

        cr.set_source(gradient)
        cr.rectangle(0, 0, width, height)
        cr.fill()
        return False

    def do_realize(self):
        Gtk.DrawingArea.do_realize(self)
        if (window := self.get_window()):
            window.set_pass_through(True)
        return


class Dropdown(Stack):
    def __init__(self, name, placeholder):
        self.name = name
        super().__init__(
            name=self.name,
            style_classes=["dropdown"],
            transition_type="slide-down",
            transition_duration=400
        )

        self.element_list = Box(name="element-list", orientation="v")
        self.scrolled_window = ScrolledWindow(
            name="scrolled-window",
            style_classes=["closed"],
            child=self.element_list,
            v_scrollbar_policy="external",
            h_scrollbar_policy="never"
        )
        self.fade_overlay = Overlay(child=self.scrolled_window)
        self.fade = DropdownFade()

        self.add(self.fade_overlay)

    def add_new_element(self, label, tooltip=None, image=None, callback=None, value=None):
        # callback gets  executed when button is pressed
        # value gets passed to callback as an argument
        new_element = Button(name="element", label=label, tooltip_text=tooltip, image=image, on_clicked=lambda element: self.element_clicked(element, callback, value))
        self.element_list.add(new_element)
        return new_element

    def remove_element(self, element):
        self.element_list.remove(element)

    def get_elements(self):
        return self.element_list.children

    def set_current_selection(self, label, tooltip_text=None, image=None):
        try:
            self.remove(self.current_selection)
        except AttributeError:
            pass
        self.current_selection = Button(name="current-selection", style_classes=["opened"], label=label, tooltip_text=tooltip_text, image=image, on_clicked=self.open)
        self.add(self.current_selection)
        self.set_visible_child(self.current_selection)

    def element_clicked(self, element, callback, value):
        self.set_current_selection(label=element.get_label(), tooltip_text=element.get_tooltip_text(), image=element.get_image())
        self.close()
        if callback is not None:
            callback()

    def open(self, *_):
        self.scrolled_window.remove_style_class("closed")
        self.scrolled_window.add_style_class("opened")
        self.current_selection.remove_style_class("opened")
        self.current_selection.add_style_class("closed")

        self.fade_overlay.add_overlay(self.fade)
        self.fade_overlay.set_overlay_pass_through(self.fade, True)
        self.set_visible_child(self.fade_overlay)

    def close(self, *_):
        self.current_selection.remove_style_class("closed")
        self.current_selection.add_style_class("opened")
        self.scrolled_window.remove_style_class("opened")
        self.scrolled_window.add_style_class("closed")

        try:
            self.fade_overlay.remove_overlay(self.fade)
        except ValueError:
            pass
        self.set_visible_child(self.current_selection)
