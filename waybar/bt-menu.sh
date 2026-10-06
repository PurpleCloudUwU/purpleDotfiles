#!/usr/bin/env bash
# Bluetooth-Menue fuer sway/Waybar.
# Benoetigt: bluez-utils, fuzzel, pipewire-pulse (pactl), optional libnotify

# Menue-Programm (liest Zeilen von stdin, gibt die Auswahl aus).
# Alternativen: (wofi --dmenu)  (rofi -dmenu)  (bemenu)
MENU=(fuzzel --dmenu --width 60 --lines 10)

# Muss zu "signal" im Waybar-Modul passen
SIGNAL=8

# Feste Menueeintraege mit Nerd-Font-Icon (zwei Leerzeichen wie bei den Geraetezeilen)
PAIR_ENTRY=$'\U000F0415  Neues Gerät koppeln'     # nf-md-plus
OFF_ENTRY=$'\U000F00B2  Bluetooth ausschalten'    # nf-md-bluetooth_off
ON_ENTRY=$'\U000F00AF  Bluetooth einschalten'     # nf-md-bluetooth
AUDIO_ENTRY=$'\U000F04C3  Audioausgabe'           # nf-md-speaker

# Untermenue fuer Ausgabegeraet und Qualitaet (liegt neben diesem Skript)
AUDIO_MENU="${0%/*}/audio-menu.sh"

# Jede Meldung ersetzt die vorherige ("Verbinde …" -> "verbunden"),
# damit nicht beide im Benachrichtigungs-Verlauf landen.
NID=""
notify() {
    command -v notify-send >/dev/null || return
    NID=$(notify-send -a Bluetooth -p ${NID:+-r "$NID"} "$1")
}
refresh() { sleep 1; pkill -RTMIN+"$SIGNAL" waybar; }
is_connected() { bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes"; }
is_powered() { bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; }

# Nerd-Font-Icon je Geraetetyp ("Icon:" aus bluetoothctl info), sonst Bluetooth-Symbol
device_glyph() {
    case $(sed -n 's/^[[:space:]]*Icon: //p' <<<"$1") in
        audio-headphones)           printf '\U000F02CB' ;;  # nf-md-headphones
        audio-headset)              printf '\U000F02CE' ;;  # nf-md-headset
        audio-card|audio-speakers)  printf '\U000F04C3' ;;  # nf-md-speaker
        input-mouse)                printf '\U000F037D' ;;  # nf-md-mouse
        input-keyboard)             printf '\U000F030C' ;;  # nf-md-keyboard
        input-gaming)               printf '\U000F0297' ;;  # nf-md-gamepad_variant
        phone)                      printf '\U000F011C' ;;  # nf-md-cellphone
        computer)                   printf '\U000F0322' ;;  # nf-md-laptop
        *)                          printf '\U000F00AF' ;;  # nf-md-bluetooth
    esac
}

declare -A MAC_OF
LABELS=()

build_list() {
    local mac name label info mark
    LABELS=(); MAC_OF=()
    while read -r _ mac name; do
        info=$(bluetoothctl info "$mac" 2>/dev/null)
        if grep -q "Connected: yes" <<<"$info"; then mark="●"; else mark="○"; fi
        label="$(device_glyph "$info")  $mark $name"
        LABELS+=("$label")
        MAC_OF["$label"]=$mac
    done < <(bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices)
}

codec_menu() {
    local card="bluez_card.${1//:/_}" active key desc label choice
    local labels=()
    declare -A KEY_OF

    # LC_ALL=C: pactl uebersetzt seine Ausgabe, das awk-Parsing braucht die englische
    active=$(LC_ALL=C pactl list cards | awk -v c="$card" '
        /^Card #/ { on=0 }
        $1=="Name:" { on=($2==c) }
        on && /Active Profile:/ { print $3 }')

    while IFS=$'\t' read -r key desc; do
        [[ $key == off ]] && continue
        if [[ $key == "$active" ]]; then label="● $desc"; else label="○ $desc"; fi
        KEY_OF["$label"]=$key
        labels+=("$label")
    done < <(LC_ALL=C pactl list cards | awk -v c="$card" '
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
    local labels=() mac name paired choice label
    declare -A NEW NAME_OF

    notify "Suche Geräte (10 s) – Gerät in den Kopplungsmodus versetzen"
    bluetoothctl --timeout 10 scan on >/dev/null 2>&1

    paired=$(bluetoothctl devices Paired 2>/dev/null)
    while read -r _ mac name; do
        grep -q "$mac" <<<"$paired" && continue
        [[ $name == "${mac//:/-}" ]] && continue   # Geraete ohne Namen ausblenden
        label="$(device_glyph "$(bluetoothctl info "$mac" 2>/dev/null)")  $name  [$mac]"
        labels+=("$label")
        NEW["$label"]=$mac
        NAME_OF["$label"]=$name
    done < <(bluetoothctl devices)

    if [[ ${#labels[@]} -eq 0 ]]; then
        notify "Keine neuen Geräte gefunden"
        return
    fi

    choice=$(printf '%s\n' "${labels[@]}" | "${MENU[@]}") || return
    mac=${NEW[$choice]}
    [[ -n $mac ]] || return

    notify "Koppeln mit ${NAME_OF[$choice]} …"
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
    if is_powered; then
        bluetoothctl power off >/dev/null; notify "Bluetooth aus"
    else
        # Ein rfkill-Block (z. B. Flugmodus) verhindert sonst "power on"
        rfkill unblock bluetooth 2>/dev/null
        if bluetoothctl power on >/dev/null; then
            notify "Bluetooth an"
        else
            notify "Bluetooth einschalten fehlgeschlagen"
        fi
    fi
    refresh
}

main() {
    local choice
    local entries=()

    # Die Audioausgabe ist immer waehlbar, auch ohne Bluetooth.
    # bluetoothctl wartet endlos, wenn bluetoothd nicht laeuft -> timeout
    if ! timeout 2 bluetoothctl show >/dev/null 2>&1; then
        notify "Bluetooth nicht verfügbar (läuft bluetoothd?)"
        entries=("$AUDIO_ENTRY")
    elif ! is_powered; then
        entries=("$ON_ENTRY" "$AUDIO_ENTRY")
    else
        build_list
        entries=("${LABELS[@]}" "$PAIR_ENTRY" "$AUDIO_ENTRY" "$OFF_ENTRY")
    fi

    choice=$(printf '%s\n' "${entries[@]}" | "${MENU[@]}") || exit 0

    case $choice in
        "$AUDIO_ENTRY") exec "$AUDIO_MENU" ;;
        "$PAIR_ENTRY")  pair_new ;;
        "$ON_ENTRY"|"$OFF_ENTRY") toggle_power ;;
        *) [[ -n ${MAC_OF[$choice]} ]] && device_menu "${MAC_OF[$choice]}" ;;
    esac
}

main
