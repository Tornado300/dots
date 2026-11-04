hl.bind("SUPER + ALT + F", hl.dsp.exec_cmd("pkill main-ui"))
hl.bind("SUPER + CTRL + F", hl.dsp.exec_cmd("pkill needle-launcher"))

Terminal = 'kitty --hold zsh -c "fastfetch; echo; echo; echo; echo;"'
hl.bind("SUPER + Q", hl.dsp.exec_cmd(Terminal))
hl.bind("SUPER + X", hl.dsp.window.close())
hl.bind("SUPER + V", hl.dsp.window.float())
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
