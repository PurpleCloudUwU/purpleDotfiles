#!/usr/bin/env bash
# Waybar-Statusmodul: zeigt verbundene Kopfhoerer mit Akkustand.
# Leerer Text = Modul wird in Waybar ausgeblendet.

icon=$'\uf025'   # Font Awesome: headphones

while read -r _ mac name; do
    info=$(bluetoothctl info "$mac" 2>/dev/null)

    grep -q "Connected: yes" <<<"$info" || continue
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

    tip=${tip//\"/\\\"}
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tip" "$class"
    exit 0
done < <(bluetoothctl devices)

# Nichts verbunden -> ausblenden
printf '{"text":""}\n'
