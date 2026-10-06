#!/usr/bin/env bash
# Creates a symmetric 5x5 pixel sigil from the machine-id.
# Run once; the result is saved to ~/.config/hypr/sigil.png

out="$HOME/.config/hypr/sigil.png"
fg="#b794f6"     # Sigil color (violet)
bg="#12101a"     # Background

mkdir -p "$(dirname "$out")"
hash=$(sha256sum /etc/machine-id | cut -d' ' -f1)

cmd=(magick -size 5x5 "xc:$bg" -fill "$fg")
for y in 0 1 2 3 4; do
    for x in 0 1 2; do
        nibble=$(( 0x${hash:$(( y * 3 + x )):1} ))
        if (( nibble % 2 == 0 )); then
            cmd+=(-draw "point $x,$y" -draw "point $(( 4 - x )),$y")
        fi
    done
done

# 5x5 -> 120x120 without smoothing (each pixel 24x24)
"${cmd[@]}" -scale 2400% "$out"
echo "Siegel erstellt: $out"
