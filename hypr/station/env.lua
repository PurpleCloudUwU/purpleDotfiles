-- Environment for everything started from Hyprland

-- The station script lives in ~/.local/bin, however the session was started
local home = os.getenv("HOME")
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not path:find(home .. "/.local/bin", 1, true) then
    hl.env("PATH", home .. "/.local/bin:" .. path)
end

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Wayland first for Qt, GTK, SDL and Electron apps
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Qt in the station look: qt6ct with the palette and the stylesheet that
-- `station theme` writes (~/.config/qt6ct). Without qt6ct, Qt takes colours
-- and fonts from the GTK 3 theme (Station) and Fusion draws the widgets.
local qt6ct = io.open("/usr/lib/qt6/plugins/platformthemes/libqt6ct.so", "r")
if qt6ct then
    qt6ct:close()
    hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
else
    hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
    hl.env("QT_STYLE_OVERRIDE", "Fusion")
end

hl.env("EDITOR", "nvim")
hl.env("VISUAL", "nvim")
hl.env("TERMINAL", "foot")
