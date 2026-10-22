#!/usr/bin/env bash
# Wi-Fi menu for sway/Waybar (NetworkManager).
# Requires: networkmanager (nmcli), fzf, kitty, tui-menu, optional libnotify

# Menu program: reads lines from stdin, prints the selection.
MENU=("${0%/*}/tui-menu" --width 45 --lines 10)

# Each notification replaces the previous one ("Connecting …" -> "Connected"),
# so they don't both end up in the notification history.
NID=""
notify() {
    command -v notify-send >/dev/null || return
    NID=$(notify-send -a Wi-Fi -p ${NID:+-r "$NID"} "$1")
}

# Free text input: ask "Prompt: " [--password]
ask() { "${MENU[@]}" --prompt-only="$1" "${@:2}" </dev/null; }

DEV=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}')

declare -A SSID_OF SAVED SIG SEC USE
LABELS=()

build_list() {
    local line type name inuse sig sec ssid mark lock saved label
    LABELS=(); SSID_OF=(); SAVED=(); SIG=(); SEC=(); USE=()

    # Saved Wi-Fi profiles (assumption: profile name = SSID)
    while IFS= read -r line; do
        type=${line##*:}
        name=${line%:*}; name=${name//\\:/:}
        [[ $type == 802-11-wireless ]] && SAVED["$name"]=1
    done < <(nmcli -g NAME,TYPE connection show)

    # Networks found; keep the strongest signal per SSID
    while IFS=: read -r inuse sig sec ssid; do
        ssid=${ssid//\\:/:}
        [[ -z $ssid || -z $sig ]] && continue
        if [[ -z ${SIG[$ssid]} || $sig -gt ${SIG[$ssid]} ]]; then
            SIG[$ssid]=$sig
            SEC[$ssid]=$sec
        fi
        [[ $inuse == '*' ]] && USE[$ssid]=1
    done < <(nmcli -g IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no)

    # Output sorted by signal
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
    notify "Connecting to $ssid …"

    if [[ -n ${SAVED[$ssid]} ]]; then
        if nmcli connection up id "$ssid" >/dev/null 2>&1; then
            notify "Connected to $ssid"
        else
            notify "Connecting to $ssid failed"
        fi
        return
    fi

    if [[ -n ${SEC[$ssid]} && ${SEC[$ssid]} != "--" ]]; then
        pw=$(ask "Password for $ssid: " --password) || return
        nmcli device wifi connect "$ssid" password "$pw" >/dev/null 2>&1
    else
        nmcli device wifi connect "$ssid" >/dev/null 2>&1
    fi

    if [[ $? -eq 0 ]]; then
        notify "Connected to $ssid"
    else
        # Remove the failed profile again (e.g. wrong password)
        nmcli connection delete id "$ssid" >/dev/null 2>&1
        notify "Connecting to $ssid failed (wrong password?)"
    fi
}

network_menu() {
    local ssid=$1 entries action
    if [[ -n ${USE[$ssid]} ]]; then
        entries=$'Disconnect'
        [[ -n ${SAVED[$ssid]} ]] && entries+=$'\nForget'
    elif [[ -n ${SAVED[$ssid]} ]]; then
        entries=$'Connect\nForget'
    else
        entries=$'Connect'
    fi

    action=$(printf '%s\n' "$entries" | "${MENU[@]}") || return

    case $action in
        Connect)
            connect_to "$ssid"
            ;;
        Disconnect)
            nmcli device disconnect "$DEV" >/dev/null 2>&1
            notify "Disconnected from $ssid"
            ;;
        Forget)
            if [[ $(printf 'Cancel\nYes, forget %s\n' "$ssid" | "${MENU[@]}") == Yes* ]]; then
                nmcli connection delete id "$ssid" >/dev/null 2>&1
                notify "Forgot $ssid"
            fi
            ;;
    esac
}

hidden_network() {
    local ssid pw
    ssid=$(ask "SSID: ") || return
    [[ -n $ssid ]] || return
    pw=$(ask "Password for $ssid: " --password) || return
    notify "Connecting to $ssid …"
    if nmcli device wifi connect "$ssid" password "$pw" hidden yes >/dev/null 2>&1; then
        notify "Connected to $ssid"
    else
        nmcli connection delete id "$ssid" >/dev/null 2>&1
        notify "Connecting to $ssid failed"
    fi
}

# LC_ALL=C: nmcli translates "enabled" in other languages (e.g. "aktiviert")
toggle_power() {
    if [[ $(LC_ALL=C nmcli radio wifi) == enabled ]]; then
        nmcli radio wifi off; notify "Wi-Fi off"
    else
        nmcli radio wifi on; notify "Wi-Fi on"
    fi
}

main() {
    local choice

    if [[ $(LC_ALL=C nmcli radio wifi) != enabled ]]; then
        printf '%s\n' "⏻ Turn Wi-Fi on" | "${MENU[@]}" >/dev/null || exit 0
        toggle_power
        exit 0
    fi

    # Start a scan in the background so the list is fresh next time
    nmcli device wifi rescan >/dev/null 2>&1 &

    build_list
    choice=$(printf '%s\n' "${LABELS[@]}" "↻ Rescan" "+ Hidden network" "⏻ Turn Wi-Fi off" | "${MENU[@]}") || exit 0

    case $choice in
        "↻ Rescan")
            notify "Scanning for networks …"
            nmcli device wifi rescan >/dev/null 2>&1
            sleep 3
            exec "$0"
            ;;
        "+ Hidden network") hidden_network ;;
        "⏻ Turn Wi-Fi off")     toggle_power ;;
        *) [[ -n ${SSID_OF[$choice]} ]] && network_menu "${SSID_OF[$choice]}" ;;
    esac
}

main
