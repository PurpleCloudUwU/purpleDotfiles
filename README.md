# purpleDotfiles · Mondbasis

My ThinkPad T580 rice: Arch Linux, Hyprland and Quickshell, styled like the
terminals of a moon base. Four colour worlds (Amber, Red, Green, Violet),
pixel fonts and an optional CRT screen shader.

The old Sway/Waybar/eww setup is kept as the git tag `sway-legacy`.

## What's inside

| Part | What it does |
|---|---|
| `hypr/` | Hyprland (Lua config, 0.55+), hyprlock, hypridle |
| `quickshell/` | Everything on screen that isn't an app window: top bar, program select (Super+D), PDA quick access (Super+N), power menu, desktop widgets (tasks, music, PDA panel), notifications, volume/brightness OSD, wallpaper, and STATION SETUP (Super+Shift+F12) |
| `station/` | Palettes, the CRT shader template and the `station` script that switches theme and CRT |
| `foot/` | Terminal (Departure Mono) |
| `yazi/` | File manager, floats in the right column (Super+E) |
| `nvim/` | Neovim without plugins: station colours and the statusline from the canvas |
| `fastfetch/` | System info with the pixel moon |
| `btop/` | System monitor |
| `fingerprint/` | Fingerprint login for the T580's sensor (not part of `install.sh`) |

The interface is English, the keyboard layout German without dead keys
(`hypr/station/input.lua`).

## Setup

On a fresh, minimal Arch Linux, as your normal user with sudo:

```sh
sudo pacman -S --needed git
git clone https://github.com/PurpleCloudUwU/purpleDotfiles ~/purpleDotfiles
~/purpleDotfiles/install.sh
```

The script installs the packages (official repos, plus three pixel fonts
from the AUR via paru), symlinks the configs into `~/.config` (old ones go to
`~/dotfiles-backup-<date>/`), writes the theme files for Violet and enables
NetworkManager, Bluetooth, TLP and the ly login manager. Then reboot and
choose Hyprland in ly. Options: `--copy`, `--no-packages`, `--no-services`,
`--help`.

### Where the files go

| Repo | Destination |
|---|---|
| `hypr`, `quickshell`, `station`, `foot`, `yazi`, `nvim`, `fastfetch` | `~/.config/<name>` (symlink) |
| `station/bin/station` | `~/.local/bin/station` |
| `btop/btop.conf` | `~/.config/btop/btop.conf` (copied, btop rewrites it) |
| `station/tasks.txt` | `~/.local/share/station/tasks.txt` (only the first time) |
| `station/shell.bash` | sourced from `~/.bashrc` (prompt, aliases, `y` for yazi) |

Generated, not in git: everything in `~/.local/state/station/` (theme,
CRT settings and shaders, terminal colours, prompt, hyprlock colours),
`yazi/theme.toml`, `fastfetch/config.jsonc` and btop's `themes/station.theme`.

## Keys

| Keys | Action |
|---|---|
| Super+Return | Terminal |
| Super+D | Program select |
| Super+E | Files (yazi) |
| Super+Shift+W | Browser (LibreWolf) |
| Super+Shift+M | Music (Spotify) |
| Super+N | PDA quick access: WiFi, brightness, volume, toggles, theme, CRT |
| Super+Shift+E | Power menu |
| Super+Escape | Lock |
| Super+F12 | CRT on/off |
| Super+Shift+F12 | STATION SETUP: CRT calibration and desktop widgets |
| Super+F11 | Next theme |
| Super+Shift+Q | Close window |
| Super+F | Fullscreen |
| Super+G | Big window over the widget column, not fullscreen (again: back) |
| Super+Shift+Space | Float |
| Super+H J K L or arrows | Focus (with Shift: move, with Ctrl: resize) |
| Super+1…0 | Workspace (with Shift: move the window there) |
| Super+minus | Scratchpad (with Shift: move the window there) |
| Super+W / Super+Tab | Tab group / next tab |
| Print, Super+Print, Super+Shift+Print | Screenshot of the screen, window, region |
| Super+Shift+N | Dismiss notifications |
| Super+Shift+C | Reload Hyprland |

After a `git pull` in the repo, `station reload` reloads Hyprland and
Quickshell.

