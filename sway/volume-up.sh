#!/usr/bin/env bash
# Volume up key: +5 %, at most 100 %.
# "wpctl -l 1.0" alone would *lower* a volume that is already above 100 %
# (e.g. set higher in pavucontrol), so above 100 % this does nothing.

sink=@DEFAULT_AUDIO_SINK@
vol=$(wpctl get-volume "$sink" | awk '{print $2}')   # "Volume: 0.35 [MUTED]" -> 0.35

awk -v v="$vol" 'BEGIN { exit !(v < 1.0) }' && wpctl set-volume -l 1.0 "$sink" 5%+
