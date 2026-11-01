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

    -- No animations at all: windows, workspaces and the shell's panels
    -- appear at once. Nothing moves that does not have to.
    animations = { enabled = false },

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

-- All windows keep the same border width; a thicker frame on the focused
-- window resized it by a pixel on every focus change. Focus shows by colour.
-- The old rule was called "focus-frame" and a config reload does not drop a
-- named rule, so it is set again here with the normal 2 px.
hl.window_rule({
    name  = "focus-frame",
    match = { focus = true },
    border_size = 2,
})

-- Every workspace on the laptop panel keeps the right column free for the
-- floating file manager and the desktop widgets, like on canvas board 01:
-- tiled windows end at x 1116, the column runs from 1140 to 1896. Super+G
-- switches it on and off (binds.lua). Switch the column off on the
-- DESKTOP WIDGETS page of STATION SETUP (station desktop column off).
if s.desktop.column ~= "off" then
    hl.workspace_rule({
        workspace = "m[eDP-1]",
        gaps_out  = { top = 24, left = 24, bottom = 24, right = 804 },
    })
end

-- CRT shader saved by `station crt`. Curvature and flicker need full
-- redraws, every other effect keeps damage tracking on.
local shader = s.crt.shader
if shader and shader ~= "" and s.exists(shader) then
    if s.crt.full_redraw == "1" then
        hl.config({ debug = { damage_tracking = 0 } })
    end
    hl.config({ decoration = { screen_shader = shader } })
end
