#!/usr/bin/env bash
# Volume and brightness keys with a small on-screen display (SwayOSD, see
# swayosd/). SwayOSD changes the value itself and shows icon + bar.
#   osd.sh volume up|down|mute
#   osd.sh brightness up|down
# Volume up: +5 %, at most 100 %. It never lowers a volume that is already
# above 100 % (e.g. set higher in pavucontrol); then the OSD only shows it.
# Without a running swayosd-server the keys still work, just without OSD.

sink=@DEFAULT_AUDIO_SINK@
osd() { pgrep -x swayosd-server >/dev/null; }

volume() {
    local vol
    case $1 in
        up)
            vol=$(wpctl get-volume "$sink" | awk '{print $2}')   # "Volume: 0.35 [MUTED]" -> 0.35
            if awk -v v="$vol" 'BEGIN { exit !(v < 1.0) }'; then
                if osd; then swayosd-client --output-volume +5 --max-volume 100
                else wpctl set-volume -l 1.0 "$sink" 5%+; fi
            elif osd; then
                swayosd-client --custom-progress 1.0 --custom-icon audio-volume-high-symbolic
            fi ;;
        down)
            if osd; then swayosd-client --output-volume -5
            else wpctl set-volume "$sink" 5%-; fi ;;
        mute)
            if osd; then swayosd-client --output-volume mute-toggle
            else wpctl set-mute "$sink" toggle; fi ;;
    esac
}

brightness() {
    local step=+5
    [[ $1 == down ]] && step=-5
    if osd; then swayosd-client --brightness "$step"
    else brightnessctl -q set "${step#[+-]}%${step:0:1}"; fi   # +5 -> "5%+", -5 -> "5%-"
}

case $1 in
    volume)     volume "$2" ;;
    brightness) brightness "$2" ;;
esac
