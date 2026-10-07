# purpleDotfiles
## My T580 config.
![Example Picture from my Desktop.](screenshots/desktop.png)
The Dotfiles include:
- Sway
- Waybar (incl. Bluetooth, audio output, WLAN, power profile and notification history menus)
- Hyprlock
- Fuzzel
- Mako (notifications)
- qt6ct + KDE color scheme (purple theme for Qt apps like Dolphin)
- Chatterino theme
- Kitty (terminal, same colors)
- Starship (shell prompt as flat purple blocks)
- swayimg (image viewer, same colors)
- SwayOSD (small on-screen display with icon for volume and brightness)
- Yazi (file manager: Enter goes into folders instead of opening them in $EDITOR, nvim when $EDITOR is unset)
- Neovim (LazyVim with Catppuccin Mocha, purple accent, transparent background like kitty)

### Setup
The configs are symlinked into place, so this repo is the live config
(move existing folders out of the way first):
```sh
git clone https://github.com/PurpleCloudUwU/purpleDotfiles ~/purpleDotfiles
for d in sway waybar hypr fuzzel mako qt6ct kitty swayimg swayosd yazi nvim; do ln -s ~/purpleDotfiles/$d ~/.config/$d; done
ln -s ~/purpleDotfiles/dolphin/PurpleMocha.colors ~/.local/share/color-schemes/
ln -s ~/purpleDotfiles/chatterino/PurpleMocha.json ~/.local/share/chatterino/Themes/
ln -s ~/purpleDotfiles/starship/starship.toml ~/.config/starship.toml
~/purpleDotfiles/hypr/make-sigil.sh   # creates hypr/sigil.png (ignored by git)
```

### Where the files go
The config folders (`sway`, `waybar`, `hypr`, `fuzzel`, `mako`, `qt6ct`, `kitty`, `swayimg`, `swayosd`, `yazi`, `nvim`) go to `~/.config/` (e.g. `waybar/` -> `~/.config/waybar/`); `screenshots/` is only for this README. Exceptions:

| File | Destination |
|---|---|
| `dolphin/PurpleMocha.colors` | `~/.local/share/color-schemes/` |
| `chatterino/PurpleMocha.json` | `~/.local/share/chatterino/Themes/` |
| `starship/starship.toml` | `~/.config/starship.toml` |

Additional settings:
- Qt apps use qt6ct: add `export QT_QPA_PLATFORMTHEME=qt6ct` to `~/.bash_profile` (needs a re-login).
- Starship: add `eval "$(starship init bash)"` to the end of `~/.bashrc`.
- swayimg as default image viewer: `xdg-mime default swayimg.desktop $(grep -Po '(?<=^MimeType=).*' /usr/share/applications/swayimg.desktop | tr ';' ' ')`
- kew as default music player. kew is a terminal app, so a local copy of its desktop entry starts it in its own kitty window (otherwise xdg-open, yazi and browsers run it invisibly):
  ```sh
  sed -e 's|^Exec=kew play %F$|Exec=kitty --class kew -e kew play %F|' -e 's|^Terminal=true$|Terminal=false|' \
      -e 's|^MimeType=.*|&audio/x-vorbis+ogg;audio/x-opus+ogg;|' \
      /usr/share/applications/kew.desktop > ~/.local/share/applications/kew.desktop
  xdg-mime default kew.desktop audio/mpeg audio/flac audio/x-flac audio/wav audio/x-wav audio/mp4 audio/x-m4a audio/ogg audio/opus audio/webm audio/x-vorbis+ogg audio/x-opus+ogg
  ```
- Dolphin as default for folders (kew also claims folders and would otherwise be picked): `xdg-mime default org.kde.dolphin.desktop inode/directory`
- Dolphin: in `~/.config/dolphinrc` set `ColorScheme=PurpleMocha` under `[UiSettings]`.
- Chatterino: select `PurpleMocha` as theme in the settings.
- `hypr/sigil.png` is generated per machine with `hypr/make-sigil.sh`.

### Terminal
Kitty with the starship prompt:

![Terminal: kitty with the starship prompt](screenshots/terminal.png)
