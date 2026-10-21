#!/usr/bin/env bash
# Locks the screen with blackhole-lock (animated black hole, see blackhole/).
# If it can't lock or dies while locked, hyprlock takes over the lock, so the
# screen never stays locked without a password field.
pgrep -f '/blackhole-lock( |$)' >/dev/null || pidof hyprlock >/dev/null && exit 0
~/.local/bin/blackhole-lock && exit 0
logger -t blackhole-lock "blackhole-lock failed (exit $?), hyprlock takes over"
exec hyprlock --immediate-render -q
