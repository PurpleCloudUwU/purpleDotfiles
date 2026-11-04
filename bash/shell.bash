# Shell settings, sourced from ~/.bashrc (install.sh adds the line:
#   [[ -f ~/.config/bash/shell.bash ]] && . ~/.config/bash/shell.bash)

[[ $- == *i* ]] || return

# The window title is the folder (the yami bar shows it in the task list)
__title_prompt() {
    printf '\e]2;%s\a' "${PWD/#$HOME/\~}"
}
PROMPT_COMMAND+=(__title_prompt)

# Prompt: starship in the yami palette (starship/starship.toml). The linux
# console has neither its colours nor its characters, so it keeps the plain
# user@host ~/dots $ in the old Violet colours.
if [[ $TERM != linux ]] && command -v starship >/dev/null; then
    export STARSHIP_CONFIG=${XDG_CACHE_HOME:-$HOME/.cache}/starship/yami.toml
    # Before every prompt: a new config when yami wrote a new palette
    # (Mod+S → color) or the template changed, else only two date checks
    __starship_palette() {
        local tpl=~/.config/starship/starship.toml
        local pal=${XDG_STATE_HOME:-$HOME/.local/state}/yami/palette.json
        if [[ ! -f $STARSHIP_CONFIG || $pal -nt $STARSHIP_CONFIG || $tpl -nt $STARSHIP_CONFIG ]]; then
            python3 -I ~/.config/starship/palette.py "$tpl" "$pal" "$STARSHIP_CONFIG"
        fi
    }
    starship_precmd_user_func=__starship_palette
    eval "$(starship init bash)"
else
    PS1='\[\e[38;2;155;123;255m\]\u@\h\[\e[0m\] \[\e[38;2;138;141;170m\]\w\[\e[0m\] \$ '
fi

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
