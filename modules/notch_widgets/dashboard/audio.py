from fabric.widgets.label import Label
from fabric.widgets.box import Box
from fabric.widgets.scale import Scale
from widgets.dropdown import Dropdown
from fabric.audio import Audio
from gi.repository import GLib
import json


class AudioModule(Box):
    def __init__(self):
        super().__init__(
            name="dashboard-segment-audio",
            style_classes=["dashboard"],
            v_expand=True,
            h_expand=True,
            orientation="v",
        )

        self.input_slider = Scale(
            name="dashboard-audio-input-slider",
            style_classes=["audio-slider"],
            min_value=0,
            max_value=200,
            value=50,
            draw_value=True,
            h_expand=True,
            all_visible=True,
            value_position="right",
            digits=0
        )
        self.input_slider.connect("value-changed", self.slider_changed)
        self.input_slider.connect("format-value", self.format_slider_value)

        self.output_slider = Scale(
            name="dashboard-audio-output-slider",
            style_classes=["audio-slider"],
            min_value=0,
            max_value=200,
            value=50,
            draw_value=True,
            h_expand=True,
            all_visible=True,
            value_position="right",
            digits=0
        )
        self.output_slider.connect("value-changed", self.slider_changed)
        self.output_slider.connect("format-value", self.format_slider_value)

        self.input_dropdown = Dropdown(name="dashboard-audio-input-dropdown", placeholder="Select Input Device")
        self.output_dropdown = Dropdown(name="dashboard-audio-output-dropdown", placeholder="Select Output Device")

        self.vertical_split = Box(
            orientation="h",
            spacing=5,
            children=[
                Box(
                    name="dashboard-audio-input-box",
                    v_align="start",
                    orientation="v",
                    h_expand=True,
                    spacing=7,
                    children=[
                        Label(h_align="start", label="Input:"),
                        self.input_slider,
                        self.input_dropdown
                    ],
                ),
                Box(
                    name="dashboard-audio-output-box",
                    v_align="start",
                    orientation="v",
                    h_expand=True,
                    spacing=7,
                    children=[
                        Label(h_align="start", label="Output:"),
                        self.output_slider,
                        self.output_dropdown
                    ],
                )
            ]
        )

        self.speakers = []
        self.microphones = []
        self.slider_active = False

        self.audio = Audio(200, "fabric audio control")
        self.audio.connect("changed", self.audio_change)
        self.audio.connect("speaker_changed", self.speaker_changed)
        self.audio.connect("microphone_changed", self.microphone_changed)

        self.add(Label(label="Audio", h_align="center", v_align="start"))  # Module Heading
        self.add(self.vertical_split)

    def slider_changed(self, value):
        self.slider_active = True
        if "input" in value.get_name():
            GLib.spawn_command_line_async(f"pactl set-source-volume @DEFAULT_SOURCE@ {value.value}%")
        elif "output" in value.get_name():
            GLib.spawn_command_line_async(f"pactl set-sink-volume @DEFAULT_SINK@ {value.value}%")

    def format_slider_value(self, scale, value):
        return f"{int(value)}%"

    def speaker_changed(self, v):
        if self.slider_active:
            return
        self.output_dropdown.set_current_selection(self.resolve_device_name(v.speaker.name))

    def microphone_changed(self, v):
        if self.slider_active:
            return
        self.input_dropdown.set_current_selection(self.resolve_device_name(v.microphone.name))

    def update_slider(self):
        self.input_slider.value = round(self.audio.microphone.volume)
        self.output_slider.value = round(self.audio.speaker.volume)

    def audio_change(self, audio):
        # look for added or removed speakers since last update
        removed_speakers = list(set(self.speakers) - set(audio.speakers))
        added_speakers = list(set(audio.speakers) - set(self.speakers))

        removed_microphones = list(set(self.microphones) - set(audio.microphones))
        added_microphones = list(set(audio.microphones) - set(self.microphones))

        with open("./data/audio.json", "r+") as file:
            self.data = json.load(file)
            # init json lists
            if "speakers" not in self.data["device_name_mapping"]:
                self.data["device_name_mapping"]["speakers"] = {}
            if "microphones" not in self.data["device_name_mapping"]:
                self.data["device_name_mapping"]["microphones"] = {}

            if "speakers" not in self.data["excluded_devices"]:
                self.data["excluded_devices"]["speakers"] = []
            if "microphones" not in self.data["excluded_devices"]:
                self.data["excluded_devices"]["microphones"] = []

            # map speaker name to custom name or register speaker if not done before
            for speaker in added_speakers:
                if speaker.name not in self.data["excluded_devices"]["speakers"]:
                    speaker_name = self.resolve_device_name(speaker.name)
                    self.speakers.append(speaker)
                    self.output_dropdown.add_new_element(label=speaker_name, callback=lambda: self.set_device_as_default(speaker.name))

            # map microphone name to custom name or register microphone if not done before
            for microphone in added_microphones:
                if microphone.name not in self.data["excluded_devices"]["microphones"]:
                    microphone_name = self.resolve_device_name(microphone.name)
                    self.microphones.append(microphone)
                    self.input_dropdown.add_new_element(label=microphone_name, callback=lambda: self.set_device_as_default(microphone.name))

            # write updated data to data.json
            file.seek(0)
            json.dump(self.data, file, indent=2)
            file.truncate()

        removed_buttons = []
        for speaker in removed_speakers:
            self.speakers.remove(speaker)
            removed_buttons.append(self.resolve_device_name(speaker.name))
        for microphone in removed_microphones:
            self.microphones.remove(microphone)
            removed_buttons.append(self.resolve_device_name(microphone.name))
        for speaker_button in self.output_dropdown.get_elements():
            if speaker_button.get_label() in removed_buttons:
                self.output_dropdown.remove_element(speaker_button)
        for microphone_button in self.input_dropdown.get_elements():
            if microphone_button.get_label() in removed_buttons:
                self.input_dropdown.remove_element(microphone_button)

    def set_device_as_default(self, id):
        if "alsa_input" in id:
            GLib.spawn_command_line_async(f"pactl set-default-source {id}")
        elif "alsa_output" in id:
            GLib.spawn_command_line_async(f"pactl set-default-sink {id}")
        else:
            print("!!! wrong device id/name:", id)

    def resolve_device_name(self, name):
        if "alsa_input" in name:
            if name not in self.data["device_name_mapping"]["microphones"]:
                self.data["device_name_mapping"]["microphones"][name] = name
                return name
            else:
                return self.data["device_name_mapping"]["microphones"][name]

        elif "alsa_output" in name:
            if name not in self.data["device_name_mapping"]["speakers"]:
                self.data["device_name_mapping"]["speakers"][name] = name
                return name
            else:
                return self.data["device_name_mapping"]["speakers"][name]

        else:
            print("!!! wrong device name:", name)
