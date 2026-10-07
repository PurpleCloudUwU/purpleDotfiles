-- Purple Mocha: Catppuccin Mocha with the purple accent #b794f6, same palette
-- as kitty, Sway and Waybar. The background is transparent, so kitty's
-- background (incl. its opacity) shows through.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = { transparent = true },
      -- Catppuccin's purple (keywords, borders, ...) becomes the system accent
      color_overrides = {
        mocha = { mauve = "#b794f6" },
      },
      -- Popup borders purple like the Sway and kitty borders (default: blue)
      custom_highlights = function(c)
        return {
          FloatBorder = { fg = c.mauve },
          FloatTitle = { fg = c.mauve },
        }
      end,
      integrations = {
        -- Status line: normal mode purple like the active Waybar workspace,
        -- visual mode gets the blue that normal mode had
        lualine = {
          all = function(c)
            return {
              normal = {
                a = { bg = c.mauve, fg = c.base, gui = "bold" },
                b = { bg = c.surface0, fg = c.mauve },
              },
              visual = {
                a = { bg = c.blue, fg = c.base, gui = "bold" },
                b = { bg = c.surface0, fg = c.blue },
              },
            }
          end,
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    -- Not just "catppuccin": Neovim 0.12 ships its own colorscheme with that
    -- name, which would be loaded instead of this plugin
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
