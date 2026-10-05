#!/usr/bin/env bash
# WLAN-Menue fuer sway/Waybar (NetworkManager).
# Benoetigt: networkmanager (nmcli), fuzzel, optional libnotify

# Menue-Programm: liest Zeilen von stdin, gibt die Auswahl aus.
MENU=(fuzzel --dmenu --width 45 --lines 10)

notify() { command -v notify-send >/dev/null && notify-send -a WLAN "$1"; }

# Freitext-Eingabe (nur fuzzel): ask "Prompt: " [--password]
ask() { "${MENU[@]}" --prompt-only="$1" "${@:2}" </dev/null; }

DEV=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')

declare -A SSID_OF SAVED SIG SEC USE
LABELS=()

build_list() {
    local line type name inuse sig sec ssid mark lock saved label
    LABELS=(); SSID_OF=(); SAVED=(); SIG=(); SEC=(); USE=()

    # Gespeicherte WLAN-Profile (Annahme: Profilname = SSID)
    while IFS= read -r line; do
        type=${line##*:}
        name=${line%:*}; name=${name//\\:/:}
        [[ $type == 802-11-wireless ]] && SAVED["$name"]=1
    done < <(nmcli -g NAME,TYPE connection show)

    # Gefundene Netze; pro SSID das staerkste Signal behalten
    while IFS=: read -r inuse sig sec ssid; do
        ssid=${ssid//\\:/:}
        [[ -z $ssid || -z $sig ]] && continue
        if [[ -z ${SIG[$ssid]} || $sig -gt ${SIG[$ssid]} ]]; then
            SIG[$ssid]=$sig
            SEC[$ssid]=$sec
        fi
        [[ $inuse == '*' ]] && USE[$ssid]=1
    done < <(nmcli -g IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no)

    # Nach Signal sortiert ausgeben
    while IFS=$'\t' read -r sig ssid; do
        mark="○"; [[ -n ${USE[$ssid]} ]] && mark="●"
        lock=""; [[ -n ${SEC[$ssid]} && ${SEC[$ssid]} != "--" ]] && lock=$' \uf023'
        saved=""; [[ -n ${SAVED[$ssid]} ]] && saved=" ★"
        label="$mark $ssid  ${sig}%${lock}${saved}"
        LABELS+=("$label")
        SSID_OF["$label"]=$ssid
    done < <(for s in "${!SIG[@]}"; do printf '%s\t%s\n' "${SIG[$s]}" "$s"; done | sort -rn)
}

connect_to() {
    local ssid=$1 pw
    notify "Verbinde mit $ssid …"

    if [[ -n ${SAVED[$ssid]} ]]; then
        if nmcli connection up id "$ssid" >/dev/null 2>&1; then
            notify "Verbunden mit $ssid"
        else
            notify "Verbinden mit $ssid fehlgeschlagen"
        fi
        return
    fi

    if [[ -n ${SEC[$ssid]} && ${SEC[$ssid]} != "--" ]]; then
        pw=$(ask "Passwort für $ssid: " --password) || return
        nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1
    else
        nmcli device wifi connect "$ssid" >/dev/null 2>&1
    fi

    if [[ $? -eq 0 ]]; then
        notify "Verbunden mit $ssid"
    else
        # Fehlgeschlagenes Profil (z. B. falsches Passwort) wieder entfernen
        nmcli connection delete id "$ssid" >/dev/null 2>&1
        notify "Verbinden mit $ssid fehlgeschlagen (Passwort?)"
    fi
}

network_menu() {
    local ssid=$1 entries action
    if [[ -n ${USE[$ssid]} ]]; then
        entries=$'Trennen'
        [[ -n ${SAVED[$ssid]} ]] && entries+=$'\nVergessen'
    elif [[ -n ${SAVED[$ssid]} ]]; then
        entries=$'Verbinden\nVergessen'
    else
        entries=$'Verbinden'
    fi

    action=$(printf '%s\n' "$entries" | "${MENU[@]}") || return

    case $action in
        Verbinden)
            connect_to "$ssid"
            ;;
        Trennen)
            nmcli device disconnect "$DEV" >/dev/null 2>&1
            notify "Getrennt von $ssid"
            ;;
        Vergessen)
            if [[ $(printf 'Abbrechen\nJa, %s vergessen\n' "$ssid" | "${MENU[@]}") == Ja* ]]; then
                nmcli connection delete id "$ssid" >/dev/null 2>&1
                notify "$ssid vergessen"
            fi
            ;;
    esac
}

hidden_network() {
    local ssid pw
    ssid=$(ask "SSID: ") || return
    [[ -n $ssid ]] || return
    pw=$(ask "Passwort für $ssid: " --password) || return
    notify "Verbinde mit $ssid …"
    if nmcli device wifi connect "$ssid" password "$pw" hidden yes >/dev/null 2>&1; then
        notify "Verbunden mit $ssid"
    else
        nmcli connection delete id "$ssid" >/dev/null 2>&1
        notify "Verbinden mit $ssid fehlgeschlagen"
    fi
}

toggle_power() {
    if [[ $(nmcli radio wifi) == enabled ]]; then
        nmcli radio wifi off; notify "WLAN aus"
    else
        nmcli radio wifi on; notify "WLAN an"
    fi
}

main() {
    local choice

    if [[ $(nmcli radio wifi) != enabled ]]; then
        printf '%s\n' "⏻ WLAN einschalten" | "${MENU[@]}" >/dev/null || exit 0
        toggle_power
        exit 0
    fi

    # Scan im Hintergrund anstossen, damit die Liste beim naechsten Oeffnen frisch ist
    nmcli device wifi rescan >/dev/null 2>&1 &

    build_list
    choice=$(printf '%s\n' "${LABELS[@]}" "↻ Neu scannen" "+ Verstecktes Netzwerk" "⏻ WLAN ausschalten" | "${MENU[@]}") || exit 0

    case $choice in
        "↻ Neu scannen")
            notify "Suche Netzwerke …"
            nmcli device wifi rescan >/dev/null 2>&1
            sleep 3
            exec "$0"
            ;;
        "+ Verstecktes Netzwerk") hidden_network ;;
        "⏻ WLAN ausschalten")     toggle_power ;;
        *) [[ -n ${SSID_OF[$choice]} ]] && network_menu "${SSID_OF[$choice]}" ;;
    esac
}

main
