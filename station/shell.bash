# Mondbasis shell settings, sourced from ~/.bashrc (install.sh adds the line:
#   [[ -f ~/.config/station/shell.bash ]] && . ~/.config/station/shell.bash)

[[ $- == *i* ]] || return

# Prompt in the theme colours: user@host ~/dots $
station_state=${XDG_STATE_HOME:-$HOME/.local/state}/station
[[ -f $station_state/prompt.sh ]] && . "$station_state/prompt.sh"

# The window title is the folder, the bar shows it as "TERMINAL — ~/dots"
PROMPT_COMMAND='printf "\e]2;%s\a" "${PWD/#$HOME/\~}"'${PROMPT_COMMAND:+"; $PROMPT_COMMAND"}

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
