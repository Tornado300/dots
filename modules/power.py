from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from gi.repository import GLib
from modules.icons import icon


class PowerMenu(Box):
    def __init__(self, monitor_id=None, **kwargs):
        super().__init__(
            name="power-menu",
            orientation="h",
            spacing=0,
            v_align="center",
            h_align="center",
            v_expand=True,
            h_expand=True,
            visible=True,
            **kwargs,
        )

        self.monitor_id = monitor_id

        self.btn_lock = Button(
            name="power-menu-button-lock",
            style_classes=["power-menu-button"],
            child=Label(name="button-label", markup=icon("lock")),
            on_clicked=self.lock,
        )

        self.btn_suspend = Button(
            name="power-menu-button-suspend",
            style_classes=["power-menu-button"],
            child=Label(name="button-label", markup=icon("suspend")),
            on_clicked=self.suspend,
        )

        self.btn_logout = Button(
            name="power-menu-button-logout",
            style_classes=["power-menu-button"],
            child=Label(name="button-label", markup=icon("logout")),
            on_clicked=self.logout,
        )

        self.btn_reboot = Button(
            name="power-menu-button-reboot",
            style_classes=["power-menu-button"],
            child=Label(name="button-label", markup=icon("reboot")),
            on_clicked=self.reboot,
        )

        self.btn_shutdown = Button(
            name="power-menu-button-shutdown",
            style_classes=["power-menu-button"],
            child=Label(name="button-label", markup=icon("shutdown")),
            on_clicked=self.poweroff,
        )

        self.buttons = [
            self.btn_shutdown,
            self.btn_logout,
            self.btn_reboot,
        ]

        for button in self.buttons:
            self.add(button)
        self.show_all()

    def close_menu(self):
        GLib.spawn_command_line_async(f"fabric-cli exec main-ui 'notch{self.monitor_id}.close_notch()'")

    def open(self):
        self.btn_shutdown.grab_focus()

    def lock(self, *args):
        print("Locking screen...")
        GLib.spawn_command_line_async("loginctl lock-session")
        self.close_menu()

    def suspend(self, *args):
        print("Suspending system...")
        GLib.spawn_command_line_async("systemctl suspend")
        self.close_menu()

    def logout(self, *args):
        print("Logging out...")
        GLib.spawn_command_line_async("hyprctl dispatch exit")
        self.close_menu()

    def reboot(self, *args):
        print("Rebooting system...")
        GLib.spawn_command_line_async("systemctl reboot")
        self.close_menu()

    def poweroff(self, *args):
        print("Powering off...")
        GLib.spawn_command_line_async("systemctl poweroff")
        self.close_menu()
