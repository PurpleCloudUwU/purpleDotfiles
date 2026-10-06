#!/usr/bin/env bash
# Power profile switcher for TLP (tlp-pd / tlpctl).
#   power-profile.sh        -> JSON for Waybar (icon + tooltip)
#   power-profile.sh menu   -> fuzzel menu to switch

MENU=(fuzzel --dmenu --width 30 --lines 3)
SIGNAL=9   # must match "signal" in the Waybar module

notify() { command -v notify-send >/dev/null && notify-send -a Powerprofil "$1"; }

valid() { [[ $1 == performance || $1 == balanced || $1 == power-saver ]]; }

get_profile() {
    local p
    # tlp-pd's D-Bus interface: fast, doesn't start Python like tlpctl
    p=$(busctl --system get-property org.freedesktop.UPower.PowerProfiles \
        /org/freedesktop/UPower/PowerProfiles \
        org.freedesktop.UPower.PowerProfiles ActiveProfile 2>/dev/null | cut -d'"' -f2)
    # Fallback: tlpctl
    valid "$p" || p=$(tlpctl get 2>/dev/null)
    valid "$p" && echo "$p" || echo "unknown"
}

status() {
    local p icon label
    p=$(get_profile)
    case $p in
        performance) icon=$'\uf135'; label="Performance" ;;   # rocket
        balanced)    icon=$'\uf24e'; label="Balanced" ;;      # scale
        power-saver) icon=$'\uf06c'; label="Power Saver" ;;   # leaf
        *)           icon=$'\uf128'; label="Unbekannt" ;;
    esac
    printf '{"text":"%s","tooltip":"Profil: %s","class":"%s"}\n' "$icon" "$label" "$p"
}

menu() {
    local cur entry id name mark label choice
    local labels=()
    declare -A ID_OF

    cur=$(get_profile)
    for entry in "performance:Performance" "balanced:Balanced" "power-saver:Power Saver"; do
        id=${entry%%:*}
        name=${entry#*:}
        if [[ $id == "$cur" ]]; then mark="●"; else mark="○"; fi
        label="$mark $name"
        ID_OF["$label"]=$id
        labels+=("$label")
    done

    choice=$(printf '%s\n' "${labels[@]}" | "${MENU[@]}") || exit 0
    id=${ID_OF[$choice]}
    [[ -n $id ]] || exit 0

    if tlpctl "$id" >/dev/null 2>&1; then
        notify "Profil: ${choice#??}"
    else
        notify "Wechsel fehlgeschlagen (läuft tlp-pd?)"
    fi
    pkill -RTMIN+"$SIGNAL" waybar
}

case $1 in
    menu) menu ;;
    *)    status ;;
esac
