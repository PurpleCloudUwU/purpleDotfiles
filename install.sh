#!/usr/bin/env bash
# purpleDotfiles installer: niri with the yami desktop (bar, launcher, lock,
# notifications, files) for a fresh, minimal Arch Linux on the ThinkPad T580.
# No Qt anywhere: yami draws everything itself.
#
# Installs the programs, builds yami from source (yami/ in this repo),
# links the configs into place and enables the services. Run it as your
# normal user (not as root); sudo asks for your password where needed:
#   git clone https://github.com/PurpleCloudUwU/purpleDotfiles ~/purpleDotfiles
#   ~/purpleDotfiles/install.sh
#
# The configs are symlinked to this repo, so "git pull" updates them.
# Existing configs are moved to ~/dotfiles-backup-<date>/ first.
#
# Options:
#   --copy         copy the configs instead of symlinking them
#   --no-packages  don't install packages (only configs and settings)
#   --no-services  don't enable system services (NetworkManager, TLP, ...)
#   -h, --help     show this help
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
backup="$HOME/dotfiles-backup-$(date +%Y-%m-%d_%H%M%S)"
copy=0 packages=1 services=1

# yami: the fork in yami/ of this repo, and the look it starts with
yami_opts=(--yes --no-sudo --lang en --palette ash --font pixel --no-fork --no-login --no-count --no-anim)

# Programs from the official repos, grouped by what needs them. yami's own
# installer runs with --no-sudo: its package list would bring qt6ct and
# power-profiles-daemon (which fights tlp-pd), so the packages are here.
pacman_pkgs=(
    # Compositor, X11 apps, portals (yami answers file dialogs and screen
    # sharing itself, gnome and gtk do the rest)
    niri xwayland-satellite xdg-desktop-portal-gnome xdg-desktop-portal-gtk
    # Passwords for apps; polkit asks through the yami window
    gnome-keyring polkit
    # Building yami
    rust base-devel git curl unzip
    # What yami uses: clipboard history, screenshots, palette export, video,
    # drives, phones and network shares in yami-files
    cliphist wl-clipboard grim slurp python python-pillow mpv libarchive
    udisks2 gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc gvfs-smb
    # Terminals, prompt, file manager, editor, system info
    kitty foot starship yazi neovim fastfetch btop eza zoxide fzf fd ripgrep jq 7zip
    # yazi previews
    chafa resvg ffmpegthumbnailer poppler imagemagick
    # Audio, media keys, the equalizer in the music widget
    pipewire pipewire-pulse pipewire-alsa wireplumber libpulse playerctl pavucontrol cava
    # WiFi, Bluetooth, battery, power profiles (tlp-pd answers yami's
    # profile switch), brightness
    networkmanager bluez bluez-utils upower tlp tlp-pd brightnessctl
    # Helpers
    libnotify xdg-utils xdg-user-dirs glib2
    # Browser and music (Spotify, kew for local files)
    librewolf spotify-launcher kew
    # Fonts (yami brings its pixel fonts itself), GTK theme and icons
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-nerd-fonts-symbols adw-gtk-theme papirus-icon-theme
)
# From the AUR: Departure Mono (foot, Neovim)
aur_pkgs=(otf-departure-mono-nerd)

# Config folders: <repo>/<name> -> ~/.config/<name>
config_dirs=(foot yazi nvim bash starship)
# Single files: <path in repo>:<destination>. ~/.config/niri itself belongs
# to yami (the shell writes its files there), only user.kdl is ours.
config_files=(
    "niri/user.kdl:$HOME/.config/niri/user.kdl"
    "niri/desk-term-size:$HOME/.local/bin/desk-term-size"
    "niri/lock-at-login:$HOME/.local/bin/lock-at-login"
    # next to yami's 50-yami-pixel.conf; the folder itself is yami's
    "fontconfig/55-brave-no-pixel-font.conf:$HOME/.config/fontconfig/conf.d/55-brave-no-pixel-font.conf"
)
# Links the old Hyprland setup left behind
old_links=(
    "$HOME/.config/hypr" "$HOME/.config/quickshell" "$HOME/.config/station"
    "$HOME/.config/fastfetch" "$HOME/.local/bin/station"
)

