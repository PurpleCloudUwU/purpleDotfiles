#!/usr/bin/env bash
# purpleDotfiles installer: the Mondbasis rice (Hyprland + Quickshell) for a
# fresh, minimal Arch Linux on the ThinkPad T580.
#
# Installs the programs, links the configs into place, writes the theme
# files (Violet) and enables the services. Run it as your normal user (not
# as root); sudo asks for your password where needed:
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
    # Compositor and the Hypr tools (lock, idle, polkit, night light)
    hyprland hyprlock hypridle hyprpolkitagent hyprsunset hyprshutdown
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xorg-xwayland
    # Bar, program select, PDA panels, widgets, notifications, OSD
    quickshell
    # Login manager (starts Hyprland and unlocks GNOME Keyring)
    ly gnome-keyring
    # Terminal, file manager, editor, system info
    foot yazi neovim fastfetch btop eza zoxide fzf fd ripgrep jq 7zip
    # yazi previews
    chafa resvg ffmpegthumbnailer poppler imagemagick
    # Audio and media keys
    pipewire pipewire-pulse pipewire-alsa wireplumber playerctl pavucontrol
    # WiFi, Bluetooth, battery, power profiles, brightness
    networkmanager bluez bluez-utils upower tlp tlp-pd brightnessctl
    # Screenshots, clipboard, notifications, helpers of the station script
    grim slurp wl-clipboard libnotify xdg-utils xdg-user-dirs glib2
    # Browser and music (Spotify, kew for local files)
    librewolf spotify-launcher kew
    # Fonts and dark GTK apps
    noto-fonts noto-fonts-emoji ttf-nerd-fonts-symbols adw-gtk-theme
    # Building AUR packages
    base-devel git curl unzip
)
# Pixel fonts from the AUR: Departure Mono (terminal), VT323 (displays,
# stand-in for Pocket), Silkscreen (small labels)
aur_pkgs=(otf-departure-mono-nerd ttf-vt323 ttf-silkscreen)

# Config folders: <repo>/<name> -> ~/.config/<name>
config_dirs=(hypr quickshell station foot yazi nvim fastfetch)
# Single files: <path in repo>:<destination>
config_files=(
    "station/bin/station:$HOME/.local/bin/station"
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

    info "Installing the pixel fonts from the AUR: ${aur_pkgs[*]}"
    "$helper" -S --needed "${aur_pkgs[@]}"
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

    # The task list on the desktop (only the first time)
    local tasks=${XDG_DATA_HOME:-$HOME/.local/share}/station/tasks.txt
    if [[ ! -e $tasks ]]; then
        mkdir -p "$(dirname "$tasks")"
        cp "$repo/station/tasks.txt" "$tasks"
    fi
}

apply_settings() {
    info "Applying the settings"

    # ~/.local/bin for the station script, the shell settings from the repo
    [[ -f ~/.bash_profile ]] || printf '%s\n' '[[ -f ~/.bashrc ]] && . ~/.bashrc' > ~/.bash_profile
    add_line ~/.bash_profile 'export PATH="$HOME/.local/bin:$PATH"'
    add_line ~/.bash_profile 'export EDITOR=nvim VISUAL=nvim'
    add_line ~/.bashrc '[[ -f ~/.config/station/shell.bash ]] && . ~/.config/station/shell.bash'
    note "~/.bash_profile and ~/.bashrc: PATH, EDITOR, prompt, aliases"

    # Theme files (foot, yazi, btop, fastfetch, hyprlock, prompt) and the
    # CRT shader. Violet and SUBTLE on the first run, the last choice after.
    chmod +x "$repo/station/bin/station" "$repo/quickshell/scripts/sysinfo.sh"
    "$repo/station/bin/station" init | sed 's/^/  -> /'

    # Dark GTK apps (Hyprland also sets the colour scheme on every start)
    local gtk
    for gtk in gtk-3.0 gtk-4.0; do
        mkdir -p ~/.config/$gtk
        if [[ ! -e ~/.config/$gtk/settings.ini ]]; then
            printf '%s\n' '[Settings]' 'gtk-theme-name=adw-gtk3-dark' 'gtk-application-prefer-dark-theme=1' > ~/.config/$gtk/settings.ini
        fi
    done
    note "GTK: adw-gtk3-dark"

    command -v xdg-user-dirs-update >/dev/null && xdg-user-dirs-update
    if command -v xdg-settings >/dev/null && [[ -f /usr/share/applications/librewolf.desktop ]]; then
        xdg-settings set default-web-browser librewolf.desktop 2>/dev/null && note "default browser: LibreWolf"
    fi

    fc-cache -f >/dev/null 2>&1 || true
    if ! fc-list 2>/dev/null | grep -qi pocket; then
        note "Pocket (the game's display font) is not installed, VT323 stands in. See the README."
    fi
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
((services)) && enable_services

info "Done"
[[ -d $backup ]] && note "your old configs are in $backup"
note "reboot, log in with ly and choose Hyprland"
note "fingerprint (T580 only): ~/purpleDotfiles/fingerprint/setup.sh"
