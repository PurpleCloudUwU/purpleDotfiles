# purpleDotfiles · yami on niri

My ThinkPad T580 rice: Arch Linux, the [niri](https://github.com/YaLTeR/niri)
compositor and the [yami](https://github.com/Trendorin/yami) desktop, a
pixel-art shell written in Rust that draws the bar, launcher, dock,
notifications, lock screen, widgets and settings itself. No Qt anywhere.

Older setups are git tags: the Hyprland + Quickshell "Mondbasis" rice is
`hyprland-quickshell`, the Sway/Waybar/eww one `sway-legacy`.

## What's inside

| Part | What it does |
|---|---|
| `niri/user.kdl` | My niri settings on top of yami: German keyboard without dead keys, touchpad, the T580 panel, a few keys from the Hyprland days |
| `niri/desk-term-size` | Desk mode helper: new windows open floating at the last terminal size, each one 1 % further up and right; click to focus; tidy switches between desk and tiling |
| `fontconfig/` | Brave (Origin) uses Noto Sans instead of the pixel font for its interface |
| `bash/` | Aliases, `y` for yazi, zoxide, starship (sourced from `~/.bashrc`) |
| `starship/` | The prompt in the yami look, its colours follow the yami palette |
| `foot/` | Second terminal (Departure Mono, the old Violet colours) |
| `yazi/` | Terminal file manager, Violet theme |
| `nvim/` | Neovim without plugins: Violet colours (`palette.conf`) and the statusline |
| `btop/` | System monitor (yami writes its theme) |
| `fingerprint/` | Fingerprint for sudo and polkit on the T580's sensor (not part of `install.sh`) |

yami itself is not in this repo: `install.sh` builds it from source in
`~/.local/share/yami/src`, and its updater keeps it current from there.
The interface is English, the keyboard layout German without dead keys.

## Setup

On a fresh, minimal Arch Linux, as your normal user with sudo:

```sh
sudo pacman -S --needed git
git clone https://github.com/PurpleCloudUwU/purpleDotfiles ~/purpleDotfiles
~/purpleDotfiles/install.sh
```

The script installs the packages (official repos, plus Departure Mono from
the AUR via paru), builds the newest yami release and runs
its installer without root (palette ash, pixel font everywhere, packaged
niri, no login screen), links the configs into `~/.config` (old ones go to
`~/dotfiles-backup-<date>/`), sets GTK to the yami look and enables
NetworkManager, Bluetooth and TLP. Then log in on a TTY and run
`niri-session`. Options: `--copy`, `--no-packages`, `--no-services`,
`--help`.

Fixes of my own for yami live in `yami/patches/`. `install.sh` puts them
into yami's source only for the build and takes them out again, so yami's
updater keeps a clean checkout (settings → updates shows "with local edits").
A patch that no longer applies is skipped. An update through yami itself
builds without them, so after `yami update` run `install.sh --no-packages
--no-services` again until the fix is in a yami release:

- `0001-desk-mode-first-window.patch`: in desk mode the first window on an
  empty desktop opened tiled (the shell toggled it to floating twice)
- `0002-desk-mode-window-order.patch`: switching tiling → desk floated the
  windows in the order they were opened, so title bars lay over the windows
  in front; now in focus order, as the title bars are drawn (needs 0001)

`install.sh` also comments `focus-follows-mouse` out of yami's
`niri/config.kdl`; `desk-term-size` sets it again in tiling mode only (see
below).

yami's own package list is skipped on purpose: it would bring qt6ct and
power-profiles-daemon, and the latter fights tlp-pd (which answers yami's
power profile switch just as well).

### Where the files go

| Repo | Destination |
|---|---|
| `foot`, `yazi`, `nvim`, `bash`, `starship` | `~/.config/<name>` (symlink) |
| `niri/user.kdl` | `~/.config/niri/user.kdl` (symlink; the rest of `~/.config/niri` is yami's) |
| `niri/desk-term-size` | `~/.local/bin/desk-term-size` (symlink, started from `user.kdl`) |
| `fontconfig/55-brave-no-pixel-font.conf` | `~/.config/fontconfig/conf.d/` (symlink; the folder and `50-yami-pixel.conf` are yami's) |
| `btop/btop.conf` | `~/.config/btop/btop.conf` (copied, btop rewrites it) |

Written by yami, not in git: `~/.config/niri/config.kdl` and `yami-*.kdl`,
`~/.config/yami-shell.json` (every setting from Mod+S), kitty, fastfetch,
the btop theme, `gtk.css` for GTK 3/4 and the pixel cursor.

## Keys

yami's keys (Mod is Super). All of them can be changed in settings → keys,
`yami-shell binds list` prints the current set, Mod+? (Mod+Shift+ß) shows
them.

| Keys | Action |
|---|---|
| Mod+Space, Mod+D | launcher (Tab switches to the clipboard) |
| Mod+V | clipboard |
| Mod+S | yami settings (palette, wallpaper, bar, widgets, dock, keys, screens) |
| Mod+T, Mod+Return | kitty |
| Mod+E | yami-files |
| Mod+Q, Mod+Shift+Q, Alt+F4 | close window |
| Mod+F, Mod+Shift+F | maximize window (also floating, in desk mode), fullscreen |
| Mod+G | floating on/off |
| Mod+Shift+Space | desk mode (floating windows with title bars) ↔ tiling |
| Mod+N, Mod+Shift+N | minimize, restore the last one |
| Mod+Tab | overview |
| Alt+Tab, Alt+^ | recent windows, windows of the same app |
| Mod+arrows, Mod+HJKL | focus; with Ctrl: move |
| Mod+1…0, Mod+Shift+1…0 | workspace, move the column there |
| Mod+R, Mod+Minus, Mod+Plus | next column width, narrower, wider (with Shift: height) |
| Mod+Comma, Mod+Period, Mod+Ü, Mod+Ä | window into the column, out of it, into/out of the left/right one |
| Print, Mod+Shift+S | screenshot overlay; Ctrl+Print monitor, Alt+Print window |
| Mod+Escape | lock |
| Mod+Shift+E, Ctrl+Alt+Del | power menu |
| Mod+B | hide the bar |
| Mod+Shift+C | reload the niri config |
| Mod+Shift+W | default browser |
| Mod+Shift+M | Spotify |

From `niri/user.kdl`: Mod+Return, Mod+Shift+Q, Mod+Shift+C, Mod+Shift+W,
Mod+Shift+M, Mod+0 / Mod+Shift+0, volume up capped at 100 %, and German
keys for the yami keys on `=`, `/`, `[`, `]` and `` ` `` (niri matches a key
as it is without Shift, and those are Shift or AltGr keys on the German
layout). Volume, brightness and media keys work as before.

## Desk mode

`niri/desk-term-size` follows niri's event stream and the mode yami writes
to `~/.local/state/yami/stacking`, and keeps `~/.local/state/desk-mode.kdl`
(included at the end of `user.kdl`) in step with it:

- **Terminals** open floating, centred, at the size a kitty was last resized
  to by hand (dragging, Mod+Minus/Plus), through a window rule in desk mode,
  so they never show up tiled first. Only hand resizes of a floating kitty
  count; the size is kept in `~/.local/state/desk-term-size.json` and can be
  set there by hand too. Other terminals: `APPS` at the top of the script.
- **Focus**: in desk mode a click focuses and raises a window; in tiling mode
  focus follows the mouse. (Hover focus without raising put yami's title
  bars over the windows in front.)
- **Tiling → desk**: windows that still have their tiled shape get a window
  size (terminals the saved one, others 60 % × 70 % of the screen), centred
  and staggered so every title bar shows. Windows that floated before keep
  their size and place.
- **Desk → tiling**: every window gets the default column width (50 %), the
  view starts at the left edge, and terminals the rule opened floating are
  tiled again.

## Prompt

[Starship](https://starship.rs) in the look of the yami bar: user and host
on the accent, the folder on a surface, git and language versions on the
panel colour with faint labels, a red `exit` block after a failed command,
`took` for anything over two seconds, dots up to the clock, `›` below.

The colours follow the yami palette. yami writes its palette to
`~/.local/state/yami/palette.json` whenever it changes (Mod+S → color);
before each prompt `bash/shell.bash` compares that file's date with
`~/.cache/starship/yami.toml` and, when the palette (or
`starship/starship.toml`) is newer, `starship/palette.py` writes the config
again with yami's colours. The next prompt has the new palette; when nothing
changed it costs two date checks. Edit `starship/starship.toml`, never the
copy in `~/.cache`. The linux console keeps a plain prompt.

## Fingerprint (T580 only)

The T580's Synaptics sensor (`06cb:009a`) is not supported by libfprint, so
`~/purpleDotfiles/fingerprint/setup.sh` sets up python-validity with
open-fprintd (not part of `install.sh`). The script:
- builds python-validity with the init fixes from upstream PR #290, without them the sensor doesn't start on Python 3.14
- keeps the sensor out of USB autosuspend and its firmware in `/var/lib`
- allows the finger for sudo and polkit (yami's password window shows the sensor's prompt)
- starts enrolling a finger

The yami lock screen takes the password only.
