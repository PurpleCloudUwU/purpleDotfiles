#!/usr/bin/env bash
# Bluetooth-Menue fuer sway/Waybar.
# Benoetigt: bluez-utils, fuzzel, pipewire-pulse (pactl), optional libnotify

# Menue-Programm (liest Zeilen von stdin, gibt die Auswahl aus).
# Alternativen: (wofi --dmenu)  (rofi -dmenu)  (bemenu)
MENU=(fuzzel --dmenu --width 60 --lines 10)

# Muss zu "signal" im Waybar-Modul passen
SIGNAL=8

notify() { command -v notify-send >/dev/null && notify-send -a Bluetooth "$1"; }
refresh() { sleep 1; pkill -RTMIN+"$SIGNAL" waybar; }
is_connected() { bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes"; }

declare -A MAC_OF
LABELS=()

build_list() {
    local mac name label
    LABELS=(); MAC_OF=()
    while read -r _ mac name; do
        if is_connected "$mac"; then label="● $name"; else label="○ $name"; fi
        LABELS+=("$label")
        MAC_OF["$label"]=$mac
    done < <(bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices)
}

codec_menu() {
    local card="bluez_card.${1//:/_}" active key desc label choice
    local labels=()
    declare -A KEY_OF

    active=$(pactl list cards | awk -v c="$card" '
        /^Card #/ { on=0 }
        $1=="Name:" { on=($2==c) }
        on && /Active Profile:/ { print $3 }')

    while IFS=$'\t' read -r key desc; do
        [[ $key == off ]] && continue
        if [[ $key == "$active" ]]; then label="● $desc"; else label="○ $desc"; fi
        KEY_OF["$label"]=$key
        labels+=("$label")
    done < <(pactl list cards | awk -v c="$card" '
        /^Card #/ { on=0; prof=0 }
        $1=="Name:" { on=($2==c) }
        on && /^\tProfiles:/ { prof=1; next }
        on && /^\tActive Profile:/ { prof=0 }
        on && prof && /available: yes/ {
            line=$0; sub(/^[ \t]+/, "", line)
            key=line;  sub(/:.*/, "", key)
            desc=line; sub(/^[^:]*: /, "", desc); sub(/ \(sinks:.*/, "", desc)
            printf "%s\t%s\n", key, desc
        }')

    if [[ ${#labels[@]} -eq 0 ]]; then
        notify "Keine Profile gefunden (pactl / pipewire-pulse pruefen)"
        return
    fi

    choice=$(printf '%s\n' "${labels[@]}" | "${MENU[@]}") || return
    [[ -n ${KEY_OF[$choice]} ]] || return
    if pactl set-card-profile "$card" "${KEY_OF[$choice]}"; then
        notify "Profil: ${choice#??}"
    else
        notify "Profilwechsel fehlgeschlagen"
    fi
}

device_menu() {
    local mac=$1 name entries action
    name=$(bluetoothctl info "$mac" | sed -n 's/^[[:space:]]*Name: //p')

    if is_connected "$mac"; then
        entries=$'Trennen\nCodec / Profil wählen\nVergessen'
    else
        entries=$'Verbinden\nVergessen'
    fi

    action=$(printf '%s\n' "$entries" | "${MENU[@]}") || return

    case $action in
        Verbinden)
            notify "Verbinde $name …"
            if bluetoothctl connect "$mac" | grep -q "Connection successful"; then
                notify "$name verbunden"
            else
                notify "Verbinden mit $name fehlgeschlagen"
            fi
            ;;
        Trennen)
            bluetoothctl disconnect "$mac" >/dev/null
            notify "$name getrennt"
            ;;
        "Codec / Profil wählen")
            codec_menu "$mac"
            ;;
        Vergessen)
            if [[ $(printf 'Abbrechen\nJa, %s vergessen\n' "$name" | "${MENU[@]}") == Ja* ]]; then
                bluetoothctl remove "$mac" >/dev/null
                notify "$name vergessen"
            fi
            ;;
    esac
    refresh
}

pair_new() {
    local labels=() mac name paired choice
    declare -A NEW

    notify "Suche Geräte (10 s) – Gerät in den Kopplungsmodus versetzen"
    bluetoothctl --timeout 10 scan on >/dev/null 2>&1

    paired=$(bluetoothctl devices Paired 2>/dev/null)
    while read -r _ mac name; do
        grep -q "$mac" <<<"$paired" && continue
        [[ $name == "${mac//:/-}" ]] && continue   # Geraete ohne Namen ausblenden
        labels+=("$name  [$mac]")
        NEW["$name  [$mac]"]=$mac
    done < <(bluetoothctl devices)

    if [[ ${#labels[@]} -eq 0 ]]; then
        notify "Keine neuen Geräte gefunden"
        return
    fi

    choice=$(printf '%s\n' "${labels[@]}" | "${MENU[@]}") || return
    mac=${NEW[$choice]}
    [[ -n $mac ]] || return

    notify "Koppeln mit ${choice%  \[*} …"
    if bluetoothctl pair "$mac" | grep -q "Pairing successful"; then
        bluetoothctl trust "$mac" >/dev/null
        bluetoothctl connect "$mac" >/dev/null
        notify "Gekoppelt und verbunden"
    else
        notify "Koppeln fehlgeschlagen"
    fi
    refresh
}

toggle_power() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power off >/dev/null; notify "Bluetooth aus"
    else
        bluetoothctl power on >/dev/null; notify "Bluetooth an"
    fi
    refresh
}

main() {
    local choice
    build_list
    choice=$(printf '%s\n' "${LABELS[@]}" "+ Neues Gerät koppeln" "⏻ Bluetooth an/aus" | "${MENU[@]}") || exit 0

    case $choice in
        "+ Neues Gerät koppeln") pair_new ;;
        "⏻ Bluetooth an/aus")    toggle_power ;;
        *) [[ -n ${MAC_OF[$choice]} ]] && device_menu "${MAC_OF[$choice]}" ;;
    esac
}

main
