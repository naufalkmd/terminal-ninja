[[ -o interactive ]] || return 0 2>/dev/null || exit 0

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

_terminal_ninja_root="$(cd -- "$(dirname -- "${(%):-%N}")" && pwd)"
export STARSHIP_CONFIG="${_terminal_ninja_root}/starship.toml"

_terminal_ninja_starship() {
    if (( $+commands[starship] )); then
        print -r -- "$commands[starship]"
        return 0
    fi

    if (( $+commands[starship.exe] )); then
        print -r -- "$commands[starship.exe]"
        return 0
    fi

    return 1
}

_terminal_ninja_reset_starship_zsh() {
    autoload -Uz add-zsh-hook

    add-zsh-hook -d precmd prompt_starship_precmd >/dev/null 2>&1 || true
    add-zsh-hook -d preexec prompt_starship_preexec >/dev/null 2>&1 || true

    if [[ -n "${__starship_preserved_zle_keymap_select:-}" ]]; then
        zle -N zle-keymap-select "$__starship_preserved_zle_keymap_select" 2>/dev/null || true
        unset __starship_preserved_zle_keymap_select
    elif [[ -v widgets[zle-keymap-select] ]]; then
        case "${widgets[zle-keymap-select]}" in
            user:starship_zle-keymap-select|user:starship_zle-keymap-select-wrapped)
                zle -D zle-keymap-select 2>/dev/null || true
                ;;
        esac
    fi

    unfunction prompt_starship_precmd prompt_starship_preexec starship_zle-keymap-select starship_zle-keymap-select-wrapped __starship_get_time >/dev/null 2>&1 || true
}

if _terminal_ninja_starship >/dev/null 2>&1 && [[ -f "$STARSHIP_CONFIG" ]]; then
    _terminal_ninja_starship_path="$(_terminal_ninja_starship)"
    _terminal_ninja_reset_starship_zsh
    eval "$("${_terminal_ninja_starship_path}" init zsh)"
fi

HISTSIZE=${HISTSIZE:-10000}
SAVEHIST=${SAVEHIST:-20000}
setopt APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

autoload -Uz compinit
if [[ -z "${_terminal_ninja_compinit_done:-}" ]]; then
    compinit -C
    typeset -g _terminal_ninja_compinit_done=1
fi

autoload -Uz up-line-or-beginning-search
autoload -Uz down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^L' clear-screen

alias ll='ls -lah --color=auto'
alias la='ls -A'
alias c='clear'

if grep --help 2>/dev/null | grep -q -- '--color'; then
    alias grep='grep --color=auto'
fi

function ..() {
    cd ..
}

function ...() {
    cd ../..
}

function ....() {
    cd ../../..
}

function mkcd() {
    [[ -n "$1" ]] || return 1
    mkdir -p -- "$1" && cd -- "$1"
}

function explore() {
    if (( $+commands[explorer.exe] )); then
        explorer.exe . >/dev/null 2>&1 &
    elif (( $+commands[xdg-open] )); then
        xdg-open . >/dev/null 2>&1 &
    fi
}

function publicip() {
    curl -fsSL https://api.ipify.org
    printf '\n'
}

function findfile() {
    [[ -n "$1" ]] || return 1
    find . -iname "*$1*" 2>/dev/null
}

function findinfiles() {
    [[ -n "$1" ]] || return 1
    if (( $+commands[rg] )); then
        rg --hidden --glob '!.git' -- "$1" "${2:-.}"
    else
        grep -RIn -- "$1" "${2:-.}"
    fi
}

function memorytop() {
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 11
}

function gs() {
    git status "$@"
}

function gaa() {
    git add .
}

function gc() {
    git commit -m "$*"
}

function gp() {
    git push "$@"
}
