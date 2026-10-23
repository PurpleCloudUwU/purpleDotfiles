#!/usr/bin/env bash
# Expandable power menu for Waybar (own toggle instead of "drawer").
#   power-menu.sh status        -> icon on the far right (power or "<")
#   power-menu.sh toggle        -> expand/collapse the menu
#   power-menu.sh item NAME     -> entry (only visible while the menu is open)
#   power-menu.sh run NAME      -> close the menu and run the action
#   power-menu.sh blackhole     -> animated wallpaper on/off (menu stays open)

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-power-open"
SIGNAL=10   # must match "signal" in the Waybar modules
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/blackhole/settings.json"

is_open() { [[ -f $STATE ]]; }
refresh() { pkill -RTMIN+"$SIGNAL" waybar; }

json() { printf '{"text":"%s","tooltip":"%s"%s}\n' "$1" "$2" "$3"; }

# "enabled" in settings.json (missing = on); blackhole-wallpaper watches the file
blackhole_on() {
    ! grep -Eq '^  "enabled": false' "$SETTINGS" 2>/dev/null
}

case $1 in
    toggle)
        if is_open; then rm -f "$STATE"; else : > "$STATE"; fi
        refresh
        ;;

    status)
        if is_open; then
            json $'\uf104' "Close" ',"class":"open"'
        else
            json $'\uf011' "Power menu" ''
        fi
        ;;

    item)
        # Closed: empty text = module is hidden
        is_open || { printf '{"text":""}\n'; exit 0; }
        case $2 in
            lock)      json $'\uf023' "Lock" '' ;;
            reboot)    json $'\uf021' "Reboot" '' ;;
            suspend)   json $'\uf186' "Suspend" '' ;;
            poweroff)  json $'\uf011' "Shut down" '' ;;
            # nf-md-weather_hurricane: a small spiral as black hole
            blackhole)
                if blackhole_on; then
                    json $'\U000f0898' "Animated wallpaper: on" ',"class":"on"'
                else
                    json $'\U000f0898' "Animated wallpaper: off" ',"class":"off"'
                fi
                ;;
        esac
        ;;

    blackhole)
        mkdir -p "${SETTINGS%/*}"
        python3 - "$SETTINGS" <<'PY'
import json, os, sys
path = sys.argv[1]
try:
    data = json.load(open(path))
    data = data if isinstance(data, dict) else {}
except (FileNotFoundError, ValueError):
    data = {}
data["enabled"] = not data.get("enabled", True)
tmp = path + ".tmp"
with open(tmp, "w") as f:
    f.write(json.dumps(data, indent=2) + "\n")
os.replace(tmp, path)                     # atomic, like blackhole-settings
PY
        refresh
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
