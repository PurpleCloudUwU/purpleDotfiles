#!/bin/sh
# Feeds services/Sys.qml: one line every 3 seconds with
#   cpu_total cpu_idle temperature(millidegrees) brightness max_brightness
#   mem_total_kb mem_available_kb uptime_s disk_used_pct
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

disk=0
tick=0
while :; do
    # The disk changes slowly: df every 30 seconds is enough
    if [ $((tick % 10)) -eq 0 ]; then
        disk=$(df -P / 2>/dev/null | awk 'NR==2 { sub("%", "", $5); print $5 }')
        [ -n "$disk" ] || disk=0
    fi
    tick=$((tick + 1))
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    temp=$(cat "$zone" 2>/dev/null || echo 0)
    if [ -n "$light" ]; then
        bright=$(cat "$light/brightness")
        max=$(cat "$light/max_brightness")
    else
        bright=0 max=0
    fi
    mem_total=0 mem_avail=0
    while read -r key value _; do
        case $key in
            MemTotal:) mem_total=$value ;;
            MemAvailable:) mem_avail=$value; break ;;
        esac
    done < /proc/meminfo
    read -r up _ < /proc/uptime
    echo "$((user + nice + system + idle + iowait + irq + softirq + steal)) $((idle + iowait)) $temp $bright $max $mem_total $mem_avail ${up%.*} $disk"
    sleep 3
done
