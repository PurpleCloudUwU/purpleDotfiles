# Mondbasis shell settings, sourced from ~/.bashrc (install.sh adds the line:
#   [[ -f ~/.config/station/shell.bash ]] && . ~/.config/station/shell.bash)

[[ $- == *i* ]] || return

station_state=${XDG_STATE_HOME:-$HOME/.local/state}/station

# Runs before every prompt, after Arch's own title (/etc/bash.bashrc):
# - the window title is the folder, the bar shows it as "TERMINAL — ~/dots"
# - after `station theme` the prompt takes the new colours (user@host ~/dots $)
__station_prompt() {
    local theme
    printf '\e]2;%s\a' "${PWD/#$HOME/\~}"
    read -r theme 2>/dev/null < "$station_state/theme" || return 0
    if [[ $theme != "${__station_theme:-}" ]]; then
        __station_theme=$theme
        [[ -f $station_state/prompt.sh ]] && . "$station_state/prompt.sh"
    fi
}
PROMPT_COMMAND+=(__station_prompt)

# fastfetch with the moon: fastfetch leaves a blank 18x9
# logo area (station writes it with the image, ~/.local/state/station/
# patch.six), this draws the sixel image into it afterwards. Narrow
# terminals get the logo on top of the info.
fastfetch() {
    local six=$station_state/patch.six out lines rows=9
    local -a pos=()
    ((COLUMNS < 60)) && pos=(--logo-position top)
    if (($#)) || [[ ! -t 1 || ! -f $six ]]; then
        command fastfetch "${pos[@]}" "$@"
        return
    fi
    # Without the empty lines fastfetch leaves after the colour bar, so the
    # output is exactly as tall as the image
    out=$(command fastfetch --pipe false "${pos[@]}" | awk '
        { l[NR] = $0 }
        END {
            n = NR
            while (n > 0) { s = l[n]; gsub(/\033\[[0-9;]*m/, "", s); if (s != "") break; n-- }
            for (i = 1; i < n; i++) print l[i]
            printf "%s\033[m", l[n]
        }')
    lines=$(printf '%s\n' "$out" | wc -l)
    printf '%s\n' "$out"
    # Up to the logo area, one column in (its padding), draw; the cursor
    # then sits below the image, so go down the rest of the way
    if ((lines >= rows && lines < LINES)); then
        printf '\e[%dA\r\e[1C' "$lines"
        cat "$six"
        if ((lines > rows)); then printf '\e[%dB' "$((lines - rows))"; fi
        printf '\r'
    fi
}

alias ls='eza --group-directories-first'
alias ll='eza -l --group-directories-first'
alias la='eza -la --group-directories-first'

# y: yazi that leaves the shell in the folder you quit in
y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd.XXXXXX)
    yazi "$@" --cwd-file="$tmp"
    if cwd=$(<"$tmp") && [[ -n $cwd && $cwd != "$PWD" ]]; then
        builtin cd -- "$cwd" || true
    fi
    rm -f -- "$tmp"
}

command -v zoxide >/dev/null && eval "$(zoxide init bash)"