info() { printf '\n\033[1;35m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
note() { printf '\033[1;33m  ->\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m==> Error:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    # The comment block at the top of this file, without the "# "
    sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d; s/^# \{0,1\}//'
}

# Moves whatever is at $1 into the backup folder
stash() {
    local dest=$1 rel
    rel=${dest#"$HOME"/}
    mkdir -p "$(dirname "$backup/$rel")"
    mv "$dest" "$backup/$rel"
    note "moved the old ~/$rel to $backup"
}

# Puts <repo>/$1 at $2 (symlink, or a copy with --copy). Whatever is already
# there is moved to the backup folder, unless it is already the right link.
place() {
    local src="$repo/$1" dest=$2
    if [[ -L $dest && $(readlink -f "$dest") == "$(readlink -f "$src")" ]]; then
        ((copy)) || return 0
        rm "$dest"
    elif [[ -e $dest || -L $dest ]]; then
        stash "$dest"
    fi
    mkdir -p "$(dirname "$dest")"
    if ((copy)); then cp -r "$src" "$dest"; else ln -s "$src" "$dest"; fi
}

# Appends a line to a file unless the file already has exactly that line
add_line() {
    grep -qxF -- "$2" "$1" 2>/dev/null || printf '%s\n' "$2" >> "$1"
}

install_packages() {
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

    info "Installing from the AUR: ${aur_pkgs[*]}"
    "$helper" -S --needed "${aur_pkgs[@]}"
}

drop_old_links() {
    local l
    for l in "${old_links[@]}"; do
        if [[ -L $l && $(readlink "$l") == "$repo"/* ]]; then
            rm "$l"
            note "removed the old link ~/${l#"$HOME"/}"
        fi
    done
}

# yami from source, the fork in yami/ (my fixes are committed there); its
# installer builds the shell, yami-files, yami-view and yami-play into
# ~/.local/bin and writes the niri, kitty and fastfetch configs. Later runs
# rebuild from the same tree (settings → updates can also do it from a tag).
install_yami() {
    info "Building and installing yami (a few minutes)"
    note "yami $(cat "$repo/yami/VERSION") from $repo/yami"
    "$repo/yami/install.sh" "${yami_opts[@]}" ||
        die "the yami installer failed, see ~/.cache/yami/install.log"

    # The layout lives in niri/user.kdl (de, nodeadkeys); the same here, so
    # the bar shows DE, and yami-binds.kdl written again with it
    ~/.local/bin/yami-shell config set kbLayout '"de"' >/dev/null
    ~/.local/bin/yami-shell binds write

    # focus-follows-mouse only in tiling mode: desk-term-size sets it in
    # ~/.local/state/desk-mode.kdl, and niri cannot switch it off in a later
    # file, so it comes out of yami's config.kdl (written again by updates)
    sed -i -E 's|^([[:space:]]*)(focus-follows-mouse\b.*)$|\1// \2   // purpleDotfiles: set by desk-term-size|' \
        ~/.config/niri/config.kdl
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

    # btop writes its whole config back on exit, so it gets a copy
    if [[ ! -e ~/.config/btop/btop.conf ]] || ! cmp -s "$repo/btop/btop.conf" ~/.config/btop/btop.conf; then
        [[ -e ~/.config/btop/btop.conf ]] && stash ~/.config/btop/btop.conf
        mkdir -p ~/.config/btop
        cp "$repo/btop/btop.conf" ~/.config/btop/btop.conf
    fi

    if command -v niri >/dev/null; then
        niri validate -c ~/.config/niri/config.kdl
    fi
}

apply_settings() {
    info "Applying the settings"

    [[ -f ~/.bash_profile ]] || printf '%s\n' '[[ -f ~/.bashrc ]] && . ~/.bashrc' > ~/.bash_profile
    add_line ~/.bash_profile 'export PATH="$HOME/.local/bin:$PATH"'
    add_line ~/.bash_profile 'export EDITOR=nvim VISUAL=nvim'
    # tty1 logs in on its own (login/autologin.conf) and starts niri, which
    # locks at once: the yami lock screen is the login screen. Only in an
    # interactive shell: niri-session re-runs itself through a login shell,
    # which reads this file again (without the check it loops forever)
    sed -i '\|^\[\[ -z \$WAYLAND_DISPLAY .* exec niri-session$|d' ~/.bash_profile
    add_line ~/.bash_profile '[[ $- == *i* && -z $WAYLAND_DISPLAY && $XDG_VTNR == 1 && -z $SSH_TTY ]] && exec niri-session'
    # the station line of the old setup goes
    sed -i '\|~/.config/station/shell.bash|d' ~/.bashrc 2>/dev/null || true
    add_line ~/.bashrc '[[ -f ~/.config/bash/shell.bash ]] && . ~/.config/bash/shell.bash'
    note "~/.bash_profile and ~/.bashrc: PATH, EDITOR, prompt, aliases"

    # GTK in the yami palette: the part of yami's tools/apply-theme.sh that
    # does not need root (the rest of it is qt6ct). yami's installer has
    # written gtk.css, the fonts and the pixel cursor already; this picks
    # the base theme and the icons.
    local v ini kv k
    for v in 3.0 4.0; do
        mkdir -p ~/.config/gtk-$v
        ini=~/.config/gtk-$v/settings.ini
        [[ -f $ini ]] || printf '[Settings]\n' > "$ini"
        for kv in "gtk-theme-name=adw-gtk3-dark" "gtk-application-prefer-dark-theme=true" \
            "gtk-icon-theme-name=Papirus-Dark" "gtk-enable-animations=0"; do
            k=${kv%%=*}
            if grep -q "^$k=" "$ini"; then sed -i "s|^$k=.*|$kv|" "$ini"; else printf '%s\n' "$kv" >> "$ini"; fi
        done
    done
    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
        # No GTK animations; browsers read this as "reduce motion" too
        gsettings set org.gnome.desktop.interface enable-animations false
    fi
    note "GTK: adw-gtk3-dark in the yami palette, Papirus icons"

    command -v xdg-user-dirs-update >/dev/null && xdg-user-dirs-update
    if command -v xdg-settings >/dev/null && [[ -f /usr/share/applications/librewolf.desktop ]]; then
        xdg-settings set default-web-browser librewolf.desktop 2>/dev/null && note "default browser: LibreWolf"
    fi

    fc-cache -f >/dev/null 2>&1 || true
}

enable_services() {
    info "Enabling services: NetworkManager, Bluetooth, TLP"
    sudo systemctl enable NetworkManager.service bluetooth.service tlp.service tlp-pd.service
    # login screen: autologin on tty1, niri starts locked (see login/)
    sed "s/USER/$USER/" "$repo/login/autologin.conf" |
        sudo install -Dm644 /dev/stdin /etc/systemd/system/getty@tty1.service.d/autologin.conf
    touch ~/.hushlogin   # no motd or "Last login" on the tty before niri
    note "tty1 logs in on its own, the yami lock screen asks for the password"
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
drop_old_links
install_yami
install_configs
apply_settings
((services)) && enable_services

info "Done"
[[ -d $backup ]] && note "your old configs are in $backup"
note "log in on a TTY and run: niri-session"
note "fingerprint (T580 only): ~/purpleDotfiles/fingerprint/setup.sh"
