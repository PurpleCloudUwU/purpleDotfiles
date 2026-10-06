# purpleDotfiles
## My T580 config.
![Example Picture from my Desktop.](https://github.com/PurpleCloudUwU/purpleDotfiles/blob/main/pasted%20file.png)
The Dotfiles include:
- Sway
- Waybar (incl. Bluetooth, WLAN, power profile and notification history menus)
- Hyprlock
- Fuzzel
- Mako (notifications)
- qt6ct + KDE color scheme (purple theme for Qt apps like Dolphin)
- Chatterino theme

### Where the files go
Folders at the top level go to `~/.config/` (e.g. `waybar/` -> `~/.config/waybar/`). Exceptions:

| File | Destination |
|---|---|
| `dolphin/PurpleMocha.colors` | `~/.local/share/color-schemes/` |
| `chatterino/PurpleMocha.json` | `~/.local/share/chatterino/Themes/` |

Additional settings:
- Qt apps use qt6ct: add `export QT_QPA_PLATFORMTHEME=qt6ct` to `~/.bash_profile` (needs a re-login).
- Dolphin: in `~/.config/dolphinrc` set `ColorScheme=PurpleMocha` under `[UiSettings]`.
- Chatterino: select `PurpleMocha` as theme in the settings.
- `hypr/sigil.png` is generated per machine with `hypr/make-sigil.sh`.
