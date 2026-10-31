-- Look: square pixel frames, no blur or shadows, the theme's colours and
-- the CRT shader. Layout numbers follow the canvas (1920x1080): the bar
-- (Quickshell, Theme.barScale 0.75) ends at y 48, windows start at y 72 and
-- sit 24 px apart.

local s = require("station.state")

hl.config({
    general = {
        gaps_in     = 12,
        gaps_out    = 24,
        border_size = 2,
        col = {
            active_border   = s.color("frame"),
            inactive_border = s.color("border"),
        },
        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding         = 0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = false },
        blur   = { enabled = false },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = s.color("bg"),
        focus_on_activate        = true,
        key_press_enables_dpms   = true,
        mouse_move_enables_dpms  = true,
        allow_session_lock_restore = true,
    },

    cursor = { hide_on_key_press = true },

    ecosystem = { no_donation_nag = true },
})

-- The focused window gets the thick 3 px frame from the canvas
hl.window_rule({
    name  = "focus-frame",
    match = { focus = true },
    border_size = 3,
})

-- Every workspace on the laptop panel keeps the right column free for the
-- floating file manager and the desktop widgets, like on canvas board 01:
-- tiled windows end at x 1116, the column runs from 1140 to 1896. Super+G
-- makes one window big over it (binds.lua). Switch the column off on the
-- DESKTOP WIDGETS page of STATION SETUP (station desktop column off).
if s.desktop.column ~= "off" then
    hl.workspace_rule({
        workspace = "m[eDP-1]",
        gaps_out  = { top = 24, left = 24, bottom = 24, right = 804 },
    })
end

-- Short, linear animations. Nothing bounces on a CRT.
hl.curve("step", { type = "bezier", points = { {0.2, 0}, {0, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.animation({ leaf = "global",     enabled = true, speed = 3, bezier = "step" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2, bezier = "linear" })
hl.animation({ leaf = "border",     enabled = false, speed = 1, bezier = "linear" })
-- Windows appear and vanish at once: no pop-in and no fade when they open
-- or close (moving and resizing still animate)
hl.animation({ leaf = "windowsIn",  enabled = false, speed = 1, bezier = "linear" })
hl.animation({ leaf = "windowsOut", enabled = false, speed = 1, bezier = "linear" })
hl.animation({ leaf = "fadeIn",     enabled = false, speed = 1, bezier = "linear" })
hl.animation({ leaf = "fadeOut",    enabled = false, speed = 1, bezier = "linear" })
hl.animation({ leaf = "layers",     enabled = true, speed = 2, bezier = "step", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "step", style = "fade" })

-- CRT shader saved by `station crt`. Curvature and flicker need full
-- redraws, every other effect keeps damage tracking on.
local shader = s.crt.shader
if shader and shader ~= "" and s.exists(shader) then
    if s.crt.full_redraw == "1" then
        hl.config({ debug = { damage_tracking = 0 } })
    end
    hl.config({ decoration = { screen_shader = shader } })
end
