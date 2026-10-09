#!/usr/bin/env bash
# Keyboard backlight to 100% (ThinkPad: tpacpi::kbd_backlight).
# Called at login, after waking from suspend (swayidle after-resume) and when
# the screen turns back on (screen.sh on, Super+O). brightnessctl goes through
# logind, so no root is needed.
brightnessctl -q -d '*::kbd_backlight' set 100%
