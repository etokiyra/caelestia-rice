#!/usr/bin/env bash
#
# Switch this Artix/dinit machine from LightDM to greetd + tuigreet.
#
#   sudo ./setup-greetd.sh              install/repair, using VT 7
#   sudo ./setup-greetd.sh --vt 7       pick the VT explicitly
#   ./setup-greetd.sh --dry-run         print the commands only
#
# greetd is NOT started by this script: the current graphical session would
# fight it for the VT. Reboot (or log out to a TTY and start greetd) instead.
#
# Rollback from a TTY:
#   sudo dinitctl disable greetd
#   sudo pacman -S --needed lightdm-dinit
#   sudo dinitctl enable lightdm
#   sudo reboot

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
VT=7

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=true ;;
        --vt)         VT="${2:?--vt needs a number}"; shift ;;
        --vt=*)       VT="${1#--vt=}" ;;
        -h|--help)    sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)            printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

case "$VT" in
    ''|*[!0-9]*) printf 'ERROR: invalid VT: %s\n' "$VT" >&2; exit 2 ;;
esac

info() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m ->\033[0m %s\n' "$*" >&2; }

run() {
    if $DRY_RUN; then printf '    [dry-run] %s\n' "$*"; else "$@"; fi
}

if ! $DRY_RUN && [ "$(id -u)" -ne 0 ]; then
    printf 'ERROR: run this with sudo (it edits /etc and the init system).\n' >&2
    exit 1
fi

command -v dinitctl >/dev/null 2>&1 || {
    printf 'ERROR: dinitctl not found — this script is for Artix/dinit.\n' >&2
    exit 1
}

if [ "$VT" -le 6 ]; then
    warn "VT $VT is used by a getty by default; remove it from /etc/dinit.d/config/console.conf"
    warn "(ACTIVE_CONSOLES=\"/dev/tty[2-6]\" for VT 1, etc.) or greetd will fight agetty."
fi

# ---------------------------------------------------------------- packages --
# Do the package work while the current network and session still work.
# greetd-dinit Provides/Conflicts init-displaymanager, so lightdm-dinit has to
# go. Removing it explicitly avoids pacman's interactive conflict prompt
# (--noconfirm does not always answer that one the way you would expect).
if pacman -Q lightdm-dinit >/dev/null 2>&1; then
    info "Disabling LightDM before replacing its dinit package"
    if [ -e /etc/dinit.d/boot.d/lightdm ]; then
        run dinitctl disable lightdm || warn "could not disable lightdm (continuing)"
    fi
    info "Removing lightdm-dinit (the lightdm binary stays installed)"
    run pacman -R --noconfirm lightdm-dinit
else
    info "lightdm-dinit is already gone"
fi

info "Installing greetd, tuigreet and the dinit service"
run pacman -S --needed --noconfirm greetd greetd-tuigreet greetd-dinit

# ------------------------------------------------------------------ config --
info "Installing /etc/greetd/config.toml (VT $VT)"
if $DRY_RUN; then
    printf '    [dry-run] install -d -m 0755 /etc/greetd\n'
    printf '    [dry-run] sed "s/^vt = .*/vt = %s/" %s > /etc/greetd/config.toml\n' "$VT" "$SCRIPT_DIR/configs/greetd/config.toml"
else
    install -d -m 0755 /etc/greetd
    tmp="$(mktemp)"
    sed "s/^vt = .*/vt = $VT/" "$SCRIPT_DIR/configs/greetd/config.toml" > "$tmp"
    install -m 0644 "$tmp" /etc/greetd/config.toml
    rm -f "$tmp"
fi

# ----------------------------------------------------------------- service --
info "Enabling greetd at boot (not starting it in this session)"
if [ -L /etc/dinit.d/boot.d/greetd ]; then
    info "greetd is already enabled"
else
    run dinitctl enable greetd
fi

if ! $DRY_RUN; then
    id greeter >/dev/null 2>&1 \
        || warn "the greeter user is missing — reinstall greetd before rebooting"
    [ -s /etc/greetd/config.toml ] \
        || warn "/etc/greetd/config.toml is empty — greetd will not start"

    printf '\nDone. Reboot to reach the greeter on VT %s:  sudo reboot\n' "$VT"
    printf 'Rollback from a TTY: dinitctl disable greetd; pacman -S lightdm-dinit; dinitctl enable lightdm\n'
fi
