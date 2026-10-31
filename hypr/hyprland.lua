-- Mondbasis · Hyprland (Lua config, Hyprland 0.55 or newer)
--
-- The parts live in station/*.lua next to this file. Colours and the CRT
-- shader are not written here: the `station` script keeps them in
-- ~/.local/state/station/ and station/state.lua reads them on every
-- (re)load, so `station theme` and `station crt` survive `hyprctl reload`.

local home = os.getenv("HOME")
local hypr = (os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")) .. "/hypr/"
package.path = hypr .. "?.lua;" .. package.path

require("station.monitors")
require("station.env")
require("station.look")
require("station.input")
require("station.binds")
require("station.rules")
require("station.autostart")
