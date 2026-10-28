#!/usr/bin/env bash
#
# Switch this Artix/dinit machine from ConnMan to NetworkManager.
#
#   sudo ./setup-network.sh            install and switch
#   ./setup-network.sh --dry-run       print the commands only
#
# networkmanager-dinit is installed FIRST, while ConnMan still provides the
# network, so pacman does not need a connection after the switch.
#
# Rollback from a TTY:
#   sudo dinitctl disable NetworkManager
#   sudo dinitctl enable connmand && sudo dinitctl start connmand
#   sudo reboot

set -euo pipefail

DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=true ;;
        -h|--help)    sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)            printf 'unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

info() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m ->\033[0m %s\n' "$*" >&2; }

run() {
    if $DRY_RUN; then printf '    [dry-run] %s\n' "$*"; else "$@"; fi
}

if ! $DRY_RUN && [ "$(id -u)" -ne 0 ]; then
    printf 'ERROR: run this with sudo (it edits the init system).\n' >&2
    exit 1
fi

command -v dinitctl >/dev/null 2>&1 || {
    printf 'ERROR: dinitctl not found — this script is for Artix/dinit.\n' >&2
    exit 1
}

if pgrep -x NetworkManager >/dev/null 2>&1 && ! pgrep -x connmand >/dev/null 2>&1; then
    info "NetworkManager is already running and ConnMan is not — nothing to do"
    nmcli -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true
    exit 0
fi

# ---------------------------------------------------------------- packages --
# Keep ConnMan alive until the NM dinit package is on disk.
info "Installing networkmanager-dinit (ConnMan is still online)"
run pacman -S --needed --noconfirm networkmanager-dinit

# ------------------------------------------------------------------- switch --
if [ -e /etc/dinit.d/boot.d/connmand ]; then
    info "Disabling ConnMan at boot"
    run dinitctl disable connmand || warn "could not disable connmand (continuing)"
else
    info "ConnMan is not enabled at boot"
fi

if pgrep -x connmand >/dev/null 2>&1; then
    info "Stopping ConnMan"
    run dinitctl stop connmand || warn "could not stop connmand (continuing)"
fi

# ConnMan's wpa_supplicant daemonizes and is reparented, so dinit does not own
# it. NetworkManager starts and manages its own supplicant.
if pgrep -x wpa_supplicant >/dev/null 2>&1; then
    info "Stopping ConnMan's wpa_supplicant"
    run pkill -x wpa_supplicant || warn "could not stop wpa_supplicant (continuing)"
fi

if [ -L /etc/dinit.d/boot.d/NetworkManager ]; then
    info "NetworkManager is already enabled at boot"
else
    info "Enabling NetworkManager at boot"
    run dinitctl enable NetworkManager
fi

if pgrep -x NetworkManager >/dev/null 2>&1; then
    info "NetworkManager is already running"
else
    info "Starting NetworkManager"
    run dinitctl start NetworkManager
fi

if ! $DRY_RUN; then
    # Give NM a moment to take over the interface before reporting.
    for _ in $(seq 1 20); do
        nmcli general status >/dev/null 2>&1 && break
        sleep 1
    done
    printf '\n'
    nmcli -f DEVICE,TYPE,STATE,CONNECTION device status 2>&1 || true
    printf '\nSaved Wi-Fi profiles are not imported from ConnMan (/var/lib/connman is root-only).\n'
    printf 'Connect once with:  nmtui\n'
    printf 'or:                 nmcli device wifi connect "SSID" password "PASSWORD"\n'
    printf 'Rollback:           dinitctl disable NetworkManager; dinitctl enable connmand; dinitctl start connmand\n'
fi
