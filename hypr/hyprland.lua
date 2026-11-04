WORKSPACE_PROGRAMS = {
    ["12"] = { "vesktop" },
    ["13"] = { "spotify" },
}

-- standard
hl.monitor({ output = "DP-1", mode = "1920x1080", position = "-1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080", position = "1x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", disabled = true })

-- one screen mode
-- hl.monitor({ output = "DP-3", mode = "3840x1080", position = "0x0", scale = 1 })

-- tv
-- hl.monitor({ output = "HDMI", mode = "1920x1080", position = "1x0", scale = 1 })

hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon && awww restore")
    hl.exec_cmd("source ~/.config/fabric/.venv/bin/activate && python ~/.config/fabric/main.py")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("xava -p ~/.config/xava/config_left")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("ie-r")
    -- hypridle DISABLED 2026-09-14: the first Wayland dpms cycle on this nvidia 615 + DP
    -- setup wedged the compositor (primary frozen, secondary black, hard reset needed).
    -- Re-enable only after a supervised dpms off/on test passes. Config kept in hypridle.conf.
    -- hl.exec_cmd("hypridle")
end)

hl.on("workspace.created", function(ws)
    if ws.is_empty then return end

    local program = WORKSPACE_PROGRAMS[ws.name]
    if program == nil then return end

    local cmd, rules = table.unpack(program)
    local rules2 = {}
    for k, v in rules do
        rules2[k] = v
    end
    rules2.workspace = ws.name .. " silent"
    hl.exec_cmd(cmd, rules2)
end)

require("env_vars")
require("animations")
require("window_rules")
require("layer_rules")
require("workspace_rules")
require("binds")

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
