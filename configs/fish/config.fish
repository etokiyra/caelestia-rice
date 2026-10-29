# ~/.config/fish/config.fish — Kiyra's Caelestia rice (fish)
# Fish is the login shell; this mirrors configs/bash/.bashrc from the rice.

# Keep the rice's and opencode's paths available to every fish instance.
for __dir in "$HOME/.local/bin" /usr/local/bin "$HOME/.opencode/bin"
    if not contains -- "$__dir" $PATH
        set -x PATH "$__dir" $PATH
    end
end
set -x XDG_CONFIG_HOME "$HOME/.config"
set -x XDG_DATA_HOME "$HOME/.local/share"
set -x XDG_STATE_HOME "$HOME/.local/state"
set -x XDG_CACHE_HOME "$HOME/.cache"

if status is-interactive
    # Starship prompt
    if command -q starship
        starship init fish | source
    end

    # Direnv + zoxide
    if command -q direnv
        direnv hook fish | source
    end
    if command -q zoxide
        zoxide init fish --cmd cd | source
    end

    # Better ls
    if command -q eza
        alias ls='eza --icons --group-directories-first -1'
    end

    # Git abbreviations (the Caelestia defaults)
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # Apply the current Caelestia terminal palette.
    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null

    # Mark the start of each prompt so foot can jump between prompts.
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # The greeting lives in fish/functions/fish_greeting.fish (upstream
    # caelestia style, installed by install.sh) — do NOT define fish_greeting
    # here or it would shadow that autoloaded file.

    # Custom user configuration.
    set -l cConf $XDG_CONFIG_HOME/caelestia
    source $cConf/user-config.fish 2> /dev/null
end
