#!/usr/bin/env bash
# Screen off/on for swayidle, logged to the journal (journalctl -t swayidle).
#   screen.sh off|on
# Workaround for a swayidle bug (1.9): if an app takes a logind idle inhibitor
# while the screen is off (e.g. the Claude app's "Keep computer awake"),
# swayidle drops its timeouts without running the resume command, so the
# screen would stay black. While the screen is off, this watches for such an
# inhibitor and turns the screen back on itself (the lock screen stays).
log() { logger -t swayidle "$*"; }
screen_on() { swaymsg -r -t get_outputs | grep -q '"power": *true'; }
idle_inhibited() {
    busctl --system get-property org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager BlockInhibited 2>/dev/null | grep -qw idle
}

case $1 in
    off)
        log "screen off"
        swaymsg "output * power off" >/dev/null || log "screen off failed"
        # In the background, so swayidle (-w) doesn't wait for it
        (
            while sleep 2; do
                screen_on && exit   # normal wake-up, swayidle turned it on
                if idle_inhibited; then
                    log "idle inhibitor while the screen is off: screen on"
                    swaymsg "output * power on" >/dev/null
                    ~/.config/sway/kbd-light.sh
                    exit
                fi
            done
        ) </dev/null >/dev/null 2>&1 &
        ;;
    on)
        log "screen on"
        swaymsg "output * power on" >/dev/null || log "screen on failed"
        ~/.config/sway/kbd-light.sh
        ;;
esac
