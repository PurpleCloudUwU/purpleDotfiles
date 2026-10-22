#!/usr/bin/env bash
# Notification history for Waybar (mako).
#   notifications.sh         -> JSON for Waybar (bell, with a dot when there is something)
#   notifications.sh menu    -> fzf menu with the history, Nerd Font icon per app (selecting copies the text)
#   notifications.sh clear   -> clear the history
# Requires: mako (makoctl), jq, fzf, kitty, tui-menu, optional wl-clipboard

MENU=("${0%/*}/tui-menu" --width 70 --lines 10)
SIGNAL=11   # must match "signal" in the Waybar module and "on-notify" in the mako config

# makoctl can't delete the history. Instead we remember the highest
# ID when clearing and only show newer notifications.
STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-notif-cleared"

BELL=$'\U000F009A'         # nf-md-bell
BELL_BADGE=$'\U000F116B'   # nf-md-bell_badge

refresh() { pkill -RTMIN+"$SIGNAL" waybar; }

# Sets ALL (all notifications) and ITEMS (only those not cleared),
# both as JSON arrays, newest first.
load() {
    local list hist cleared=0 max
    list=$(makoctl list -j 2>/dev/null) && hist=$(makoctl history -j 2>/dev/null) || return 1
    ALL=$(printf '%s\n%s\n' "$list" "$hist" | jq -s 'add | unique_by(.id) | sort_by(-.id)')

    max=$(jq '.[0].id // 0' <<<"$ALL")
    [[ -f $STATE ]] && cleared=$(<"$STATE")
    # mako restarted (IDs start at 1 again) -> reset the threshold
    if (( max < cleared )); then cleared=0; rm -f "$STATE"; fi

    ITEMS=$(jq --argjson c "$cleared" 'map(select(.id > $c))' <<<"$ALL")
}

status() {
    local n
    if ! load; then
        printf '{"text":"%s","tooltip":"mako is not running","class":"empty"}\n' "$BELL"
        return
    fi

    n=$(jq length <<<"$ITEMS")
    if (( n == 0 )); then
        printf '{"text":"%s","tooltip":"No notifications","class":"empty"}\n' "$BELL"
    else
        (( n == 1 )) && n="1 notification" || n="$n notifications"
        printf '{"text":"%s","tooltip":"%s\\nClick: history · Right click: clear","class":"has-notifications"}\n' \
            "$BELL_BADGE" "$n"
    fi
}

# Nerd Font icon per app (app name or .desktop entry), else the bell.
# For the popups, my own scripts (Wi-Fi, Bluetooth, Power Profile, Audio) are set in the mako config.
glyph_for() {
    case "${1,,} ${2,,}" in
        *wi-fi*|*wlan*)              printf '\U000F05A9' ;;  # nf-md-wifi
        *bluetooth*)                 printf '\U000F00AF' ;;  # nf-md-bluetooth
        *power\ profile*)            printf '\U000F04C5' ;;  # nf-md-speedometer
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
    local clear_entry=$'\U000F05E9  Clear history'   # nf-md-delete_sweep
    declare -A ID_OF
    load || exit 0

    # One line per notification: "Icon  App · Title — Body" (markup and line breaks removed).
    # Fields separated by \x1f: unlike tabs, read doesn't merge empty fields.
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
        printf '%s\n' "No notifications" | "${MENU[@]}" >/dev/null
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