Only a new folder in `quickshell/` needs a real restart (`qs kill`, then
`qs -n -d`). Quickshell 0.3.2 sometimes crashes while it shuts down and then
shows its crash dialog; that is a Quickshell bug at exit, the restarted shell
is fine.

The bar is 0.75 of the canvas size; `barScale` in
`quickshell/services/Theme.qml` makes it bigger or smaller (1.0 is the
canvas). With another value, also adjust the yazi position in
`hypr/station/rules.lua` (bar bottom + 24).

Every workspace keeps the right column free for the floating file
manager and the desktop widgets, like on the canvas; Super+G makes a window
big over it. Switch the column off on the DESKTOP WIDGETS page of STATION
SETUP.

## Themes and CRT

```sh
station theme violet          # amber, red, green, violet, next
station crt subtle            # off, work, subtle, full
station crt toggle            # Super+F12
station crt tint amber        # phosphor tint: neutral, amber, green, red
station crt set scan 50       # single values 0-100, the preset becomes "custom"
station crt option battery_subtle off
```

The **CRT CALIBRATION** page of STATION SETUP (Super+Shift+F12, or CRT
CALIBRATION in the program select) shows the effects on a test picture first: presets, the seven
values, phosphor colour, the behaviour options and an estimate of the GPU
load. APPLY sends everything to `station crt write`; the colour world row
switches the theme right away. From scripts: `qs ipc call crt open`,
`qs ipc call crt preset subtle`, `qs ipc call theme set amber`.

| Preset | Effects | Cost on the UHD 620 |
|---|---|---|
| OFF | none | none |
| WORK | scanlines, a little glow, vignette | barely measurable |
| SUBTLE | plus colour fringe and static grain | small |
| FULL TUBE | plus curvature and flicker | noticeable: full redraw every frame |

The shader (`station/crt/crt.frag.in`) runs through Hyprland's
`decoration.screen_shader`. Curvature and flicker need a full redraw on every
frame, so only FULL TUBE switches Hyprland's damage tracking off. Two
options, both on by default: on battery FULL TUBE drops to SUBTLE, and the
shader goes off while a window is fullscreen. A third one, off by default,
lets the tube flicker for a moment at login.

## Desktop widgets

MUSIC, TASKS and the PDA panel sit below the windows. The **DESKTOP
WIDGETS** page of STATION SETUP shows the screen in small: drag a widget
there and the real one moves along (8 px grid). The page also shows or
hides each widget, switches the music visualizer and the done tasks, and
decides whether Hyprland keeps the right column free for
them (`station desktop column on|off`). The layout is kept in
`~/.local/state/station/desktop.json`; RESET LAYOUT brings back the one
from the canvas.

The level bars in MUSIC show the real music through
[cava](https://github.com/karlstav/cava) (PipeWire). cava only runs while
something plays, the widget is shown and the visualizer is on
(`quickshell/scripts/cava.conf`: 10 bars, 25 frames a second).

## Fonts

- **Departure Mono** (Nerd Font) in the terminal, **VT323** for the displays,
  **Silkscreen** for small labels. All three come from the AUR.
- **Pocket** by Aaron D. Chand is the font the game uses for its displays. It
  isn't packaged and its licence isn't stated clearly, so check it on dafont
  before you use it. Put the `.ttf` into `~/.local/share/fonts/` and run
  `fc-cache -f`: Quickshell and hyprlock pick it up instead of VT323.

## Tasks

The task widget reads `~/.local/share/station/tasks.txt`, one `[ ] task` or
`[x] task` per line. Click a task to tick it off, click the header to edit
the file in nvim.

## Fingerprint (T580 only)

The T580's Synaptics sensor (`06cb:009a`) is not supported by libfprint, so
`~/purpleDotfiles/fingerprint/setup.sh` sets up python-validity with
open-fprintd (not part of `install.sh`). The script:
- builds python-validity with the init fixes from upstream PR #290, without them the sensor doesn't start on Python 3.14
- keeps the sensor out of USB autosuspend and its firmware in `/var/lib`
- allows the finger for sudo and polkit
- starts enrolling a finger

While a finger is wanted, Quickshell shows a "FINGER REQUESTED"
notification. hyprlock unlocks with the finger too.
