#!/usr/bin/env bash
# Text sources for hyprlock.
# Usage: lock-info.sh date | sky | moon | status | sigil

# Start of the "planetary hours" (roughly sunrise; set it later in autumn/winter)
SUNRISE="07:30"

ordinal() {
    local d=$1
    if (( d % 100 >= 11 && d % 100 <= 13 )); then echo "${d}th"; return; fi
    case $((d % 10)) in
        1) echo "${d}st" ;;
        2) echo "${d}nd" ;;
        3) echo "${d}rd" ;;
        *) echo "${d}th" ;;
    esac
}

case $1 in
    date)
        d=$(date +%-d)
        echo "$(LC_ALL=C date +%A), the $(ordinal "$d") of $(LC_ALL=C date +%B)"
        ;;

    sky)
        # Day ruler by weekday (0 = Sunday)
        day_ruler=(Sun Moon Mars Mercury Jupiter Venus Saturn)
        # Chaldean order for the hour rulers
        chaldean=(Saturn Jupiter Mars Sun Venus Mercury Moon)

        wd=$(date +%w)
        now=$(( 10#$(date +%H) * 60 + 10#$(date +%M) ))
        sr=$(( 10#${SUNRISE%:*} * 60 + 10#${SUNRISE#*:} ))

        if (( now < sr )); then
            wd=$(( (wd + 6) % 7 ))       # before sunrise it still counts as the previous day
            since=$(( now + 1440 - sr ))
        else
            since=$(( now - sr ))
        fi
        hour_idx=$(( since / 60 ))

        ruler=${day_ruler[$wd]}
        for i in "${!chaldean[@]}"; do
            [[ ${chaldean[$i]} == "$ruler" ]] && start=$i
        done
        hour_ruler=${chaldean[$(( (start + hour_idx) % 7 ))]}
        echo "Day of the ${ruler}, hour of ${hour_ruler}"
        ;;

    moon)
        awk -v n="$(date +%s)" 'BEGIN {
            p = 29.530588
            a = (n - 947182440) / 86400
            a = a - p * int(a / p)
            printf "Moon %s, %d days old\n", (a < p / 2) ? "waxing" : "waning", a
        }'
        ;;

    status)
        now=$(cat /sys/class/power_supply/BAT*/energy_now 2>/dev/null | awk '{s+=$1} END{print s+0}')
        full=$(cat /sys/class/power_supply/BAT*/energy_full 2>/dev/null | awk '{s+=$1} END{print s+0}')
        pct=0
        (( full > 0 )) && pct=$(( now * 100 / full ))
        up=$(cut -d. -f1 /proc/uptime)
        echo "Hp:${pct}(100)  T:${up}"
        ;;

    sigil)
        fp=$(sha256sum /etc/machine-id | cut -d' ' -f1 | xxd -r -p | base64 | tr -d '=+/\n')
        echo "SHA256:${fp:0:5}...${fp: -3}"
        ;;
esac
