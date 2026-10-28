# ~/.bashrc

# Keep the Caelestia/opencode paths available to all shells.
for __dir in "$HOME/.local/bin" /usr/local/bin "$HOME/.opencode/bin"; do
    case ":$PATH:" in
        *":$__dir:"*) ;;
        *) PATH="$__dir:$PATH" ;;
    esac
done
unset __dir
export PATH
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Only do interactive setup for interactive shells.
[[ $- != *i* ]] && return

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Direnv + zoxide
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash --cmd cd)"
fi

# Better ls
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first -1'
fi

# Git aliases (translated from the Caelestia fish abbreviations)
alias lg='lazygit'
alias gd='git diff'
alias ga='git add .'
alias gc='git commit -am'
alias gl='git log'
alias gs='git status'
alias gst='git stash'
alias gsp='git stash pop'
alias gp='git push'
alias gpl='git pull'
alias gsw='git switch'
alias gsm='git switch main'
alias gb='git branch'
alias gbd='git branch -d'
alias gco='git checkout'
alias gsh='git show'

alias l='ls'
alias ll='ls -l'
alias la='ls -a'
alias lla='ls -la'

# Apply the current Caelestia terminal palette.
if [ -r "$HOME/.local/state/caelestia/sequences.txt" ]; then
    cat "$HOME/.local/state/caelestia/sequences.txt"
fi

# Mark the start of each prompt for foot's prompt jumping.
__caelestia_mark_prompt_start() {
    printf '\033]133;A\033\\'
}
PROMPT_COMMAND="__caelestia_mark_prompt_start${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Caelestia greeting
__caelestia_greeting() {
    printf '\033[38;5;16m'
    cat <<'EOF'
     ______           __          __  _
    / ____/___ ____  / /__  _____/ /_(_)___ _
   / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/
  / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /
  \____/\__,_/\___/_/\___/____/\__/_/\__,_/
EOF
    printf '\033[0m'
    if command -v fastfetch >/dev/null 2>&1; then
        fastfetch --key-padding-left 5
    fi
}
__caelestia_greeting

# Custom user configuration. The fish version sources user-config.fish;
# the bash equivalent is user-config.sh.
__caelestia_config="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia"
if [ -r "$__caelestia_config/user-config.sh" ]; then
    . "$__caelestia_config/user-config.sh"
fi
unset __caelestia_config
# Cargo (kept safe on machines without rust)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ble.sh — fish-like line editing for bash
# https://github.com/akinomyoga/ble.sh
# Gives inline autosuggestions, live syntax highlighting and a completion menu.
if [[ $- == *i* ]] && [[ -r "$HOME/.local/share/blesh/ble.sh" ]]; then
    source "$HOME/.local/share/blesh/ble.sh"

    # Completion menu (TAB shows candidates, TAB again cycles through them).
    # 'align-nowrap' = fish-style column grid; switch to 'desc' if you would
    # rather have one candidate per line with its description (better for
    # git/systemctl completions, noisier for plain filenames).
    bleopt complete_menu_style=align-nowrap
    bleopt complete_menu_maxlines=-1

    # Suggest from the selected completion as well as shell history.
    bleopt complete_auto_complete=1
    bleopt complete_auto_history=1
fi
# Deno (kept safe on machines without deno)
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
