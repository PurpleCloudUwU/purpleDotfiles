-- Window and layer rules

-- The file manager floats in the right column (canvas board 01). On
-- workspace 1 that column is kept free, elsewhere it floats over the tiles.
hl.window_rule({
    name  = "files-column",
    match = { class = "^station\\.files$" },
    float = true,
    size  = { 756, 420 },
    move  = { "monitor_w-780", 88 },
})

-- Small tools float in the middle
hl.window_rule({
    name   = "float-tools",
    match  = { class = "^(org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueman-manager|xdg-desktop-portal-gtk)$" },
    float  = true,
    center = true,
    size   = { 900, 600 },
})

-- Bitwarden's extension popup (LibreWolf/Firefox) floats like before
hl.window_rule({
    name  = "bitwarden-popup",
    match = { title = "^Extension: \\(Bitwarden" },
    float = true,
    size  = { 457, 668 },
})

-- Picture in picture: small, pinned, bottom right
hl.window_rule({
    name  = "pip",
    match = { title = "^Picture-in-Picture$" },
    float = true,
    pin   = true,
    size  = { 480, 270 },
    move  = { "monitor_w-504", "monitor_h-294" },
})

-- No screen blanking while something is fullscreen (videos, games)
hl.window_rule({
    name  = "idle-fullscreen",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
})

-- From the Hyprland example config
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Quickshell's toasts and OSD appear without the layer fade
hl.layer_rule({
    name  = "shell-no-anim",
    match = { namespace = "^station-(osd|toast)$" },
    no_anim = true,
})
