#!/usr/bin/env python3
"""Starship config with yami's current palette.

    palette.py TEMPLATE PALETTE OUT

TEMPLATE is starship.toml next to this file, PALETTE yami's palette.json
(~/.local/state/yami/palette.json), OUT the copy starship reads
(STARSHIP_CONFIG). The [palettes.yami] table at the end of the template gets
yami's colours (camelCase keys in lower case: textDim -> textdim); keys yami
does not have keep their value from the template. A missing or broken
palette file leaves the template's colours. OUT is replaced atomically, so a
prompt drawn at the same moment never reads half a file.
"""
import json
import os
import re
import sys
import tomllib
from pathlib import Path

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
HEADER = "[palettes.yami]"


def main():
    tpl, pal, out = map(Path, sys.argv[1:4])
    text = tpl.read_text()
    head, sep, block = text.partition(HEADER)
    if not sep or "\n[" in block:
        sys.exit(f"{tpl}: [palettes.yami] must be the last table")

    colours = tomllib.loads(text)["palettes"]["yami"]
    try:
        yami = json.loads(pal.read_text())
    except (OSError, ValueError):
        yami = {}
    for key, value in yami.items():
        if isinstance(value, str) and HEX.match(value) and key.lower() in colours:
            colours[key.lower()] = value.lower()

    lines = [HEADER] + [f'{k} = "{v}"' for k, v in colours.items()]
    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_name(out.name + ".tmp")
    tmp.write_text(head + "\n".join(lines) + "\n")
    os.replace(tmp, out)


if __name__ == "__main__":
    main()
