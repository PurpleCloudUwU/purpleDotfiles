-- blackhole: Catppuccin Mocha in the black hole colors (accent #be8cff), same palette
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
      -- Catppuccin's purple (keywords, borders, ...) becomes the system accent,
      -- text and grays take the colors of the black hole wallpaper
      color_overrides = {
        mocha = {
          mauve = "#be8cff",
          pink = "#ff50dc",
          lavender = "#c8b9ff",
          text = "#f0d7ff",
          subtext1 = "#ceb8dc",
          subtext0 = "#a396d0",
          overlay2 = "#8a7fae",
          overlay1 = "#756b95",
          overlay0 = "#62597e",
          surface2 = "#44325c",
          surface1 = "#332645",
          surface0 = "#22192e",
          base = "#0f0b14",
          mantle = "#0b080f",
          crust = "#08060a",
        },
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
