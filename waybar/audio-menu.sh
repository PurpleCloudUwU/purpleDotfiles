#!/usr/bin/env bash
# Audio menu for sway/Waybar (PipeWire), opened from bt-menu.sh.
#   audio-menu.sh   -> choose the default output device
# Requires: pipewire-pulse (pactl), jq, fuzzel, optional libnotify

MENU=(fuzzel --dmenu --width 55 --lines 8)

# Each notification replaces the previous one so they don't pile up in the history
NID=""
notify() {
    command -v notify-send >/dev/null || return
    NID=$(notify-send -a Audio -p ${NID:+-r "$NID"} "$1")
}

glyph() {
    case $1 in
        headphones)    printf '\U000F02CB' ;;  # nf-md-headphones
        bt-headset)    printf '\U000F02CE' ;;  # nf-md-headset
        bt-headphone)  printf '\U000F02CB' ;;
        bt-*)          printf '\U000F00AF' ;;  # nf-md-bluetooth
        hdmi)          printf '\U000F0379' ;;  # nf-md-monitor
        *)             printf '\U000F04C3' ;;  # nf-md-speaker
    esac
}

output_menu() {
    local default name label kind mark line choice
    local lines=()
    declare -A NAME_OF LABEL_OF

    default=$(pactl get-default-sink 2>/dev/null)

    # LC_ALL=C: English port names, translated below.
    # Fields separated by \x1f: name, display name, kind (for the icon)
    while IFS=$'\x1f' read -r name label kind; do
        case $label in
            "Laptop – Headphones") label="Laptop – Kopfhörer" ;;
            "Laptop – Speakers")   label="Laptop – Lautsprecher" ;;
        esac
        if [[ $name == "$default" ]]; then mark="●"; else mark="○"; fi
        line="$(glyph "$kind")  $mark $label"
        lines+=("$line")
        NAME_OF["$line"]=$name
        LABEL_OF["$line"]=$label
    done < <(LC_ALL=C pactl -f json list sinks 2>/dev/null | jq -r '
        .[] | .properties as $p | .active_port as $ap
        | ([.ports[]? | select(.name == $ap) | .description][0] // "") as $port
        | (if $p["device.bus"] == "bluetooth" then "bt-" + ($p["device.form_factor"] // "")
           elif ($ap // "") | test("headphones") then "headphones"
           elif ($ap // "") | test("speaker") then "speaker"
           elif .name | test("hdmi") then "hdmi"
           else "other" end) as $kind
        | (if $p["device.bus"] == "pci" and ($kind == "headphones" or $kind == "speaker")
           then "Laptop – " + $port else .description end) as $label
        | [.name, $label, $kind] | join("\u001f")')

    if (( ${#lines[@]} == 0 )); then
        notify "Keine Ausgabegeräte gefunden (läuft PipeWire?)"
        exit 1
    fi

    choice=$(printf '%s\n' "${lines[@]}" | "${MENU[@]}" --prompt="Ausgabe > ") || exit 0
    name=${NAME_OF[$choice]}
    [[ -n $name ]] || exit 0

    # WirePlumber moves running playback along unless a stream is pinned to a device
    if pactl set-default-sink "$name"; then
        notify "Ausgabe: ${LABEL_OF[$choice]}"
    else
        notify "Ausgabe wechseln fehlgeschlagen"
    fi
}

output_menu
