#!/bin/sh
# Feeds services/Sys.qml: one line every 3 seconds with
#   cpu_total cpu_idle temperature(millidegrees) brightness max_brightness
# A single long-running loop is cheaper than starting processes from QML.

zone=
for z in /sys/class/thermal/thermal_zone*; do
    [ "$(cat "$z/type" 2>/dev/null)" = x86_pkg_temp ] && zone=$z/temp && break
done
[ -n "$zone" ] || zone=/sys/class/thermal/thermal_zone0/temp

light=
for b in /sys/class/backlight/*; do
    [ -e "$b/brightness" ] && light=$b && break
done

while :; do
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    temp=$(cat "$zone" 2>/dev/null || echo 0)
    if [ -n "$light" ]; then
        bright=$(cat "$light/brightness")
        max=$(cat "$light/max_brightness")
    else
        bright=0 max=0
    fi
    echo "$((user + nice + system + idle + iowait + irq + softirq + steal)) $((idle + iowait)) $temp $bright $max"
    sleep 3
done
