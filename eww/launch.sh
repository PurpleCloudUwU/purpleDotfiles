#!/bin/sh
# Started from sway (exec_always): restarts eww so config changes apply.
pkill -x eww   # all daemons, also ones started for another config path
sleep 0.5
setsid -f eww daemon >/dev/null 2>&1
sleep 1
eww open-many clock music stats
