-- Statusline from canvas board 04:
--   NORMAL | main | quickshell/Theme.qml          qml · utf-8 | 23:34 | 95 %

local M = {}

local modes = {
    n = "NORMAL", i = "INSERT", v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK",
    c = "COMMAND", R = "REPLACE", s = "SELECT", S = "S-LINE", t = "TERMINAL",
}

-- Git branch per buffer, looked up when the buffer is entered
local function update_branch()
    local dir = vim.fn.expand("%:p:h")
    if dir == "" or vim.fn.isdirectory(dir) == 0 then
        vim.b.station_branch = ""
        return
    end
    local out = vim.fn.systemlist({ "git", "-C", dir, "branch", "--show-current" })
    vim.b.station_branch = vim.v.shell_error == 0 and (out[1] or "") or ""
end

function M.render()
    local mode = modes[vim.fn.mode():sub(1, 1)] or vim.fn.mode():upper()
    local branch = vim.b.station_branch or ""
    local file = vim.fn.expand("%:~:.")
    if file == "" then file = "[no name]" end
    if vim.bo.modified then file = file .. " +" end
    local ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text"
    local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
    local pct = math.floor(vim.fn.line(".") * 100 / math.max(1, vim.fn.line("$")))

    local parts = {
        "%#StationMode# " .. mode .. " ",
        branch ~= "" and ("%#StationBranch# " .. branch .. " ") or "",
        "%#StationFile# " .. file:gsub("%%", "%%%%") .. " ",
        "%=",
        "%#StationInfo# " .. ft .. " · " .. enc .. " ",
        "%#StationTime# " .. os.date("%H:%M") .. " ",
        "%#StationPercent# " .. pct .. " % ",
    }
    return table.concat(parts)
end

function M.setup()
    vim.o.statusline = "%!v:lua.require'station.statusline'.render()"
    vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "DirChanged" }, { callback = update_branch })
end

return M
