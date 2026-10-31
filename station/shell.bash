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
