-- Neovim for the Mondbasis rice: no plugins, the station colours and the
-- statusline from canvas board 04 (NORMAL | branch | file ... type | time | %).

local o = vim.opt
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.termguicolors = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.scrolloff = 5
o.splitright = true
o.splitbelow = true
o.undofile = true
o.updatetime = 300
o.showmode = false
o.laststatus = 3
o.fillchars = { eob = "~", vert = "│" }
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

vim.g.mapleader = " "
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<cr>")
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Files" })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Briefly highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

require("station.colors").setup()
require("station.statusline").setup()
