-- fish_greeting for the caelestia rice — shipped verbatim from upstream
-- caelestia-dots/caelestia (config/fish/functions/fish_greeting.fish).
-- Keep it here, NOT inlined in config.fish: this file is the uniformly
-- autoloaded upstream version and inline overrides would shadow it.
function fish_greeting
    echo -ne '\x1b[38;5;16m'  # Set colour to primary
    echo '     ______           __          __  _       '
    echo '    / ____/___ ____  / /__  _____/ /_(_)___ _ '
    echo '   / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/ '
    echo '  / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /  '
    echo '  \____/\__,_/\___/_/\___/____/\__/_/\__,_/   '
    set_color normal
    command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
end
