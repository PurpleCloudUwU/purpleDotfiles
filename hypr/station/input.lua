-- Keyboard: German without dead keys (the interface itself is English)

hl.config({
    input = {
        kb_layout  = "de",
        kb_variant = "nodeadkeys",
        numlock_by_default = true,
        repeat_delay = 300,
        repeat_rate  = 40,

        follow_mouse = 1,
        sensitivity  = 0,
        -- Flat acceleration for an external mouse (applies to the touchpad too):
        -- accel_profile = "flat",

        touchpad = {
            natural_scroll          = true,
            tap_to_click            = true,
            disable_while_typing    = true,
            middle_button_emulation = true,
        },
    },
})

-- Three fingers sideways switch workspaces
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
