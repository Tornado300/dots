import setproctitle
import gi
gi.require_version('Gray', '0.1')
from gi.repository import Gray
import json
import os

from fabric.utils import get_relative_path
from fabric.notifications.service import Notifications
from fabric import Application
from modules.bar import Bar
from modules.notch import Notch
from modules.controller import Controller

if __name__ == "__main__":

    os.chdir( os.path.dirname(os.path.abspath(__file__)))

    with open("./data.json", "r") as file:
        try:
            data = json.load(file)
        except json.decoder.JSONDecodeError:
            data = {"username": None, "hostname": None, "home_dir": None, "wallpapers_dir": None, "cache_dir": None}



    data["username"] = os.getlogin()
    data["hostname"] = os.uname().nodename
    data["home_dir"] = os.path.expanduser("~/")
    data["wallpapers_dir"] = os.path.expanduser("~/.backgrounds/")
    data["cache_dir"] = os.path.expanduser("~/.cache/desktop_ui/")


    if "device_name_mapping" not in data:
        data["device_name_mapping"] = {}
    if "excluded_devices" not in data:
        data["excluded_devices"] = {}



    with open("./data.json", "w") as file:
        json.dump(data, file, indent=2)

    setproctitle.setproctitle(f"main-ui")
    notification_server = Notifications()
    sys_tray_server = Gray.Watcher()
    bar0 = Bar(monitor_id=0, server=sys_tray_server)
    bar1 = Bar(monitor_id=1, server=sys_tray_server)
    notch0 = Notch(monitor_id=0, server=notification_server)
    notch1 = Notch(monitor_id=1, server=notification_server)
    controller = Controller()
    app = Application(f"main-ui", bar0, bar1, notch0, notch1, controller, open_inspector=True)
    app.set_stylesheet_from_file(get_relative_path("main.css"))
    app.run()
