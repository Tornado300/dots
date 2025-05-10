from gi.repository import Gtk
import gi
import cairo
from typing import Literal
from collections.abc import Iterable
from fabric.widgets.widget import Widget
from services.animator import Animator

gi.require_version("Gtk", "3.0")


class RoundedAngleEnd(Gtk.DrawingArea, Widget):
    def __init__(
        self,
        place: Literal["topleft", "topright", "bottomleft", "bottomright"],
        name: str | None = None,
        visible: bool = True,
        all_visible: bool = False,
        style: str | None = None,
        style_classes: Iterable[str] | str | None = None,
        tooltip_text: str | None = None,
        tooltip_markup: str | None = None,
        h_align: Literal["fill", "start", "end", "center", "baseline"] | Gtk.Align | None = None,
        v_align: Literal["fill", "start", "end", "center", "baseline"] | Gtk.Align | None = None,
        h_expand: bool = False,
        v_expand: bool = False,
        height: int = 0,
        width: int = 0,
        custom_curve: list = None,
        **kwargs,
    ):
        Gtk.DrawingArea.__init__(self)
        Widget.__init__(
            self,
            name,
            visible,
            all_visible,
            style,
            style_classes,
            tooltip_text,
            tooltip_markup,
            h_align,
            v_align,
            h_expand,
            v_expand,
            height,
            **kwargs,
        )

        self.place = place
        self.width = width
        self.height = height
        self.custom_curve = custom_curve

        self.height_animator = (Animator(
            bezier_curve=(0, 0, 1, 1),
            duration=0.8,
            min_value=self.height,
            max_value=self.height,
            tick_widget=self,
            notify_value=lambda p, *_: self.set_height(p.value),
        ).build().unwrap())

        self.width_animator = (Animator(
            bezier_curve=(0, 0, 1, 1),
            duration=0.8,
            min_value=self.width,
            max_value=self.width,
            tick_widget=self,
            notify_value=lambda p, *_: self.set_width(p.value),
        ).build().unwrap())

        self.set_size_request(0, 0)

        self.connect("draw", self.on_draw)

    def animate_height(self, value: int, duration: float, bezier_curve: tuple = (0.5, 0.25, 0, 1.25)):
        # print("#", value)
        self.height_animator.pause()
        self.height_animator.duration = duration
        self.height_animator.bezier_curve = bezier_curve
        self.height_animator.min_value = self.height
        self.height_animator.max_value = value
        self.height_animator.play()
        return

    def animate_width(self, value: int, duration: float, bezier_curve: tuple = (0.5, 0.25, 0, 1.25)):
        self.width_animator.pause()
        self.width_animator.duration = duration
        self.width_animator.bezier_curve = bezier_curve
        self.width_animator.min_value = self.width
        self.width_animator.max_value = value
        self.width_animator.play()
        return

    def get_height(self):
        return self.height

    def set_height(self, value: int):
        # print("hight", value)
        self.height = value

    def get_width(self):
        return self.width

    def set_width(self, value: int):
        self.width = value

    def set_curve(self, value: list):
        self.custom_curve = value

    def on_draw(self, _, cr: cairo.Context):
        context = self.get_style_context()
        # border_color: Gdk.RGBA = context.get_border_color(Gtk.StateFlags.NORMAL)
        # border_width = (max((border := context.get_border(Gtk.StateFlags.NORMAL)).top, border.bottom, border.left, border.right) * 2)

        allocation = self.get_allocation()
        self.alloc_width, self.alloc_height = allocation.width, allocation.height
        self.set_size_request(self.width, self.height)

        cr.save()
        self.render_shape(cr)
        Gtk.render_background(context, cr, 0, 0, self.alloc_width, self.alloc_height)

        cr.restore()

    def render_shape(self, cr: cairo.Context):
        width = self.width
        height = self.height

        if self.place == "topleft":
            if self.custom_curve is None:
                curve = [["width / 1.3", "0"], ["width / 2", "height"], ["width", "height"]]
            else:
                curve = self.custom_curve
            cr.move_to(0, 0)
            exec("cr.curve_to(" + curve[0][0] + "," + curve[0][1] + "," + curve[1][0] + "," + curve[1][1] + "," + curve[2][0] + "," + curve[2][1] + ")")
            cr.line_to(width, 0)
            cr.close_path()
            cr.clip()
        if self.place == "topright":
            if self.custom_curve is None:
                curve = [["width / 2.7", "0"], ["width / 2", "height"], ["0", "height"]]
            else:
                curve = self.custom_curve
            cr.move_to(width, 0)
            exec("cr.curve_to(" + curve[0][0] + "," + curve[0][1] + "," + curve[1][0] + "," + curve[1][1] + "," + curve[2][0] + "," + curve[2][1] + ")")
            cr.line_to(0, 0)
            cr.close_path()
            cr.clip()
        # if self.place == "bottomleft":
            # if self.custom_curve is None:
            # curve = [[], [], []]
            # else:
            # curve = self.custom_curve
            # cr.move_to(0, r)
            # exec("cr.curve_to(" + curve[0][0] + "," + curve[0][1] + "," + curve[1][0] + "," + curve[1][1] + "," + curve[2][0] + "," + curve[2][1] + ")")
            # cr.line_to(ratio * r, r)
            # cr.close_path()
            # cr.clip()
            # cr.move_to(0, 0)
            # cr.curve_to(ratio * r / 2, 0, ratio * r / 2, r, ratio * r, r)
            # cr.stroke()
        # if self.place == "bottomright":
            # if self.custom_curve is None:
            # curve = [[], [], []]
            # else:
            # curve = self.custom_curve
            # cr.move_to(ratio * r, r)
            # exec("cr.curve_to(" + curve[0][0] + "," + curve[0][1] + "," + curve[1][0] + "," + curve[1][1] + "," + curve[2][0] + "," + curve[2][1] + ")")
            # cr.line_to(0, r)
            # cr.close_path()
            # cr.clip()
            # cr.move_to(ratio * r, 0)
            # cr.curve_to(ratio * r / 2, 0, ratio * r / 2, r, 0, r)
            # cr.stroke()
