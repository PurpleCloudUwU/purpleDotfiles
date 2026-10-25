#!/bin/sh
# Spotify state for the media player widget, one JSON line per change:
# {"status","artist","title"}

# Without Spotify playerctl prints nothing; the empty title hides the widget
echo '{"status":"","artist":"","title":""}'

playerctl -p spotify --follow metadata --format '{{status}}	{{artist}}	{{title}}' 2>/dev/null |
while IFS='	' read -r status artist title; do
    jq -cn --arg status "$status" --arg artist "$artist" --arg title "$title" '{$status, $artist, $title}'
done
