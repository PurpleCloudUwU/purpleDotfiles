#!/bin/sh
# Started from sway (exec_always): restarts the daemon so config changes apply.
eww kill 2>/dev/null
sleep 0.5
setsid -f eww daemon >/dev/null 2>&1
sleep 1
eww open-many clock music stats
