from fabric.widgets.button import Button
import cairo
import math


class GradientButton(Button):
    def __init__(self, color_points=None, gradient_type="radial", **kwargs):
        if color_points is None:
            self.show_gradient = False
        else:
            self.show_gradient = True

        self.gradient_type = gradient_type

        self.color_points = color_points
        super().__init__(**kwargs)

        if self.color_points is None:
            self.color_points = [(0, 1, 1, 1, 1), (1, 0, 0, 0, 0)]

        self.connect("draw", self._on_draw)

    def set_color_stops(self, color_points):
        for point in color_points:
            if not (isinstance(point, (list, tuple)) and len(point) in (4, 5)):
                raise ValueError("Each stop must be (offset, r, g, b) or (offset, r, g, b, a).")
            off = point[0]
            if not (0.0 <= off <= 1.0):
                raise ValueError(f"Offset {off} out of [0,1].")
            for c in point[1:]:
                if not (0.0 <= c <= 1.0):
                    raise ValueError(f"Color component {c} out of [0,1].")

        self.color_points = list(color_points)
        self.queue_draw()  # Fabric’s method to invalidate and redraw this widget

    def enable_gradient(self):
        self.show_gradient = True
        self.queue_draw()

    def disable_gradient(self):
        self.show_gradient = False
        self.queue_draw()

    def _on_draw(self, widget, cr):
        if not self.show_gradient:
            return
        # 1) Get widget size
        w = self.get_allocated_width()
        h = self.get_allocated_height()

        # -------------------
        #  RADIAL GRADIENT
        # -------------------
        if self.gradient_type == "radial":
            cx = w / 2.0
            cy = h / 2.0
            r_out = max(w, h) / 2.0
            pat = cairo.RadialGradient(cx, cy, 0.0, cx, cy, r_out)
            for off, r, g, b, a in self.color_points:
                pat.add_color_stop_rgba(off, r, g, b, a)

            # *** Missing in your original: set source and fill ***
            cr.set_source(pat)
            cr.rectangle(0.0, 0.0, w, h)
            cr.fill()

        # -------------------
        #  LINEAR GRADIENT
        # -------------------
        elif self.gradient_type == "linear":
            pat = cairo.LinearGradient(0.0, 0.0, float(w), 0.0)
            for off, r, g, b, a in self.color_points:
                pat.add_color_stop_rgba(off, r, g, b, a)

            cr.set_source(pat)
            cr.rectangle(0.0, 0.0, w, h)
            cr.fill()

        # -------------------
        #    ELLIPSE (SCALED RADIAL)
        # -------------------
        elif self.gradient_type == "elipse":
            cx = w / 2.0
            cy = h / 2.0
            # To get an ellipse that exactly fits width/height:
            #   – Build a unit‐radius circle gradient centered at (cx,cy)
            #   – Then scale Y or X so that circle → ellipse.
            # Here: scale Y by (h/2)/(w/2) = h/w, or equivalently scale X by w/h.
            # We want the circle’s radius = 1 in user space, then map that unit circle
            # to the rectangle of size (w×h) by scaling.
            # Two ways: scaleX = w/2, scaleY = h/2   BUT with a unit‐radius pattern:
            #    pat = RadialGradient(cx, cy, 0, cx, cy, 1)
            #    matrix = [ scaleX, 0; 0, scaleY; translate... ]
            # Let’s do that version:
            pat = cairo.RadialGradient(cx, cy, 0.0, cx, cy, h)
            for off, r, g, b, a in self.color_points:
                pat.add_color_stop_rgba(off, r, g, b, a)

            m = cairo.Matrix()
            # 1) translate pattern origin to (cx, cy)
            m.translate(cx, cy)
            # 2) scale unit circle → ellipse of radius (w/2, h/2)
            m.scale(0.3, (w / h) / 2)
            # 3) translate back
            m.translate(-cx, -cy)
            pat.set_matrix(m)

            cr.set_source(pat)
            cr.rectangle(0.0, 0.0, w, h)
            cr.fill()

        else:
            # If somehow gradient_type is invalid, just do nothing special.
            pass
