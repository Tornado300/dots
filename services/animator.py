from typing import cast
from fabric import Service, Signal, Property
from gi.repository import GLib, Gtk


class UnitBezier:
    """
    Solves a full CSS-style cubic-bezier(x1,y1, x2,y2).
    Given t in [0,1], finds the corresponding y value
    by first inverting x(t') = t via Newton-Raphson.
    """

    def __init__(self, x1: float, y1: float, x2: float, y2: float):
        self.cx = 3.0 * x1
        self.bx = 3.0 * (x2 - x1) - self.cx
        self.ax = 1.0 - self.cx - self.bx

        self.cy = 3.0 * y1
        self.by = 3.0 * (y2 - y1) - self.cy
        self.ay = 1.0 - self.cy - self.by

    def sample_x(self, t: float) -> float:
        return ((self.ax * t + self.bx) * t + self.cx) * t

    def sample_y(self, t: float) -> float:
        return ((self.ay * t + self.by) * t + self.cy) * t

    def sample_x_derivative(self, t: float) -> float:
        return (3.0 * self.ax * t + 2.0 * self.bx) * t + self.cx

    def solve(self, x: float, epsilon: float = 1e-6) -> float:
        t = x
        for _ in range(8):
            x_t = self.sample_x(t) - x
            dx = self.sample_x_derivative(t)
            if abs(x_t) < epsilon or dx == 0.0:
                break
            t -= x_t / dx
            t = max(0.0, min(1.0, t))
        return self.sample_y(t)


class Animator(Service):
    @Signal
    def finished(self) -> None: ...

    @Property(tuple[float, float, float, float], "read-write")
    def bezier_curve(self) -> tuple[float, float, float, float]:
        return self._bezier_curve

    @bezier_curve.setter
    def bezier_curve(self, value: tuple[float, float, float, float]):
        # Directly set private field to avoid recursion
        self._bezier_curve = value
        x1, y1, x2, y2 = value
        self._unit_bezier = UnitBezier(x1, y1, x2, y2)

    @Property(float, "read-write")
    def value(self):
        return self._value

    @value.setter
    def value(self, v: float):
        self._value = v

    @Property(float, "read-write")
    def max_value(self):
        return self._max_value

    @max_value.setter
    def max_value(self, v: float):
        self._max_value = v

    @Property(float, "read-write")
    def min_value(self):
        return self._min_value

    @min_value.setter
    def min_value(self, v: float):
        self._min_value = v

    @Property(bool, "read-write", default_value=False)
    def playing(self):
        return self._playing

    @playing.setter
    def playing(self, v: bool):
        self._playing = v

    @Property(bool, "read-write", default_value=False)
    def repeat(self):
        return self._repeat

    @repeat.setter
    def repeat(self, v: bool):
        self._repeat = v

    @Property(float, "read-write")
    def duration(self):
        return self._duration

    @duration.setter
    def duration(self, v: float):
        # print(v)
        self._duration = v

    def __init__(
        self,
        bezier_curve: tuple[float, float, float, float],
        duration: float,
        min_value: float = 0.0,
        max_value: float = 1.0,
        repeat: bool = False,
        tick_widget: Gtk.Widget | None = None,
        **kwargs,
    ):
        super().__init__(**kwargs)
        self._bezier_curve = bezier_curve
        self._unit_bezier = UnitBezier(*bezier_curve)
        self._duration = duration
        self._value = min_value
        self._min_value = min_value
        self._max_value = max_value
        self._repeat = repeat

        self._playing = False
        self._start_time = None
        self._tick_handler = None
        self._timeline_pos = 0.0
        self._tick_widget = tick_widget

    def do_get_time_now(self) -> float:
        return GLib.get_monotonic_time() / 1_000_000

    def do_lerp(self, start: float, end: float, t: float) -> float:
        return start + (end - start) * t

    def do_interpolate_cubic_bezier(self, time: float) -> float:
        # Full CSS-style easing: invert x->t then compute y
        return self._unit_bezier.solve(time)

    def do_ease(self, time: float) -> float:
        eased = self.do_interpolate_cubic_bezier(time)
        return self.do_lerp(self._min_value, self._max_value, eased)

    def do_update_value(self, current_time: float):
        if not self.playing:
            return

        elapsed = current_time - cast(float, self._start_time)
        self._timeline_pos = min(1.0, elapsed / self._duration)
        self.value = self.do_ease(self._timeline_pos)

        if self._timeline_pos >= 1.0:
            if not self.repeat:
                self.value = self.max_value
                self.finished()
                self.pause()
            else:
                self._start_time = current_time
                self._timeline_pos = 0.0

    def do_handle_tick(self, *_):
        # Stop callback if no longer playing
        if not self.playing:
            return False
        now = self.do_get_time_now()
        self.do_update_value(now)
        return True

    def do_remove_tick_handlers(self):
        if self._tick_handler:
            if self._tick_widget:
                self._tick_widget.remove_tick_callback(self._tick_handler)
            else:
                GLib.source_remove(self._tick_handler)
        self._tick_handler = None

    def play(self):
        if self.playing:
            return
        self._start_time = self.do_get_time_now()
        self.playing = True
        if not self._tick_handler:
            if self._tick_widget:
                self._tick_handler = self._tick_widget.add_tick_callback(self.do_handle_tick)
            else:
                self._tick_handler = GLib.timeout_add(16, self.do_handle_tick)

    def pause(self):
        self.playing = False
        self.do_remove_tick_handlers()

    def stop(self):
        if not self._tick_handler:
            self._timeline_pos = 0.0
            self.playing = False
            return
        self.do_remove_tick_handlers()
