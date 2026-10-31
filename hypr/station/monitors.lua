-- The T580's own panel at 1920x1080 and scale 1, the size the canvas was
-- drawn for. Anything plugged in goes to the right of it.
-- `hyprctl monitors all` lists the names.

hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
