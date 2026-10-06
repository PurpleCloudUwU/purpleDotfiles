#!/usr/bin/env bash
# Waybar status module: shows connected headphones with battery level.
# Empty text = module is hidden in Waybar.

icon=$''   # Font Awesome: headphones

# bluetoothctl waits forever if bluetoothd isn't running -> limit it
bt() { timeout 2 bluetoothctl "$@" 2>/dev/null; }

while read -r _ mac name; do
    info=$(bt info "$mac")

    # Only headphones/headsets (extend the regex if needed, e.g. |audio-card)
    grep -qE "Icon: audio-(headphones|headset)" <<<"$info" || continue

    bat=$(grep -oP 'Battery Percentage:.*\(\K[0-9]+' <<<"$info")

    if [[ -n $bat ]]; then
        text="$icon $bat%"
        tip="$name: $bat%"
    else
        text="$icon"
        tip="$name"
    fi

    class=""
    [[ -n $bat && $bat -le 20 ]] && class="low"

    # jq handles the JSON escaping, pango() the escaping for Waybar (e.g. "&" in device names)
    jq -cn --arg text "$text" --arg tip "$tip" --arg class "$class" '
        def pango: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
        {text: ($text | pango), tooltip: ($tip | pango), class: $class}'
    exit 0
done < <(bt devices Connected)

# Nothing connected -> hide
printf '{"text":""}\n'
