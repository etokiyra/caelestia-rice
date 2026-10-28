#!/usr/bin/env bash
#
# Switch this Artix/dinit machine from LightDM to greetd + tuigreet.
#
#   sudo ./setup-greetd.sh            install, configure and enable greetd
#   sudo ./setup-greetd.sh --dry-run  print the commands only
#
# The running Hyprland session is left alone; the new login screen appears
# after the next reboot. To roll back from a TTY:
#
#   sudo dinitctl disable greetd
#   sudo pacman -S --needed lightdm-dinit
#   sudo dinitctl enable lightdm
#   sudo reboot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=true ;;
        -h|--help)    sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)            printf 'unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

run() {
    if $DRY_RUN; then printf '    [dry-run] %s\n' "$*"; else "$@"; fi
}

info() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if ! $DRY_RUN && [ "$(id -u)" -ne 0 ]; then
    printf 'ERROR: run this with sudo (it edits /etc and the init system).\n' >&2
    exit 1
fi

command -v dinitctl >/dev/null 2>&1 || {
    printf 'ERROR: dinitctl not found — this script is for Artix/dinit.\n' >&2
    exit 1
}

info "Disabling LightDM (does not stop the current session)"
run dinitctl disable lightdm || true

info "Installing greetd, tuigreet and the dinit service"
# greetd-dinit Conflicts/Provides init-displaymanager, so pacman replaces
# lightdm-dinit here. The lightdm binary itself stays installed.
run pacman -S --needed --noconfirm greetd greetd-tuigreet greetd-dinit

info "Installing /etc/greetd/config.toml"
run install -d -m 0755 /etc/greetd
run install -m 0644 "$SCRIPT_DIR/configs/greetd/config.toml" /etc/greetd/config.toml

info "Enabling greetd at boot"
run dinitctl enable greetd

if ! $DRY_RUN; then
    id greeter >/dev/null 2>&1 \
        || printf 'WARNING: the greeter user is missing; reinstall greetd.\n' >&2
    printf '\nDone. Reboot to use the new login screen:  sudo reboot\n'
    printf 'Rollback from a TTY: dinitctl disable greetd; pacman -S lightdm-dinit; dinitctl enable lightdm\n'
fi
