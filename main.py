from modules.controller import Controller
from modules.notch import Notch
from modules.bar import Bar
from fabric import Application
from fabric.notifications.service import Notifications
from fabric.utils import get_relative_path
import os
import json
from gi.repository import Gray
import setproctitle
import gi
gi.require_version('Gray', '0.1')


if __name__ == "__main__":

    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    with open("./data/data.json", "r") as file:
        try:
            data = json.load(file)
        except json.decoder.JSONDecodeError:
            data = {"username": None, "hostname": None, "home_dir": None, "wallpapers_dir": None, "cache_dir": None}

    with open("./data/project_manager.json") as file:
        try:
            manager_data = json.load(file)
        except json.decoder.JSONDecodeError:
            manager_data = {}

    with open("./data/audio.json") as file:
        try:
            audio_data = json.load(file)
        except json.decoder.JSONDecodeError:
            audio_data = {}

    with open("./data/launcher.json") as file:
        try:
            launcher_data = json.load(file)
        except json.decoder.JSONDecodeError:
            launcher_data = {}

    data["username"] = os.getlogin()
    data["hostname"] = os.uname().nodename
    data["home_dir"] = os.path.expanduser("~/")
    data["wallpapers_dir"] = os.path.expanduser("~/.backgrounds/")
    data["cache_dir"] = os.path.expanduser("~/.cache/desktop_ui/")

    with open("./data/data.json", "w") as file:
        json.dump(data, file, indent=2)

    with open("./data/audio.json", "w") as file:
        json.dump(audio_data, file, indent=2)

    with open("./data/launcher.json", "w") as file:
        json.dump(launcher_data, file, indent=2)

    with open("./data/project_manager.json", "w") as file:
        json.dump(manager_data, file, indent=2)

    setproctitle.setproctitle("main-ui")
    notification_server = Notifications()
    sys_tray_server = Gray.Watcher()
    bar0 = Bar(monitor_id=0, server=sys_tray_server)
    bar1 = Bar(monitor_id=1, server=sys_tray_server)
    notch0 = Notch(monitor_id=0, server=notification_server)
    notch1 = Notch(monitor_id=1, server=notification_server)
    controller = Controller()
    app = Application("main-ui", bar0, bar1, notch0, notch1, controller, open_inspector=True)
    app.set_stylesheet_from_file(get_relative_path("main.css"))
    app.run()
