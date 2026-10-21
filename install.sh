#!/usr/bin/env bash
# purpleDotfiles installer for a fresh, minimal Arch Linux.
#
# Installs the programs the configs need, puts the configs into place and
# applies the additional settings from the README. Run it as your normal
# user (not as root); sudo asks for your password where needed:
#   git clone https://github.com/PurpleCloudUwU/purpleDotfiles ~/purpleDotfiles
#   ~/purpleDotfiles/install.sh
#
# The configs are symlinked to this repo, so "git pull" updates them.
# Existing configs are moved to ~/dotfiles-backup-<date>/ first.
#
# Options:
#   --copy         copy the configs instead of symlinking them
#   --no-packages  don't install packages (only configs and settings)
#   --no-services  don't enable system services (NetworkManager, ly, ...)
#   -h, --help     show this help
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
backup="$HOME/dotfiles-backup-$(date +%Y-%m-%d_%H%M%S)"
copy=0 packages=1 services=1

# Programs from the official repos, grouped by what needs them
pacman_pkgs=(
    # Desktop: Sway with bar, lock screen, launcher, notifications, OSD
    sway swaybg swayidle waybar hyprlock fuzzel mako swayosd
    xdg-desktop-portal-wlr xorg-xwayland polkit-gnome dex
    # Login manager (starts Sway and unlocks GNOME Keyring)
    ly gnome-keyring
    # Terminal, prompt, file manager, editor, image viewer, music player
    kitty starship eza yazi neovim swayimg kew
    # Audio (volume keys, audio menu)
    pipewire pipewire-pulse pipewire-alsa wireplumber libpulse pavucontrol playerctl
    # WLAN, Bluetooth, power profiles, brightness
    networkmanager bluez bluez-utils tlp tlp-pd brightnessctl
    # Used by the Waybar/Sway scripts, screenshots and the lock screen sigil
    jq libnotify wl-clipboard grim slurp imagemagick xdg-utils
    # Qt colors and Dolphin
    qt6ct dolphin breeze-icons
    # Animated wallpaper (blackhole-wallpaper) and its settings app
    python-gobject gtk4-layer-shell webkitgtk-6.0 libadwaita
    # Fonts
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    # Neovim (LazyVim) needs these; base-devel and git also build AUR packages
    base-devel git fd ripgrep fzf curl unzip tree-sitter-cli
)
# From the AUR (paru is installed first if there is no AUR helper)
aur_pkgs=(sway-screenshot)
# Optional AUR apps with a keybinding or theme in this repo
aur_optional=(brave-origin-bin chatterino2-bin)

# Config folders: <repo>/<name> -> ~/.config/<name>
config_dirs=(sway waybar hypr fuzzel mako qt6ct kitty swayimg swayosd yazi nvim)
# Single files: <path in repo>:<destination>
config_files=(
    "dolphin/PurpleMocha.colors:$HOME/.local/share/color-schemes/PurpleMocha.colors"
    "chatterino/PurpleMocha.json:$HOME/.local/share/chatterino/Themes/PurpleMocha.json"
    "starship/starship.toml:$HOME/.config/starship.toml"
    "blackhole/blackhole-wallpaper:$HOME/.local/bin/blackhole-wallpaper"
    "blackhole/index.html:$HOME/.local/share/blackhole/index.html"
    "blackhole/blackhole-settings:$HOME/.local/bin/blackhole-settings"
)

