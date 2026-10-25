#!/bin/sh
# Playback position for the media player widget (polled every second):
# {"pct", "time", "total"}
pos=$(playerctl -p spotify position 2>/dev/null)
len=$(playerctl -p spotify metadata mpris:length 2>/dev/null)
pos=${pos%.*}; pos=${pos:-0}
len=$(( ${len:-0} / 1000000 ))

pct=0
[ "$len" -gt 0 ] && pct=$(( pos * 100 / len ))
[ "$pct" -gt 100 ] && pct=100

printf '{"pct":%d,"time":"%d:%02d","total":"%d:%02d"}\n' \
    "$pct" $((pos / 60)) $((pos % 60)) $((len / 60)) $((len % 60))
