#!/usr/bin/env bash
# Benachrichtigungs-Verlauf fuer Waybar (mako).
#   notifications.sh         -> JSON fuer Waybar (Glocke, mit Punkt wenn etwas da ist)
#   notifications.sh menu    -> Fuzzel-Menue mit dem Verlauf, Nerd-Font-Icon je Programm (Auswahl kopiert den Text)
#   notifications.sh clear   -> Verlauf leeren
# Benoetigt: mako (makoctl), jq, fuzzel, optional wl-clipboard

MENU=(fuzzel --dmenu --width 70 --lines 10)
SIGNAL=11   # muss zu "signal" im Waybar-Modul und "on-notify" in der mako-Config passen

# makoctl kann den Verlauf nicht loeschen. Stattdessen merken wir uns die hoechste
# ID beim Leeren und zeigen nur neuere Benachrichtigungen an.
STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-notif-cleared"

BELL=$'\U000F009A'         # nf-md-bell
BELL_BADGE=$'\U000F116B'   # nf-md-bell_badge

refresh() { pkill -RTMIN+"$SIGNAL" waybar; }

# Setzt ALL (alle Benachrichtigungen) und ITEMS (nur die nicht geleerten),
# jeweils als JSON-Array, neueste zuerst.
load() {
    local list hist cleared=0 max
    list=$(makoctl list -j 2>/dev/null) && hist=$(makoctl history -j 2>/dev/null) || return 1
    ALL=$(printf '%s\n%s\n' "$list" "$hist" | jq -s 'add | unique_by(.id) | sort_by(-.id)')

    max=$(jq '.[0].id // 0' <<<"$ALL")
    [[ -f $STATE ]] && cleared=$(<"$STATE")
    # mako neu gestartet (IDs beginnen wieder bei 1) -> Grenze zuruecksetzen
    if (( max < cleared )); then cleared=0; rm -f "$STATE"; fi

    ITEMS=$(jq --argjson c "$cleared" 'map(select(.id > $c))' <<<"$ALL")
}

status() {
    local n
    if ! load; then
        printf '{"text":"%s","tooltip":"mako läuft nicht","class":"empty"}\n' "$BELL"
        return
    fi

    n=$(jq length <<<"$ITEMS")
    if (( n == 0 )); then
        printf '{"text":"%s","tooltip":"Keine Benachrichtigungen","class":"empty"}\n' "$BELL"
    else
        (( n == 1 )) && n="1 Benachrichtigung" || n="$n Benachrichtigungen"
        printf '{"text":"%s","tooltip":"%s\\nKlick: Verlauf · Rechtsklick: leeren","class":"has-notifications"}\n' \
            "$BELL_BADGE" "$n"
    fi
}

# Nerd-Font-Icon je Programm (Programmname oder .desktop-Eintrag), sonst Glocke.
# Fuer die Popups stehen die eigenen drei (WLAN, Bluetooth, Powerprofil) in der mako-Config.
glyph_for() {
    case "${1,,} ${2,,}" in
        *wlan*)                      printf '\U000F05A9' ;;  # nf-md-wifi
        *bluetooth*)                 printf '\U000F00AF' ;;  # nf-md-bluetooth
        *powerprofil*)               printf '\U000F04C5' ;;  # nf-md-speedometer
        *audio*)                     printf '\U000F04C3' ;;  # nf-md-speaker
        *mullvad*)                   printf '\U000F099D' ;;  # nf-md-shield_lock
        *claude*)                    printf '\U000F06A9' ;;  # nf-md-robot
        *vesktop*|*discord*)         printf '\U000F066F' ;;  # nf-md-discord
        *chatterino*|*twitch*)       printf '\U000F0543' ;;  # nf-md-twitch
        *brave*|*firefox*|*chrom*)   printf '\U000F059F' ;;  # nf-md-web
        *screenshot*|*grim*)         printf '\U000F0E51' ;;  # nf-md-monitor_screenshot
        *)                           printf '%s' "$BELL" ;;
    esac
}

menu() {
    local id text desktop_entry app_name label choice
    local labels=()
    local clear_entry=$'\U000F05E9  Verlauf leeren'   # nf-md-delete_sweep
    declare -A ID_OF
    load || exit 0

    # Eine Zeile pro Benachrichtigung: "Icon  App · Titel — Text" (Markup und Umbrueche entfernt).
    # Felder mit \x1f getrennt: anders als Tabs fasst read leere Felder dabei nicht zusammen.
    while IFS=$'\x1f' read -r id text desktop_entry app_name; do
        label="$(glyph_for "$app_name" "$desktop_entry")  $text"
        labels+=("$label")
        ID_OF["$label"]=$id
    done < <(jq -r '
        def clean: (. // "") | gsub("<[^>]*>"; "") | gsub("\\s+"; " ") | ltrimstr(" ") | rtrimstr(" ");
        .[] | (.body | clean) as $b
            | [ (.id | tostring),
                "\(.app_name | clean)  ·  \(.summary | clean)\(if $b != "" then "  —  " + $b else "" end)",
                (.desktop_entry // ""), (.app_name // "") ]
            | join("\u001f")
        ' <<<"$ITEMS")

    if (( ${#labels[@]} == 0 )); then
        printf '%s\n' "Keine Benachrichtigungen" | "${MENU[@]}" >/dev/null
        exit 0
    fi

    choice=$(printf '%s\n' "${labels[@]}" "$clear_entry" | "${MENU[@]}") || exit 0

    if [[ $choice == "$clear_entry" ]]; then
        clear_history
        return
    fi

    id=${ID_OF[$choice]}
    [[ -n $id ]] || exit 0
    text=$(jq -r --argjson id "$id" \
        '.[] | select(.id == $id) | [.summary, .body] | map(select(. != null and . != "")) | join("\n")' \
        <<<"$ITEMS")
    command -v wl-copy >/dev/null && printf '%s' "$text" | wl-copy
}

clear_history() {
    load || exit 0
    jq '.[0].id // 0' <<<"$ALL" > "$STATE"
    makoctl dismiss --all --no-history 2>/dev/null
    refresh
}

case $1 in
    menu)  menu ;;
    clear) clear_history ;;
    *)     status ;;
esac
