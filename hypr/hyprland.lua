-- standard
hl.monitor({ output = "DP-1", mode = "1920x1080", position = "-1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080", position = "1x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", disabled = true })

-- one screen mode
-- hl.monitor({ output = "DP-3", mode = "3840x1080", position = "0x0", scale = 1 })

hl.on("hyprland.start", function()
	hl.exec_cmd("awww-daemon && awww restore")
	hl.exec_cmd("source ~/.config/fabric/.venv/bin/activate && python ~/.config/fabric/main.py")
	hl.exec_cmd("dbus-update-activation-enviroment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("sleep 4 && systemctl --user start xdg-desktop-portal-hyprland && sleep 1 && systemctl --user restart xdg-desktop-portal")
	hl.exec_cmd("xava -p ~/.config/xava/config_left")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("ie-r")
end)

Terminal = 'kitty --hold zsh -c "fastfetch; echo; echo; echo; echo;"'

hl.env("XVURSOR_SIZE", 24)
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("WLR_DRM_DEVICES", "/home/tornado300/.config/hypr/card")

hl.env("GTK_THEME", "PurPurNight")
hl.env("GTK_USE_PORTAL", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("GNUPGHOME", os.getenv("HOME") .. "/.local/share/gnupg")

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 1.5, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 0.1, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "default" })

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 15,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(ccff00ee)", "rgba(00ff00ee)" }, angle = 45 },
			inactive_border = { colors = { "rgba(ccff0022)", "rgba(00ff0022)" }, angle = 45 },
		},
	},

	decoration = {
		rounding = 10,
		dim_special = 0.3,
		blur = {
			size = 3,
			passes = 3,
			noise = 0,
			contrast = 1,
			brightness = 1,
		},
		shadow = {
			color = "rgba(1a1a1aee)",
		},
	},

	dwindle = {
		preserve_split = true,
	},

	cursor = {
		use_cpu_buffer = 1,
		inactive_timeout = 3,
	},

	input = {
		kb_layout = "de",
		repeat_rate = 25,
		repeat_delay = 300,
		follow_mouse = 1,
		sensitivity = -0.7,
	},
})

-- ### WINDOW RULES ### --
-- opacity --
hl.window_rule({ match = { class = ".*" }, opacity = "0.9 override 0.6 override" })

hl.window_rule({ match = { title = "^(.*Blender.*)$" }, tag = "+opaque" })
hl.window_rule({ match = { title = "^(.*mpv.*)$" }, tag = "+opaque" })
hl.window_rule({ match = { title = "^(.*steam_app.*)$" }, tag = "+opaque" })
hl.window_rule({ match = { title = "^(Spotify)$" }, tag = "+opaque" })
hl.window_rule({ match = { tag = "opaque" }, opaque = true })

-- custom window behaviour --
hl.window_rule({ match = { class = "^(.*org.rncbc.qpwgraph.*)$" }, workspace = "special:tray silent" })

hl.window_rule({ match = { title = "^(termfilechooser)$" }, float = true })

hl.window_rule({ match = { class = "^zen$" }, monitor = "DP-3" })

-- ### LAYER RULES ### --
hl.layer_rule({ match = { namespace = "fabric" }, blur = true })
hl.layer_rule({ match = { namespace = "fabric" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "fabric" }, no_anim = true })

hl.layer_rule({ match = { namespace = "selection" }, blur = false })

-- ### WORKSPACE RULE ### --
hl.workspace_rule({ workspace = "special:tray", persistent = true })

hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3" })
hl.workspace_rule({ workspace = "3", monitor = "DP-3" })
hl.workspace_rule({ workspace = "4", monitor = "DP-3" })
hl.workspace_rule({ workspace = "5", monitor = "DP-3" })
hl.workspace_rule({ workspace = "6", monitor = "DP-3" })
hl.workspace_rule({ workspace = "7", monitor = "DP-3" })
hl.workspace_rule({ workspace = "8", monitor = "DP-3" })
hl.workspace_rule({ workspace = "9", monitor = "DP-3" })
hl.workspace_rule({ workspace = "10", monitor = "DP-3" })

hl.workspace_rule({ workspace = "11", monitor = "DP-1" })
hl.workspace_rule({ workspace = "12", monitor = "DP-1" })
hl.workspace_rule({ workspace = "13", monitor = "DP-1" })
hl.workspace_rule({ workspace = "14", monitor = "DP-1" })
hl.workspace_rule({ workspace = "15", monitor = "DP-1" })
hl.workspace_rule({ workspace = "16", monitor = "DP-1" })
hl.workspace_rule({ workspace = "17", monitor = "DP-1" })
hl.workspace_rule({ workspace = "18", monitor = "DP-1" })
hl.workspace_rule({ workspace = "19", monitor = "DP-1" })
hl.workspace_rule({ workspace = "20", monitor = "DP-1" })

hl.workspace_rule({ workspace = "12", on_created_empty = "vesktop" })
hl.workspace_rule({ workspace = "13", on_created_empty = "spotify" })

-- ### BINDS ### --
hl.bind("SUPER + ALT + F", hl.dsp.exec_cmd("pkill main-ui"))
hl.bind("SUPER + CTRL + F", hl.dsp.exec_cmd("pkill needle-launcher"))

