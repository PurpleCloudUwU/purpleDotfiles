#!/usr/bin/env bash
# Power profile switcher for TLP (tlp-pd / tlpctl).
#   power-profile.sh        -> JSON for Waybar (icon + tooltip)
#   power-profile.sh menu   -> fzf menu to switch

MENU=("${0%/*}/tui-menu" --width 30 --lines 3)
SIGNAL=9   # must match "signal" in the Waybar module

notify() { command -v notify-send >/dev/null && notify-send -a "Power Profile" "$1"; }

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
        *)           icon=$'\uf128'; label="Unknown" ;;
    esac
    printf '{"text":"%s","tooltip":"Profile: %s","class":"%s"}\n' "$icon" "$label" "$p"
}

menu() {
    local cur entry id name mark label choice now
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

    if ! tlpctl "$id" >/dev/null 2>&1; then
        notify "Switching failed (is tlp-pd running?)"
        exit 1
    fi

    # tlpctl returns before TLP has applied the profile, and tlp-pd only
    # reports the new one afterwards. Wait for it, otherwise Waybar reads
    # the old profile and shows it until the next interval. Max. 30 s:
    # a hanging device (e.g. Thunderbolt resume) can block TLP for ~20 s.
    for _ in {1..300}; do
        now=$(get_profile)
        [[ $now == "$id" ]] && break
        sleep 0.1
    done
    pkill -RTMIN+"$SIGNAL" waybar

    if [[ $now == "$id" ]]; then
        notify "Profile: ${choice#??}"
    else
        notify "Switch not confirmed (active: $now)"
    fi
}

case $1 in
    menu) menu ;;
    *)    status ;;
esac
