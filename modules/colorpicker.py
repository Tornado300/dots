from fabric.widgets.box import Box
from fabric.widgets.label import Label
from gi.repository import GLib
import subprocess
import colorsys
import threading
import time


class Colorpicker(Box):
    def __init__(self, monitor_id, **kwargs):
        self.monitor_id = monitor_id
        self.hex = "?"
        self.rgb = "?"
        self.hsv = "?"
        super().__init__(
            name="colorpicker",
            orientation="v",
            visible=True,
            all_visible=True,
            **kwargs
        )
        self.hex_box = Box(
            name="colorpicker-hex-box",
            orientation="v",
            children=[
                Label(name="colorpicker-hex-label", label="HEX:", h_align="start"),
                Label(name="colorpicker-hex-value", label="", h_align="start")
            ]
        )
        self.rgb_box = Box(
            name="colorpicker-rgb-box",
            orientation="v",
            children=[
                Label(name="colorpicker-hex-label", label="RGB:", h_align="start"),
                Label(name="colorpicker-rgb-value", label="", h_align="start")
            ]
        )
        self.hsv_box = Box(
            name="colorpicker-hsv-box",
            orientation="v",
            children=[
                Label(name="colorpicker-hex-label", label="HSV:", h_align="start"),
                Label(name="colorpicker-hsv-value", label="", h_align="start")
            ]

        )
        self.add(self.hex_box)
        self.add(self.rgb_box)
        self.add(self.hsv_box)

    def close_dashboard(self):
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.close_notch()'")

    def exec_hyprpicker(self):
        time.sleep(0.3)
        self.process = subprocess.Popen(
            'hyprpicker -n -f rgb | grep -E "[0-9]{1,3} [0-9]{1,3} [0-9]{1,3}"',
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        # Read output line-by-line
        for line in self.process.stdout:
            r, g, b = line.split(" ")

        self.rgb = f"{r},{g},{b}".replace("\n", "")
        self.hex = f"#{int(r):02x}{int(g):02x}{int(b):02x}"
        h, s, v = colorsys.rgb_to_hsv(int(r) / 255, int(g) / 255, int(b) / 255)
        self.hsv = (round(h * 360, 3), round(s * 100, 2), round(v * 100, 2))

        self.hex_box.children[1].set_label(str(self.hex))
        self.rgb_box.children[1].set_label(str(self.rgb))
        self.hsv_box.children[1].set_label(str(self.hsv))

    def open(self):
        self.hex_box.children[1].set_label("")
        self.rgb_box.children[1].set_label("")
        self.hsv_box.children[1].set_label("")

        picker_thread = threading.Thread(target=self.exec_hyprpicker)

        picker_thread.start()
