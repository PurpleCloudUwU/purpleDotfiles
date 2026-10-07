# purpleDotfiles
## My T580 config.
![Example Picture from my Desktop.](https://github.com/PurpleCloudUwU/purpleDotfiles/blob/main/pasted%20file.png)
The Dotfiles include:
- Sway
- Waybar (incl. Bluetooth, audio output, WLAN, power profile and notification history menus)
- Hyprlock
- Fuzzel
- Mako (notifications)
- qt6ct + KDE color scheme (purple theme for Qt apps like Dolphin)
- Chatterino theme
- Kitty (terminal, same colors)

### Setup
The configs are symlinked into place, so this repo is the live config
(move existing folders out of the way first):
```sh
git clone https://github.com/PurpleCloudUwU/purpleDotfiles ~/purpleDotfiles
for d in sway waybar hypr fuzzel mako qt6ct kitty; do ln -s ~/purpleDotfiles/$d ~/.config/$d; done
ln -s ~/purpleDotfiles/dolphin/PurpleMocha.colors ~/.local/share/color-schemes/
ln -s ~/purpleDotfiles/chatterino/PurpleMocha.json ~/.local/share/chatterino/Themes/
hypr/make-sigil.sh   # creates hypr/sigil.png (ignored by git)
```

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
