#!/usr/bin/env bash
# Expandable power menu for Waybar (own toggle instead of "drawer").
#   power-menu.sh status        -> icon on the far right (power or "<")
#   power-menu.sh toggle        -> expand/collapse the menu
#   power-menu.sh item NAME     -> entry (only visible while the menu is open)
#   power-menu.sh run NAME      -> close the menu and run the action

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-power-open"
SIGNAL=10   # must match "signal" in the Waybar modules

is_open() { [[ -f $STATE ]]; }
refresh() { pkill -RTMIN+"$SIGNAL" waybar; }

json() { printf '{"text":"%s","tooltip":"%s"%s}\n' "$1" "$2" "$3"; }

case $1 in
    toggle)
        if is_open; then rm -f "$STATE"; else : > "$STATE"; fi
        refresh
        ;;

    status)
        if is_open; then
            json $'\uf104' "Schließen" ',"class":"open"'
        else
            json $'\uf011' "Power-Menü" ''
        fi
        ;;

    item)
        # Closed: empty text = module is hidden
        is_open || { printf '{"text":""}\n'; exit 0; }
        case $2 in
            lock)      json $'\uf023' "Sperren" '' ;;
            reboot)    json $'\uf021' "Neustart" '' ;;
            suspend)   json $'\uf186' "Bereitschaft" '' ;;
            poweroff)  json $'\uf011' "Herunterfahren" '' ;;
        esac
        ;;

    run)
        rm -f "$STATE"
        refresh
        case $2 in
            lock)      ~/.config/sway/lock.sh ;;
            reboot)    systemctl reboot ;;
            suspend)   systemctl suspend ;;
            poweroff)  systemctl poweroff ;;
        esac
        ;;
esac
