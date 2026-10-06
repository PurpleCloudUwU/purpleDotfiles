#!/usr/bin/env bash
# Waybar-Statusmodul: zeigt verbundene Kopfhoerer mit Akkustand.
# Leerer Text = Modul wird in Waybar ausgeblendet.

icon=$''   # Font Awesome: headphones

# bluetoothctl wartet endlos, wenn bluetoothd nicht laeuft -> begrenzen
bt() { timeout 2 bluetoothctl "$@" 2>/dev/null; }

while read -r _ mac name; do
    info=$(bt info "$mac")

    # Nur Kopfhoerer/Headsets (Regex bei Bedarf erweitern, z. B. |audio-card)
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

    # jq uebernimmt das JSON-Escaping, pango() das fuer Waybar (z. B. "&" im Geraetenamen)
    jq -cn --arg text "$text" --arg tip "$tip" --arg class "$class" '
        def pango: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
        {text: ($text | pango), tooltip: ($tip | pango), class: $class}'
    exit 0
done < <(bt devices Connected)

# Nichts verbunden -> ausblenden
printf '{"text":""}\n'
