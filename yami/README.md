# yami (purpleDotfiles fork)

The pixel desktop shell for [niri](https://github.com/YaLTeR/niri) that runs my
ThinkPad T580: bar, launcher, dock, notifications, lock screen, widgets and
settings, plus the file manager (yami-files), image viewer (yami-view) and video
player (yami-play). Written in Rust, no Qt.

This is a fork of yami 2.4.3 (MIT, see `LICENSE`), kept inside
[purpleDotfiles](https://github.com/PurpleCloudUwU/purpleDotfiles). My fixes are
committed here directly; `CHANGELOG.md` lists them.

## Build and install

`../install.sh` (the dotfiles installer) runs it for you. By hand, from this folder:

```sh
./install.sh --yes --no-sudo --lang en --palette ash --font pixel --no-fork --no-login --no-count --no-anim
```

It builds the four programs into `~/.local/bin` (build cache `~/.cache/yami/target`)
and writes the niri, kitty and fastfetch configs. `./install.sh --update` rebuilds
from this tree and keeps every setting. `./install.sh --help` lists all options.

## Updates

Settings → updates and `yami update` check this repo
(github.com/PurpleCloudUwU/purpleDotfiles) for tags `vX.Y.Z` and build the newest
one from their own clone in `~/.local/share/yami/src`. To ship a change:

1. edit the code, bump `VERSION` and the crate versions in `shell/*/Cargo.toml`
2. commit, then `git tag vX.Y.Z && git push --tags`

Tags are installed unsigned until `keys/allowed_signers` holds a key.

## Layout

| Folder | What |
|---|---|
| `shell/` | Cargo workspace: `src` (yami-shell), `files`, `view`, `play`, `px` (shared drawing) |
| `config/` | niri, kitty, fontconfig, portal and desktop-file templates the installer writes |
| `fork/` | yami-niri, a patched niri (not used here: the packaged niri runs) |
| `tools/` | theme generator, GTK theme, checks |
| `fonts/` | the pixel fonts (OFL, licences next to them) |
| `docs/` | config keys, security notes |
