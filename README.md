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
| `niri/desk-term-size` | In desk mode new terminals open at the size the last one was resized to |
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

yami's own package list is skipped on purpose: it would bring qt6ct and
power-profiles-daemon, and the latter fights tlp-pd (which answers yami's
power profile switch just as well).

### Where the files go

| Repo | Destination |
|---|---|
| `foot`, `yazi`, `nvim`, `bash`, `starship` | `~/.config/<name>` (symlink) |
| `niri/user.kdl` | `~/.config/niri/user.kdl` (symlink; the rest of `~/.config/niri` is yami's) |
| `niri/desk-term-size` | `~/.local/bin/desk-term-size` (symlink, started from `user.kdl`) |
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
| Mod+F, Mod+Shift+F | maximize column, fullscreen |
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

## Terminal size in desk mode

niri opens every window tiled, and in desk mode yami then makes it floating
at half the screen. `niri/desk-term-size` follows niri's event stream: as
soon as a new kitty has turned floating, it gets the size a kitty was last
resized to by hand (dragging, Mod+Minus/Plus). Only hand resizes of a
floating kitty count; the changes when windows switch between floating and
tiling, its own resizes and fullscreen are left out. The size is kept in
`~/.local/state/desk-term-size.json` and read for every new terminal, so it
can be set there by hand too. In tiling mode nothing changes. Other
terminals: `APPS` at the top of the script.

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
