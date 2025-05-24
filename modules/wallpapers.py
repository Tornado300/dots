import os
from gi.repository import GdkPixbuf, Gtk, GLib
from fabric.widgets.box import Box
from fabric.widgets.entry import Entry
from fabric.widgets.scrolledwindow import ScrolledWindow
import hashlib
import json


class WallpaperSelector(Box):
    def __init__(self, wallpapers_dir: str, monitor_id=None, **kwargs):
        super().__init__(name="wallpapers", spacing=4, orientation="v", **kwargs)

        self.data = json.load(open("./data/data.json", "r"))

        self.wallpaper_cache_dir = self.data["cache_dir"] + "wallpapers/"
        self.monitor_id = monitor_id
        self.wallpapers_dir = wallpapers_dir
        os.makedirs(self.wallpaper_cache_dir, exist_ok=True)

        self.files = [
            f for f in os.listdir(wallpapers_dir) if self._is_image(f) and not f.split(".")[0].endswith(("_L", "_R"))
        ]
        self.thumbnails = []

        self.viewport = Gtk.IconView()
        self.viewport.set_model(Gtk.ListStore(GdkPixbuf.Pixbuf, str))
        self.viewport.set_pixbuf_column(0)
        self.viewport.set_text_column(1)
        self.viewport.set_item_width(0)
        self.viewport.connect("item-activated", self.on_wallpaper_selected)

        self.scrolled_window = ScrolledWindow(
            name="scrolled-window",
            spacing=10,
            h_expand=True,
            v_expand=True,
            child=self.viewport,
        )

        self.search_entry = Entry(
            name="search-entry",
            placeholder="Search Wallpapers...",
            h_expand=True,
            notify_text=lambda entry, *_: self.arrange_viewport(entry.get_text()),
        )
        self.search_entry.props.xalign = 0.5

        self.header_box = Box(
            name="header-box",
            spacing=10,
            orientation="h",
            children=[self.search_entry]
        )

        self.add(self.header_box)
        self.add(self.scrolled_window)

        self._start_thumbnail_thread()
        self.show_all()

    def close_selector(self):
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.close_notch()'")

    def arrange_viewport(self, query: str = ""):
        self.selected_wallpaper = 0
        self.viewport.get_model().clear()
        filtered_thumbnails = [
            (thumb, name)
            for thumb, name in self.thumbnails
            if query.casefold() in name.casefold()
        ]

        filtered_thumbnails.sort(key=lambda x: x[1].lower())

        for pixbuf, file_name in filtered_thumbnails:
            self.viewport.get_model().append([pixbuf, file_name])

    def on_wallpaper_selected(self, iconview, path):
        model = iconview.get_model()
        file_name = model[path][1]
        for pic in self.files:
            if pic.startswith(file_name):
                file_name = pic
        # check if multi-image wallpaper
        full_path = os.path.join(self.wallpapers_dir, file_name.replace(".", "$#!#$"))
        if os.path.exists(full_path.replace("$#!#$", "_L.")) and os.path.exists(full_path.replace("$#!#$", "_R.")):
            GLib.spawn_command_line_async(f"swww img -o DP-1 {full_path.replace("$#!#$", "_L.")}")
            GLib.spawn_command_line_async(f"swww img -o DP-3 {full_path.replace("$#!#$", "_R.")}")
        else:
            full_path = os.path.join(self.wallpapers_dir, file_name)
            GLib.spawn_command_line_async(f"swww img {full_path}")

    def _start_thumbnail_thread(self):
        """Inicia un hilo GLib para precargar las miniaturas."""
        GLib.Thread.new("thumbnail-loader", self._preload_thumbnails, None)

    def _preload_thumbnails(self, _data):
        """Carga miniaturas en segundo plano y las añade a la vista."""
        for file_name in sorted(self.files):
            full_path = os.path.join(self.wallpapers_dir, file_name)
            cache_path = self._get_cache_path(file_name)

            if not os.path.exists(cache_path):
                pixbuf = self._create_thumbnail(full_path)
                if pixbuf:
                    pixbuf.savev(cache_path, "png", [], [])
            else:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(cache_path)

            if pixbuf:
                GLib.idle_add(self._add_thumbnail_to_view, pixbuf, file_name)

    def _add_thumbnail_to_view(self, pixbuf, file_name):
        self.thumbnails.append((pixbuf, file_name))
        self.viewport.get_model().append([pixbuf, file_name.split(".")[0]])
        return False

    def _create_thumbnail(self, image_path: str, thumbnail_size=96):
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file(image_path)
            width, height = pixbuf.get_width(), pixbuf.get_height()
            if width > height:
                new_width = thumbnail_size
                new_height = int(height * (thumbnail_size / width))
            else:
                new_height = thumbnail_size
                new_width = int(width * (thumbnail_size / height))
            return pixbuf.scale_simple(new_width, new_height, GdkPixbuf.InterpType.BILINEAR)
        except Exception as e:
            print(f"Error creating thumbnail for {image_path}: {e}")
            return None

    def _get_cache_path(self, file_name: str) -> str:
        file_hash = hashlib.md5(file_name.encode("utf-8")).hexdigest()
        return os.path.join(self.wallpaper_cache_dir, f"{file_hash}.png")

    @staticmethod
    def _is_image(file_name: str) -> bool:
        return file_name.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif', '.webp'))

    def open(self):
        self.search_entry.set_text("")
        self.search_entry.grab_focus()
        GLib.timeout_add(
            500,
            lambda: (
                self.viewport.show(),
                self.viewport.set_property("name", "wallpaper-icons")
            )
        )

    def on_close(self):
        self.viewport.hide()
        self.viewport.set_property("name", None)
