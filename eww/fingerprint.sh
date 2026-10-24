#!/bin/sh
# Shows the fingerprint window while fprintd waits for a finger. The events
# come from fp-indicator.service (see ~/purpleDotfiles/fingerprint).
tail -n0 -F /run/fp-indicator/events 2>/dev/null | while read -r event; do
    case $event in
        start) eww open fingerprint ;;
        stop) eww close fingerprint ;;
    esac
done
