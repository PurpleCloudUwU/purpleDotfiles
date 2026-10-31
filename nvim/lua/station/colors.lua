-- Colour scheme from the active station palette. Neovim reloads it when
-- it gets focus again after `station theme`, or with :StationTheme.

local M = {}

local home = vim.env.HOME
local config = vim.env.XDG_CONFIG_HOME or (home .. "/.config")
local state = (vim.env.XDG_STATE_HOME or (home .. "/.local/state")) .. "/station"

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

local function current_theme()
    local f = io.open(state .. "/theme", "r")
    if not f then return "violet" end
    local name = (f:read("*l") or ""):match("%S+")
    f:close()
    return name or "violet"
end

-- Mixes colour a into b, t = share of a
local function blend(a, b, t)
    local function ch(hex, i) return tonumber(hex:sub(i, i + 1), 16) end
    local out = "#"
    for _, i in ipairs({ 2, 4, 6 }) do
        out = out .. string.format("%02x", math.floor(ch(a, i) * t + ch(b, i) * (1 - t) + 0.5))
    end
    return out
end

M.theme = nil
M.palette = {}

function M.load()
    local theme = current_theme()
    local p = read_kv(config .. "/station/palettes/" .. theme .. ".conf")
    if not p.bg then
        theme = "violet"
        p = read_kv(config .. "/station/palettes/violet.conf")
    end
    if not p.bg then return end
    M.theme, M.palette = theme, p

    vim.cmd("highlight clear")
    vim.g.colors_name = "station"
    local function hl(group, spec) vim.api.nvim_set_hl(0, group, spec) end
    local cursorline = blend(p.accent, p.surface, 0.14)

    -- Editor
    hl("Normal", { fg = p.fg, bg = p.surface })
    hl("NormalFloat", { fg = p.fg, bg = p.surface2 })
    hl("FloatBorder", { fg = p.frame, bg = p.surface2 })
    hl("FloatTitle", { fg = p.bg, bg = p.frame })
    hl("LineNr", { fg = p.muted })
    hl("CursorLineNr", { fg = p.frame, bg = cursorline })
    hl("CursorLine", { bg = cursorline })
    hl("CursorColumn", { bg = cursorline })
    hl("ColorColumn", { bg = p.surface2 })
    hl("SignColumn", { fg = p.muted })
    hl("Visual", { bg = p.line })
    hl("Search", { fg = p.bg, bg = p.frame })
    hl("IncSearch", { fg = p.bg, bg = p.accent })
    hl("CurSearch", { fg = p.bg, bg = p.accent })
    hl("MatchParen", { fg = p.accent, bold = true, underline = true })
    hl("NonText", { fg = p.faint })
    hl("EndOfBuffer", { fg = p.faint })
    hl("Whitespace", { fg = p.faint })
    hl("WinSeparator", { fg = p.line })
    hl("Folded", { fg = p.muted, bg = p.surface2 })
    hl("Pmenu", { fg = p.fg, bg = p.surface2 })
    hl("PmenuSel", { fg = p.bg, bg = p.frame })
    hl("PmenuSbar", { bg = p.surface2 })
    hl("PmenuThumb", { bg = p.border })
    hl("StatusLine", { fg = p.fg, bg = p.surface2 })
    hl("StatusLineNC", { fg = p.muted, bg = p.surface2 })
    hl("TabLine", { fg = p.muted, bg = p.surface2 })
    hl("TabLineSel", { fg = p.bg, bg = p.frame })
    hl("TabLineFill", { bg = p.surface2 })
    hl("Title", { fg = p.frame, bold = true })
    hl("Directory", { fg = p.frame })
    hl("ErrorMsg", { fg = p.accent })
    hl("WarningMsg", { fg = p.color3 })
    hl("MoreMsg", { fg = p.frame })
    hl("Question", { fg = p.frame })
    hl("ModeMsg", { fg = p.fg })

    -- Syntax, like the Theme.qml screenshot: keywords in the accent, types
    -- in the second accent, strings light, numbers in the frame colour
    hl("Comment", { fg = p.muted, italic = true })
    hl("Constant", { fg = p.frame })
    hl("String", { fg = p.fg2 })
    hl("Character", { fg = p.fg2 })
    hl("Number", { fg = p.frame })
    hl("Boolean", { fg = p.frame })
    hl("Identifier", { fg = p.fg })
    hl("Function", { fg = p.fg, bold = true })
    hl("Statement", { fg = p.accent })
    hl("Keyword", { fg = p.accent })
    hl("Operator", { fg = p.muted })
    hl("PreProc", { fg = p.accent })
    hl("Type", { fg = p.accent2 })
    hl("Special", { fg = p.frame })
    hl("Delimiter", { fg = p.muted })
    hl("Underlined", { underline = true })
    hl("Todo", { fg = p.bg, bg = p.accent })
    hl("Error", { fg = p.accent })
    hl("@variable", { fg = p.fg })
    hl("@property", { fg = p.fg })
    hl("@type.builtin", { link = "Type" })
    hl("@markup.heading", { fg = p.frame, bold = true })
    hl("@markup.link", { fg = p.accent2, underline = true })

    -- Diagnostics and diffs
    hl("DiagnosticError", { fg = p.accent })
    hl("DiagnosticWarn", { fg = p.color3 })
    hl("DiagnosticInfo", { fg = p.accent2 })
    hl("DiagnosticHint", { fg = p.muted })
    hl("DiagnosticUnderlineError", { undercurl = true, sp = p.accent })
    hl("DiagnosticUnderlineWarn", { undercurl = true, sp = p.color3 })
    hl("DiffAdd", { bg = blend(p.color2, p.surface, 0.2) })
    hl("DiffChange", { bg = blend(p.accent2, p.surface, 0.2) })
    hl("DiffDelete", { fg = p.accent })
    hl("DiffText", { bg = blend(p.accent2, p.surface, 0.4) })

    -- Statusline blocks (station/statusline.lua)
    hl("StationMode", { fg = p.bg, bg = p.accent })
    hl("StationBranch", { fg = p.fg, bg = p.line })
    hl("StationFile", { fg = p.fg, bg = p.surface2 })
    hl("StationInfo", { fg = p.muted, bg = p.surface2 })
    hl("StationTime", { fg = p.fg, bg = p.line })
    hl("StationPercent", { fg = p.bg, bg = p.frame })
end

function M.setup()
    M.load()
    vim.api.nvim_create_user_command("StationTheme", M.load, { desc = "Reload the station colours" })
    vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
            if current_theme() ~= M.theme then M.load() end
        end,
    })
end

return M