hl.bind("SUPER + Q", hl.dsp.exec_cmd(Terminal))
hl.bind("SUPER + X", hl.dsp.window.close("activewindow"))
hl.bind("SUPER + V", hl.dsp.window.float("toggle", "activewindow"))
hl.bind("SUPER + ALT + V", hl.dsp.window.pin("activewindow"))
hl.bind("SUPER + B", hl.dsp.layout("togglesplit"))
hl.bind("SUPER + code:95", hl.dsp.window.fullscreen({ "fullscreen", "toggle", "activewindow" }))
hl.bind("SUPER + M", hl.dsp.exec_cmd('fabric-cli exec main-ui "controller.toggle(\\"power\\")"'))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd('fabric-cli exec main-ui "controller.toggle(\\"launcher\\")"'))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd('fabric-cli exec main-ui "controller.toggle(\\"dashboard\\")"'), { long_press = true })

hl.bind("SUPER + PERIOD", hl.dsp.exec_cmd("pkill -SIGUSR1 ie-r"))
-- SongRec: identify currently playing system audio
hl.bind("SUPER + SHIFT + PERIOD", function()
	hl.notification.create({ text = "🎵 Listening for 8 seconds...", timeout = 2000 })
	hl.exec_cmd(
		'sh -c \'parec --device="$(pactl get-default-sink).monitor" --file-format=wav /tmp/songrec_snap.wav & '
			.. "PID=$! && sleep 8 && kill $PID && "
			.. "RESULT=$(songrec recognize /tmp/songrec_snap.wav 2>&1) && "
			.. 'notify-send SongRec "${RESULT:-No song detected}" && '
			.. "rm -f /tmp/songrec_snap.wav'"
	)
end)

hl.bind("SUPER + h", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + l", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + k", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + j", hl.dsp.focus({ direction = "d" }))

hl.bind("SUPER + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "r~1" }))
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "r~2" }))
hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "r~3" }))
hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "r~4" }))
hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "r~5" }))
hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "r~6" }))
hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "r~7" }))
hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "r~8" }))
hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "r~9" }))
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "r~10" }))

hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "r~1", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "r~2", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "r~3", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "r~4", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "r~5", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "r~6", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "r~7", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "r~8", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "r~9", follow = true, window = "activewindow" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "r~10", follow = true, window = "activewindow" }))

hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true, window = "activewindow" }))

hl.bind("SUPER + T", hl.dsp.window.move({ workspace = "special:tray", follow = false, window = "activewindow" }))
hl.bind("SUPER + SHIFT + T", hl.dsp.workspace.toggle_special("tray"))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag())
hl.bind("SUPER + mouse:273", hl.dsp.window.resize())

hl.bind("SUPER + ALT + l", hl.dsp.window.resize({ x = 20, y = 0, relative = true, window = "activewindow" }), { repeating = true })
hl.bind("SUPER + ALT + h", hl.dsp.window.resize({ x = -20, y = 0, relative = true, window = "activewindow" }), { repeating = true })
hl.bind("SUPER + ALT + k", hl.dsp.window.resize({ x = 0, y = -20, relative = true, window = "activewindow" }), { repeating = true })
hl.bind("SUPER + ALT + j", hl.dsp.window.resize({ x = 0, y = 20, relative = true, window = "activewindow" }), { repeating = true })

hl.bind("SUPER + CTRL + l", hl.dsp.window.move({ x = 20, y = 0, relative = true, window = "activewindow" }), { repeating = true })
hl.bind("SUPER + CTRL + h", hl.dsp.window.move({ x = -20, y = 0, relative = true, window = "activewindow" }), { repeating = true })
hl.bind("SUPER + CTRL + k", hl.dsp.window.move({ x = 0, y = -20, relative = true, window = "activewindow" }), { repeating = true })
hl.bind("SUPER + CTRL + j", hl.dsp.window.move({ x = 0, y = 20, relative = true, window = "activewindow" }), { repeating = true })

-- knob press
hl.bind("xf86audiomute", hl.dsp.exec_cmd("playerctl -p spotify play-pause"))
-- headphone press
hl.bind("xf86audioplay", hl.dsp.exec_cmd("playerctl -p spotify play-pause"))

-- knob left or headphone down
hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/spotify_volume.sh 2%-"))
-- hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd("playerctl -p spotify volume 0.02-"))
-- knob right or headphone up
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd("~/.config/hypr/scripts/spotify_volume.sh 2%+"))
-- hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd("playerctl -p spotify volume 0.02+"))

-- super + knob left
hl.bind("SUPER + xf86audiolowervolume", hl.dsp.exec_cmd("playerctl -p spotify previous"))
-- headphone left
hl.bind("xf86audioprev", hl.dsp.exec_cmd("playerctl -p spotify previous"))

-- super + knob right
hl.bind("SUPER + xf86audioraisevolume", hl.dsp.exec_cmd("playerctl -p spotify next"))
-- headphone right
hl.bind("xf86audionext", hl.dsp.exec_cmd("playerctl -p spotify next"))

hl.bind("SUPER + PRINT", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

hl.bind("SUPER + ALT + PRINT", hl.dsp.exec_cmd("~/.config/hypr/scripts/quick_recording.sh"))

hl.bind("SUPER + O", hl.dsp.window.tag({ tag = "opaque", window = "activewindow" }))

hl.bind("xf86tools", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"))

-- auto start --
hl.exec_cmd("qpwgraph -a")
