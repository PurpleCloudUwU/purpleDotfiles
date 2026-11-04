# Shell settings, sourced from ~/.bashrc (install.sh adds the line:
#   [[ -f ~/.config/bash/shell.bash ]] && . ~/.config/bash/shell.bash)

[[ $- == *i* ]] || return

# The window title is the folder (the yami bar shows it in the task list)
__title_prompt() {
    printf '\e]2;%s\a' "${PWD/#$HOME/\~}"
}
PROMPT_COMMAND+=(__title_prompt)

# user@host ~/dots $ in the old Violet colours
PS1='\[\e[38;2;155;123;255m\]\u@\h\[\e[0m\] \[\e[38;2;138;141;170m\]\w\[\e[0m\] \$ '

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