info() { printf '\n\033[1;35m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
note() { printf '\033[1;33m  ->\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m==> Error:\033[0m %s\n' "$*" >&2; exit 1; }
ask()  { local a; read -rp "$1 [y/N] " a; [[ $a == [yYjJ]* ]]; }

usage() {
    # The comment block at the top of this file, without the "# "
    sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'
}

# Puts <repo>/$1 at $2 (symlink, or a copy with --copy). Whatever is already
# there is moved to the backup folder, unless it is already the right link.
place() {
    local src="$repo/$1" dest=$2 rel
    if [[ -L $dest && $(readlink -f "$dest") == "$(readlink -f "$src")" ]]; then
        ((copy)) || return 0
        rm "$dest"
    elif [[ -e $dest || -L $dest ]]; then
        rel=${dest#"$HOME"/}
        mkdir -p "$(dirname "$backup/$rel")"
        mv "$dest" "$backup/$rel"
        note "moved the old ~/$rel to $backup"
    fi
    mkdir -p "$(dirname "$dest")"
    if ((copy)); then cp -r "$src" "$dest"; else ln -s "$src" "$dest"; fi
}

# Appends a line to a file unless the file already has exactly that line
add_line() {
    grep -qxF -- "$2" "$1" 2>/dev/null || printf '%s\n' "$2" >> "$1"
}

install_packages() {
    # xxd (lock screen) comes with vim or tinyxxd; both conflict, so only
    # add tinyxxd when there is no xxd yet
    command -v xxd >/dev/null || pacman_pkgs+=(tinyxxd)

    info "Installing packages from the official repos"
    sudo pacman -Syu --needed "${pacman_pkgs[@]}"

    local helper
    helper=$(command -v paru || command -v yay || true)
    if [[ -z $helper ]]; then
        info "Installing the AUR helper paru"
        local tmp
        tmp=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
        (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        helper=paru
    fi

    info "Installing packages from the AUR: ${aur_pkgs[*]}"
    "$helper" -S --needed "${aur_pkgs[@]}"

    echo
    if ask "Also install Brave Origin (browser, Super+Shift+W) and Chatterino (Twitch chat, theme included) from the AUR?"; then
        "$helper" -S --needed "${aur_optional[@]}"
    fi
}

install_configs() {
    if ((copy)); then info "Copying the configs"; else info "Linking the configs to $repo"; fi
    local d f
    for d in "${config_dirs[@]}"; do
        place "$d" "$HOME/.config/$d"
    done
    for f in "${config_files[@]}"; do
        place "${f%%:*}" "${f#*:}"
    done
}

apply_settings() {
    info "Applying the additional settings"

    # Qt colors, editor, prompt and ls with icons (like in the screenshots)
    [[ -f ~/.bash_profile ]] || printf '%s\n' '[[ -f ~/.bashrc ]] && . ~/.bashrc' > ~/.bash_profile
    add_line ~/.bash_profile 'export QT_QPA_PLATFORMTHEME=qt6ct'
    add_line ~/.bash_profile 'export EDITOR=nvim'
    add_line ~/.bash_profile 'export VISUAL=nvim'
    add_line ~/.bashrc "alias ls='eza --icons=auto'"
    add_line ~/.bashrc 'eval "$(starship init bash)"'
    note "~/.bash_profile and ~/.bashrc: qt6ct, EDITOR=nvim, eza, starship"

    # Default apps: swayimg for images, kew for music, Dolphin for folders
    if command -v xdg-mime >/dev/null; then
        local apps=/usr/share/applications
        if [[ -f $apps/swayimg.desktop ]]; then
            # shellcheck disable=SC2046  # one argument per MIME type
            xdg-mime default swayimg.desktop $(grep -Po '(?<=^MimeType=).*' "$apps/swayimg.desktop" | tr ';' ' ')
        fi
        if [[ -f $apps/kew.desktop ]]; then
            # kew is a terminal app: a local copy of its desktop entry starts
            # it in kitty (xdg-open, yazi and browsers would run it invisibly)
            mkdir -p ~/.local/share/applications
            sed -e 's|^Exec=kew play %F$|Exec=kitty --class kew -e kew play %F|' -e 's|^Terminal=true$|Terminal=false|' \
                -e 's|^MimeType=.*|&audio/x-vorbis+ogg;audio/x-opus+ogg;|' \
                "$apps/kew.desktop" > ~/.local/share/applications/kew.desktop
            xdg-mime default kew.desktop audio/mpeg audio/flac audio/x-flac audio/wav audio/x-wav audio/mp4 \
                audio/x-m4a audio/ogg audio/opus audio/webm audio/x-vorbis+ogg audio/x-opus+ogg
        fi
        [[ -f $apps/org.kde.dolphin.desktop ]] && xdg-mime default org.kde.dolphin.desktop inode/directory
        note "default apps: swayimg (images), kew (music), Dolphin (folders)"
    fi

    # Black hole settings in the launcher; Sway's PATH has no ~/.local/bin, so the full path
    mkdir -p ~/.local/share/applications
    sed "s|^Exec=.*|Exec=$HOME/.local/bin/blackhole-settings|" "$repo/blackhole/blackhole-settings.desktop" \
        > ~/.local/share/applications/blackhole-settings.desktop
    note "launcher entry: Black Hole (wallpaper settings)"

    # Dolphin uses the KDE color scheme from this repo
    if command -v kwriteconfig6 >/dev/null; then
        kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme PurpleMocha
        note "Dolphin: color scheme PurpleMocha"
    fi

    # Lock screen sigil, made from this machine's ID
    if [[ ! -e ~/.config/hypr/sigil.png ]] && command -v magick >/dev/null; then
        ~/.config/hypr/make-sigil.sh >/dev/null
        note "lock screen sigil created"
    fi

    # The Waybar clock uses the German locale and is hidden without it
    if ! locale -a 2>/dev/null | grep -qx 'de_DE.utf8'; then
        if command -v sudo >/dev/null; then
            sudo sed -i 's/^#\(de_DE\.UTF-8 UTF-8\)/\1/' /etc/locale.gen && sudo locale-gen >/dev/null
            note "locale de_DE.UTF-8 generated (Waybar clock)"
        else
            note "generate de_DE.UTF-8 (/etc/locale.gen, locale-gen), otherwise Waybar hides the clock"
        fi
    fi
}

install_nvim_plugins() {
    command -v nvim >/dev/null || return 0
    info "Installing the Neovim plugins (versions from lazy-lock.json, takes a moment)"
    # The first start installs the plugins, but some in their newest version,
    # and rewrites lazy-lock.json. So keep the file and restore its versions.
    local lock=~/.config/nvim/lazy-lock.json saved
    saved=$(mktemp)
    cp "$lock" "$saved"
    nvim --headless "+Lazy! install" +qa >/dev/null 2>&1 || true
    cp "$saved" "$lock"
    rm "$saved"
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || note "failed, Neovim installs them on its first start"
}

enable_services() {
    info "Enabling services: NetworkManager, Bluetooth, TLP, ly (login on tty1)"
    sudo systemctl enable NetworkManager.service bluetooth.service tlp.service tlp-pd.service ly@tty1.service
    local s
    for s in iwd systemd-networkd dhcpcd; do
        if systemctl is-enabled --quiet "$s.service" 2>/dev/null; then
            note "$s is enabled too and would fight with NetworkManager: sudo systemctl disable $s"
        fi
    done
}

for arg in "$@"; do
    case $arg in
        --copy) copy=1 ;;
        --no-packages) packages=0 ;;
        --no-services) services=0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $arg (see --help)" ;;
    esac
done

((EUID != 0)) || die "run this as your normal user, not as root"
[[ -f /etc/arch-release ]] || die "this script is made for Arch Linux"
if ((packages || services)) && ! command -v sudo >/dev/null; then
    die "sudo is missing: as root run 'pacman -S sudo' and allow your user (group wheel, visudo)"
fi

((packages)) && install_packages
install_configs
apply_settings
((packages)) && install_nvim_plugins
((services)) && enable_services

info "Done"
[[ -d $backup ]] && note "your old configs are in $backup"
note "reboot, log in with ly and choose Sway"
