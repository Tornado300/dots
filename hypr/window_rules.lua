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
