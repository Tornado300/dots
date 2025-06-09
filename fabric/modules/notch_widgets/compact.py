from widgets.gradient_button import GradientButton
import json
from fabric.widgets.box import Box
# from fabric.widgets.button import Button
from gi.repository import GLib
from services.mpris import MprisPlayer, MprisPlayerManager
import gi
gi.require_version('Gio', '2.0')


class Compact(Box):
    def __init__(self):
        with open("./data/data.json", "r+") as file:
            self.data = json.load(file)

        self._manager = MprisPlayerManager()
        self._player = None

        # If Spotify is already running when we instantiate, pick it up now:
        for bus_name in self._manager.players:
            self._player = MprisPlayer(bus_name)
            if self._player.player_name.lower() == "spotify":
                self._player.connect("changed", self._on_player_status_changed)
                break

        # Watch for any new MPRIS players appearing/disappearing
        self._manager.connect("player-appeared", self._on_player_appeared)
        self._manager.connect("player-vanished", self._on_player_vanished)

        GLib.timeout_add(200, lambda: None)
        # GLib.main_iteration_do(False)

        self.title, self.artist, cover = self.get_current_track()

        if self.title is None and self.artist is None:
            super().__init__(
                name="compact",
                h_expand=True,
                v_expand=True,
                children=[
                    GradientButton(
                        name="compact-button",
                        h_expand=True,
                        v_expand=True,
                        label=f"{self.data["username"]}@{self.data["hostname"]}",
                        on_clicked=lambda *_: GLib.spawn_command_line_async("fabric-cli exec main-ui 'controller.open(\"dashboard\")'")
                    )
                ]
            )
            self.add_style_class("static")
        else:
            super().__init__(
                name="compact",
                h_expand=True,
                v_expand=True,
                children=[
                    GradientButton(
                        name="compact-button",
                        color_points=[(0, 0, 0, 0, 0), (0.2, 0, 1, 0, 0), (0.8, 0, 1, 0, 0), (1, 0, 1, 0, 0)],
                        gradient_type="linear",
                        h_expand=True,
                        v_expand=True,
                        label=f"{self.title} - {self.artist}",
                        on_clicked=lambda *_: GLib.spawn_command_line_async("fabric-cli exec main-ui 'controller.open(\"dashboard\")'")
                    )
                ]
            )

    def _on_player_appeared(self, manager, bus_name):
        # If it's Spotify and we don't already have a reference, grab it
        temp = MprisPlayer(bus_name)
        if temp.player_name.lower() == "spotify":
            self._player = temp
            self._player.connect("changed", self._on_player_status_changed)

    def _on_player_vanished(self, manager, bus_name):
        # If the vanished player was our Spotify instance, drop it
        if self._player and self._player.player_name.lower() == "spotify":
            self._player = None
            self.children[0].set_label(f"{self.data["username"]}@{self.data["hostname"]}")
            self.add_style_class("static")

    def _on_player_status_changed(self, player):
        if player.playback_status == "playing":
            self.remove_style_class("static")
            self.add_style_class("playing")
            self.title, self.artist, cover = self.get_current_track()
            self.children[0].set_label(f"{self.title} - {self.artist}")
        else:
            self.remove_style_class("playing")

    def get_current_track(self):
        if not self._player:
            return None, None, None

        # MprisPlayer.title is usually a string (or None)
        title = self._player.title if self._player.title else None

        # MprisPlayer.artist is often a list; pick the first element if present
        artist = None
        if getattr(self._player, "artist", None):
            # Some wrappers store artist as a tuple/list; adjust as needed
            a = self._player.artist
            if isinstance(a, (list, tuple)) and len(a) > 0:
                artist = a[0]
            elif isinstance(a, str):
                artist = a

        # Many MprisPlayer wrappers provide an attribute for cover art URL.
        # If yours is called `art_url` or something else, tweak accordingly.
        art_url = getattr(self._player, "art_url", None)

        return title, artist, art_url
