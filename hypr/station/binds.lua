-- Keybindings. SUPER is the main modifier; most of them are the same as in
-- the old Sway config. "quickshell:<name>" are GlobalShortcuts in
-- quickshell/shell.qml, they open the shell's own panels without starting
-- a process.

local mod = "SUPER"
local function exec(cmd) return hl.dsp.exec_cmd(cmd) end
local function shell(name) return hl.dsp.global("quickshell:" .. name) end

-- Programs (`station open` knows which program belongs to what)
hl.bind(mod .. " + Return",    exec("foot"),                  { description = "Terminal" })
hl.bind(mod .. " + D",         shell("launcher"),             { description = "Program select" })
hl.bind(mod .. " + E",         exec("station open files"),    { description = "Files (yazi)" })
hl.bind(mod .. " + SHIFT + W", exec("station open browser"),  { description = "Browser" })
hl.bind(mod .. " + SHIFT + M", exec("station open music"),    { description = "Music" })

-- Shell panels
hl.bind(mod .. " + N",         shell("quick"),                { description = "PDA quick access" })
hl.bind(mod .. " + SHIFT + N", shell("dismiss"),              { description = "Dismiss notifications" })
hl.bind(mod .. " + SHIFT + E", shell("power"),                { description = "Power menu" })
hl.bind(mod .. " + Escape",    exec("station power lock"),    { description = "Lock" })

-- Screen: CRT on/off (as on the calibration board) and the next colour world
hl.bind(mod .. " + F12", exec("station crt toggle"),  { description = "CRT on/off" })
hl.bind(mod .. " + F11", exec("station theme next"),  { description = "Next theme" })
hl.bind(mod .. " + SHIFT + F12", shell("crt"),       { description = "STATION SETUP (CRT, desktop widgets)" })

-- Windows
hl.bind(mod .. " + SHIFT + Q",     hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + C",     hl.dsp.reload_config())
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen())
hl.bind(mod .. " + SHIFT + F",     hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",             hl.dsp.window.pseudo())
hl.bind(mod .. " + B",             hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + W",             hl.dsp.group.toggle())
hl.bind(mod .. " + Tab",           hl.dsp.group.next())

-- Focus, move and resize with hjkl or the arrow keys
local directions = {
    { keys = { "H", "left" },  dir = "left",  x = -40, y = 0 },
    { keys = { "J", "down" },  dir = "down",  x = 0,   y = 40 },
    { keys = { "K", "up" },    dir = "up",    x = 0,   y = -40 },
    { keys = { "L", "right" }, dir = "right", x = 40,  y = 0 },
}
for _, d in ipairs(directions) do
    for _, key in ipairs(d.keys) do
        hl.bind(mod .. " + " .. key,           hl.dsp.focus({ direction = d.dir }))
        hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = d.dir }))
        hl.bind(mod .. " + CTRL + " .. key,    hl.dsp.window.resize({ x = d.x, y = d.y, relative = true }), { repeating = true })
    end
end

-- Workspaces 1-10 (1 TERM, 2 WEB, 3 SYS, 4 CODE, 5 MEDIA in the bar)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
hl.bind(mod .. " + minus",         hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:scratch" }))

-- Mouse: drag and resize windows
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume (Quickshell shows the OSD by itself), brightness, media
local held = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), held)
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp",   exec("station bright up"), held)
hl.bind("XF86MonBrightnessDown", exec("station bright down"), held)
hl.bind("XF86AudioPlay",  exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  exec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  exec("playerctl previous"),   { locked = true })

-- Screenshots to ~/Pictures/Screenshots (and the clipboard)
hl.bind("Print",                 exec("station shot screen"))
hl.bind(mod .. " + Print",         exec("station shot window"))
hl.bind(mod .. " + SHIFT + Print", exec("station shot region"))
