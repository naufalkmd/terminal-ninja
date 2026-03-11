case $- in
    *i*) ;;
    *) return 0 2>/dev/null || exit 0 ;;
esac

if [ -n "${TERMINAL_NINJA_BASH_LOADED:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
export TERMINAL_NINJA_BASH_LOADED=1
export PATH="$HOME/.local/bin:$PATH"

_terminal_ninja_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export STARSHIP_CONFIG="${_terminal_ninja_root}/starship.toml"

_terminal_ninja_starship() {
    if command -v starship >/dev/null 2>&1; then
        command -v starship
        return 0
    fi

    if command -v starship.exe >/dev/null 2>&1; then
        command -v starship.exe
        return 0
    fi

    return 1
}

if _terminal_ninja_starship >/dev/null 2>&1 && [ -f "$STARSHIP_CONFIG" ]; then
    _terminal_ninja_starship_path="$(_terminal_ninja_starship)"
    eval "$("${_terminal_ninja_starship_path}" init bash)"
fi

shopt -s histappend checkwinsize cmdhist 2>/dev/null
HISTCONTROL=ignoredups:erasedups
HISTSIZE="${HISTSIZE:-10000}"
HISTFILESIZE="${HISTFILESIZE:-20000}"

if [ -z "${BASH_COMPLETION_VERSINFO:-}" ]; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\C-l": clear-screen'
bind 'TAB:menu-complete'

alias ll='ls -lah --color=auto'
alias la='ls -A'
alias c='clear'

if grep --help 2>/dev/null | grep -q -- '--color'; then
    alias grep='grep --color=auto'
fi

..() {
    cd ..
}

...() {
    cd ../..
}

....() {
    cd ../../..
}

mkcd() {
    [ -n "$1" ] || return 1
    mkdir -p -- "$1" && cd -- "$1"
}

explore() {
    if command -v explorer.exe >/dev/null 2>&1; then
        explorer.exe . >/dev/null 2>&1 &
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open . >/dev/null 2>&1 &
    fi
}

publicip() {
    curl -fsSL https://api.ipify.org
    printf '\n'
}

findfile() {
    [ -n "$1" ] || return 1
    find . -iname "*$1*" 2>/dev/null
}

findinfiles() {
    [ -n "$1" ] || return 1
    if command -v rg >/dev/null 2>&1; then
        rg --hidden --glob '!.git' -- "$1" "${2:-.}"
    else
        grep -RIn -- "$1" "${2:-.}"
    fi
}

memorytop() {
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 11
}

gs() {
    git status "$@"
}

gaa() {
    git add .
}

gc() {
    git commit -m "$*"
}

gp() {
    git push "$@"
}