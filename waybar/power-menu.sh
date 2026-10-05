#!/usr/bin/env bash
# Ausklappbares Power-Menue fuer Waybar (eigene Umschaltung statt "drawer").
#   power-menu.sh status        -> Symbol ganz rechts (Power oder "<")
#   power-menu.sh toggle        -> Menue ein-/ausklappen
#   power-menu.sh item NAME     -> Eintrag (nur sichtbar, wenn das Menue offen ist)
#   power-menu.sh run NAME      -> Menue schliessen und Aktion ausfuehren

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-power-open"
SIGNAL=10   # muss zu "signal" in den Waybar-Modulen passen

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
        # Geschlossen: leerer Text = Modul wird ausgeblendet
        is_open || { printf '{"text":""}\n'; exit 0; }
        case $2 in
            lock)      json $'\uf023' "Sperren" '' ;;
            reboot)    json $'\uf021' "Neustart" '' ;;
            hibernate) json $'\uf186' "Ruhezustand" '' ;;
            poweroff)  json $'\uf011' "Herunterfahren" '' ;;
        esac
        ;;

    run)
        rm -f "$STATE"
        refresh
        case $2 in
            lock)      hyprlock --immediate-render -q ;;
            reboot)    systemctl reboot ;;
            hibernate) systemctl hibernate ;;
            poweroff)  systemctl poweroff ;;
        esac
        ;;
esac
