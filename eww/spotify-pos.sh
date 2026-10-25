#!/bin/sh
# Playback position for the media player widget (polled every second):
# {"time", "total", "bar"} with "bar" as 16 text cells (▰▰▰▱▱▱)
pos=$(playerctl -p spotify position 2>/dev/null)
len=$(playerctl -p spotify metadata mpris:length 2>/dev/null)
pos=${pos%.*}; pos=${pos:-0}
len=$(( ${len:-0} / 1000000 ))

pct=0
[ "$len" -gt 0 ] && pct=$(( pos * 100 / len ))
filled=$(( pct * 16 / 100 ))
bar=""; i=0
while [ $i -lt 16 ]; do
    if [ $i -lt $filled ]; then bar="$bar▰"; else bar="$bar▱"; fi
    i=$((i + 1))
done
printf '{"time":"%d:%02d","total":"%d:%02d","bar":"%s"}\n' \
    $((pos / 60)) $((pos % 60)) $((len / 60)) $((len % 60)) "$bar"
