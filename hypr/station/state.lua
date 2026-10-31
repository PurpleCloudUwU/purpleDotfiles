-- Reads what the `station` script saved: the theme (and its palette) and
-- the CRT shader. Only plain file reads, nothing that could block.

local M = {}

local home = os.getenv("HOME")
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
M.dir = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/station"

-- key=value lines, everything else is skipped
local function read_kv(path)
    local t = {}
    local f = io.open(path, "r")
    if not f then return t end
    for line in f:lines() do
        local k, v = line:match("^([%w_]+)=(.*)$")
        if k then t[k] = v end
    end
    f:close()
    return t
end

function M.exists(path)
    local f = io.open(path, "r")
    if f then f:close() end
    return f ~= nil
end

local function first_word(path, default)
    local f = io.open(path, "r")
    if not f then return default end
    local word = (f:read("*l") or ""):match("%S+")
    f:close()
    return word or default
end

M.theme = first_word(M.dir .. "/theme", "violet")
M.palette = read_kv(config .. "/station/palettes/" .. M.theme .. ".conf")
if not M.palette.bg then
    M.theme = "violet"
    M.palette = read_kv(config .. "/station/palettes/violet.conf")
end

M.crt = read_kv(M.dir .. "/crt.conf")

-- Palette colour as a Hyprland colour string, e.g. color("frame") or
-- color("bg", "cc") with alpha
function M.color(key, alpha)
    local hex = (M.palette[key] or "#ff00ff"):gsub("#", "")
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

return M
