#!/bin/sh
# German word clock for design 2: "es ist / zwanzig nach / elf" as JSON, in 5 minute steps.
h=$(date +%-H)
m=$(date +%-M)
m=$(( (m + 2) / 5 * 5 ))

case $m in
    0|60) phrase="" ;;
    5)  phrase="fünf nach" ;;
    10) phrase="zehn nach" ;;
    15) phrase="viertel nach" ;;
    20) phrase="zwanzig nach" ;;
    25) phrase="fünf vor halb" ;;
    30) phrase="halb" ;;
    35) phrase="fünf nach halb" ;;
    40) phrase="zwanzig vor" ;;
    45) phrase="viertel vor" ;;
    50) phrase="zehn vor" ;;
    55) phrase="fünf vor" ;;
esac
# From "fünf vor halb" on, the phrase names the next hour
[ "$m" -ge 25 ] && h=$((h + 1))
h=$(( (h + 11) % 12 + 1 ))

set -- eins zwei drei vier fünf sechs sieben acht neun zehn elf zwölf
eval hour=\${$h}

# JSON with one key per line: multi-line labels get cut off in eww
if [ -z "$phrase" ]; then
    [ "$hour" = eins ] && hour=ein
    printf '{"a":"es ist","b":"%s","c":"uhr"}\n' "$hour"
else
    printf '{"a":"es ist","b":"%s","c":"%s"}\n' "$phrase" "$hour"
fi
