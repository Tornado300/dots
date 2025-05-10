from gi.repository import Gray, Gtk, Gdk, GdkPixbuf, GLib
import gi
gi.require_version("Gray", "0.1")


class SystemTray(Gtk.Box):
    def __init__(self, server, pixel_size: int = 20, **kwargs) -> None:
        super().__init__(name="systray", orientation=Gtk.Orientation.HORIZONTAL, spacing=8, **kwargs)
        self.pixel_size = pixel_size
        self.watcher = server
        self.watcher.connect("item-added", self.on_item_added)

    def on_item_added(self, _, identifier: str):
        item = self.watcher.get_item_for_identifier(identifier)
        item_button = self.do_bake_item_button(item)
        item.connect("removed", lambda *args: item_button.destroy())
        item_button.show_all()
        self.add(item_button)

    def do_bake_item_button(self, item: Gray.Item) -> Gtk.Button:
        button = Gtk.Button()

        button.connect(
            "button-press-event",
            lambda button, event: self.on_button_click(button, item, event),
        )

        # Obtiene el pixmap del ícono
        pixmap = Gray.get_pixmap_for_pixmaps(item.get_icon_pixmaps(), self.pixel_size)

        try:
            # Convierte el pixmap en pixbuf o carga un ícono por defecto si no hay pixmap
            if pixmap is not None:
                pixbuf = pixmap.as_pixbuf(self.pixel_size, GdkPixbuf.InterpType.HYPER)
            else:
                pixbuf = Gtk.IconTheme().load_icon(
                    item.get_icon_name(),
                    self.pixel_size,
                    Gtk.IconLookupFlags.FORCE_SIZE,
                )
        except GLib.Error:
            # Si no encuentra el ícono, usa un ícono por defecto
            pixbuf = Gtk.IconTheme().get_default().load_icon(
                "image-missing",
                self.pixel_size,
                Gtk.IconLookupFlags.FORCE_SIZE,
            )

        # Asigna la imagen al botón
        button.set_image(Gtk.Image.new_from_pixbuf(pixbuf))
        return button

    def on_button_click(self, button, item: Gray.Item, event):
        if event.button == Gdk.BUTTON_PRIMARY:
            try:
                item.activate(event.x, event.y)
            except Exception as e:
                print(f"Error failed to activate tray item: {e}")
        elif event.button == Gdk.BUTTON_SECONDARY:
            menu = item.get_menu()
            menu.connect("popped-up", self.on_popped_up)
            # menu.set_monitor(Gdk.Display.get_monitor_at_window(button.get_display(), button.get_window()))
            if menu:
                menu.set_name("system-tray-menu")
                alloc = button.get_allocation()

                rect = Gdk.Rectangle()
                rect.x = alloc.x
                rect.y = alloc.y + 35
                rect.width = 1
                rect.height = 1

                # menu.popup(None, None, self.position_menu, button, event.button, event.time)
                # menu.attach_to_widget(button, None)

                menu.popup_at_rect(
                    button.get_window(),
                    rect,
                    Gdk.Gravity.SOUTH,
                    Gdk.Gravity.NORTH,
                    event,
                )

                # print(menu.get_window().get_origin())

            else:
                item.context_menu(event.x, event.y)

    def on_popped_up(menu, final_rect, flipped_rect, flipped_x, flipped_y, a):
        pass

    def position_menu(systray, menu, x, y, button):
        # print(systray, menu, x, y, button)
        # Retrieve the widget and its associated window
        window = button.get_window()

        # Get the monitor at the widget's window
        display = Gdk.Display.get_default()
        print(display)
        monitor = display.get_monitor_at_window(window)
        print(monitor)

        # Obtain the monitor's geometry
        monitor_geometry = monitor.get_geometry()
        print(monitor_geometry.x, monitor_geometry.y)

        # Calculate desired position (example: top-left corner of the monitor)
        x = monitor_geometry.x + 1920
        y = monitor_geometry.y

        # Return the calculated position
        return x, y, True
