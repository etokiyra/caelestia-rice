#!/usr/bin/env bash
#
# Kiyra's Caelestia rice — one-shot installer for EndeavourOS (Arch + systemd).
#
#   ./install.sh              apply the rice: configs, wallpaper, cursor
#   ./install.sh --packages   also install packages + run `caelestia install`
#   ./install.sh --dry-run    print what would happen, change nothing
#   ./install.sh --no-backup  don't back up the existing configs
#
# Everything this script replaces is backed up to
# ~/.config-backup-rice-<timestamp>/ (unless --no-backup), so nothing is
# clobbered. Never touches the shell choice: fish ships its own config.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

DRY_RUN=false
WITH_PACKAGES=false
KEEP_BACKUP=true

info() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m ->\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# run() gets commands out of the way during --dry-run.
run() {
    if $DRY_RUN; then printf '    [dry-run] %s\n' "$*"; else "$@"; fi
}

for arg in "$@"; do
    case "$arg" in
        -p|--packages) WITH_PACKAGES=true ;;
        -n|--dry-run)  DRY_RUN=true ;;
        --no-backup)   KEEP_BACKUP=false ;;
        -h|--help)
            printf 'usage: install.sh [--packages] [--dry-run] [--no-backup]\n'
            exit 0
            ;;
        *) fail "unknown option: $arg (see --help)" ;;
    esac
done

info "Rice root: $SCRIPT_DIR"
$DRY_RUN && warn "dry run — nothing will be changed"

# ---------------------------------------------------------------- packages --
REPO_PKGS=(
    fish
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    foot fuzzel fastfetch starship
    grim slurp swappy wl-clipboard cliphist trash-cli
    polkit-gnome gnome-keyring gammastep geoclue bluez-utils
    networkmanager brightnessctl ddcutil libqalculate
    power-profiles-daemon dart-sass psmisc
    btop cava
    ttf-jetbrains-mono-nerd ttf-material-symbols-variable
    ttf-rubik-vf ttf-cascadia-code-nerd
    papirus-icon-theme thunar
    eza zoxide direnv lazygit
)
AUR_PKGS=(caelestia-cli gpu-screen-recorder)

# Everything else Caelestia needs (caelestia-shell, quickshell, qtengine,
# fonts, ...) is pulled in by `caelestia install` itself — the upstream
# installer manages those, so they are NOT listed here.

AUR_HELPER=""
install_packages() {
    command -v pacman >/dev/null 2>&1 || {
        warn "pacman not found — install the packages from the README manually"
        return 0
    }

    # One batched call instead of one per package: a single password prompt
    # and --needed skips everything already installed.
    local missing=() p
    for p in "${REPO_PKGS[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        info "Installing ${#missing[@]} repo package(s) (may ask for your password)"
        run sudo pacman -S --needed "${missing[@]}" \
            || warn "some repo packages failed to install, see the output above"
    else
        info "All repo packages are already installed"
    fi

    if command -v yay >/dev/null 2>&1; then AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then AUR_HELPER="paru"
    else
        warn "no AUR helper (yay/paru) found — install these manually: ${AUR_PKGS[*]}"
        return 0
    fi

    local aur_missing=()
    for p in "${AUR_PKGS[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 || aur_missing+=("$p")
    done
    if [ ${#aur_missing[@]} -gt 0 ]; then
        info "Installing ${#aur_missing[@]} AUR package(s) with $AUR_HELPER"
        run "$AUR_HELPER" -S --needed "${aur_missing[@]}" \
            || warn "some AUR packages failed to install, see the output above"
    else
        info "All AUR packages are already installed"
    fi
}

$WITH_PACKAGES && install_packages

# ------------------------------------------------------------- caelestia ----
# Instead of installing the Caelestia stack by hand, let the upstream CLI
# installer do it: it installs caelestia-shell + quickshell + theme engines
# and deploys its base dots. This script then overwrites the config files
# with the rice's on the next step. Its status lives in
# ~/.local/state/caelestia/dots-state.json — once present, re-runs skip
# straight here and future updates go through `caelestia update`.
if command -v caelestia >/dev/null 2>&1; then
    if [ -f "$HOME/.local/state/caelestia/dots-state.json" ]; then
        info "Caelestia dotfiles already installed — skipping caelestia install"
        info "Pull in upstream changes any time with: caelestia update"
    else
        info "Installing the Caelestia dotfiles: caelestia install (defaults, non-interactive)"
        installer_args=(--noconfirm)
        [ -n "$AUR_HELPER" ] && installer_args+=(--aur-helper "$AUR_HELPER")
        run caelestia install "${installer_args[@]}" \
            || warn "caelestia install failed — run it manually to finish the setup"
    fi
elif $WITH_PACKAGES; then
    warn "caelestia CLI not installed — cannot run caelestia install; set up manually"
fi

# ---------------------------------------------------------------- services --
# Everything runs systemd on EndeavourOS; both services are usually already
# enabled, so these are no-ops after the first run. The Caelestia battery
# panel reads power profiles from power-profiles-daemon.
if command -v systemctl >/dev/null 2>&1 \
   && pacman -Q power-profiles-daemon >/dev/null 2>&1; then
    if systemctl is-enabled --quiet power-profiles-daemon 2>/dev/null; then
        info "power-profiles-daemon is already enabled"
    else
        info "Enabling power-profiles-daemon (systemd)"
        run sudo systemctl enable --now power-profiles-daemon \
            || warn "could not enable power-profiles-daemon"
    fi

    if systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
        info "NetworkManager is already enabled"
    else
        info "Enabling NetworkManager (systemd)"
        run sudo systemctl enable --now NetworkManager \
            || warn "could not enable NetworkManager"
    fi
fi

# ------------------------------------------------------------------ backup --
# Everything the installer writes to. Backed up before anything is touched,
# so rolling back is just copying the backup contents back in place.
TARGETS=(
    "$XDG_CONFIG_HOME/caelestia"
    "$XDG_CONFIG_HOME/hypr"
    "$XDG_CONFIG_HOME/foot"
    "$XDG_CONFIG_HOME/fuzzel"
    "$XDG_CONFIG_HOME/fastfetch"
    "$XDG_CONFIG_HOME/starship.toml"
    "$XDG_CONFIG_HOME/fish/config.fish"
    "$XDG_CONFIG_HOME/fish/functions/fish_greeting.fish"
)
BACKUP_DIR="$HOME/.config-backup-rice-$(date +%Y%m%d-%H%M%S)"

if $KEEP_BACKUP; then
    present=()
    for t in "${TARGETS[@]}"; do [ -e "$t" ] && present+=("$t"); done
    if [ ${#present[@]} -gt 0 ]; then
        info "Backing up ${#present[@]} existing target(s) to $BACKUP_DIR"
        run mkdir -p "$BACKUP_DIR"
        for t in "${present[@]}"; do
            run cp -a "$t" "$BACKUP_DIR/$(basename "$t")"
        done
    else
        info "Nothing to back up"
    fi
else
    warn "--no-backup: existing configs will be overwritten without a copy"
fi

# ------------------------------------------------------------------ configs --
info "Installing config files to $XDG_CONFIG_HOME"
run mkdir -p "$XDG_CONFIG_HOME"
run rm -rf "$XDG_CONFIG_HOME/caelestia" "$XDG_CONFIG_HOME/hypr" \
           "$XDG_CONFIG_HOME/foot"    "$XDG_CONFIG_HOME/fuzzel" \
           "$XDG_CONFIG_HOME/fastfetch"
run cp -a "$SCRIPT_DIR/configs/caelestia"   "$XDG_CONFIG_HOME/caelestia"
run cp -a "$SCRIPT_DIR/configs/hypr"        "$XDG_CONFIG_HOME/hypr"
run cp -a "$SCRIPT_DIR/configs/foot"        "$XDG_CONFIG_HOME/foot"
run cp -a "$SCRIPT_DIR/configs/fuzzel"      "$XDG_CONFIG_HOME/fuzzel"
run cp -a "$SCRIPT_DIR/configs/fastfetch"   "$XDG_CONFIG_HOME/fastfetch"
run cp -a "$SCRIPT_DIR/configs/starship/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

# Shell is the login shell — the rice ships a fish config, never a .bashrc.
run mkdir -p "$XDG_CONFIG_HOME/fish"
run cp -a "$SCRIPT_DIR/configs/fish/config.fish" "$XDG_CONFIG_HOME/fish/config.fish"
# The greeting lives in fish's autoload dir, exactly like upstream caelestia.
run mkdir -p "$XDG_CONFIG_HOME/fish/functions"
run cp -a "$SCRIPT_DIR/configs/fish/functions/fish_greeting.fish" \
          "$XDG_CONFIG_HOME/fish/functions/fish_greeting.fish"

if ! [ -f "$XDG_CONFIG_HOME/caelestia/user-config.fish" ]; then
    run printf '# Add your personal fish configuration here.\n' \
        > "$XDG_CONFIG_HOME/caelestia/user-config.fish"
fi

info "Installing helper scripts to $HOME/.local/bin"
run mkdir -p "$HOME/.local/bin"
run cp -a "$SCRIPT_DIR/bin/." "$HOME/.local/bin/"

# ------------------------------------------------------------------ cursor --
CURSOR_THEME="Bibata-Modern-Ice"
CURSOR_VERSION="v2.0.7"
if [ -d "$HOME/.local/share/icons/$CURSOR_THEME" ] || [ -d "/usr/share/icons/$CURSOR_THEME" ]; then
    info "Cursor theme $CURSOR_THEME already installed"
else
    info "Installing cursor theme $CURSOR_THEME"
    tmp="$(mktemp -d)"
    if command -v curl >/dev/null 2>&1; then
        run curl -fL "https://github.com/ful1e5/Bibata_Cursor/releases/download/$CURSOR_VERSION/$CURSOR_THEME.tar.xz" -o "$tmp/$CURSOR_THEME.tar.xz"
    elif command -v wget >/dev/null 2>&1; then
        run wget -O "$tmp/$CURSOR_THEME.tar.xz" "https://github.com/ful1e5/Bibata_Cursor/releases/download/$CURSOR_VERSION/$CURSOR_THEME.tar.xz"
    else
        warn "neither curl nor wget found — install the Bibata cursor theme manually"
    fi
    run mkdir -p "$HOME/.local/share/icons"
    run tar -xf "$tmp/$CURSOR_THEME.tar.xz" -C "$HOME/.local/share/icons"
fi
if command -v gsettings >/dev/null 2>&1; then
    run gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    run gsettings set org.gnome.desktop.interface cursor-size 24
else
    warn "gsettings not found — set the cursor theme manually"
fi

# -------------------------------------------------------- wallpaper/scheme --
# Colors are NOT pinned: Caelestia's dynamic scheme derives its palette from
# whichever wallpaper is active, so switching wallpapers re-themes everything
# automatically. The installer only adds the wallpapers to the pool and picks
# one on a fresh machine (when Caelestia has no wallpaper set yet).
run mkdir -p "$HOME/Pictures/Wallpapers"
info "Installing wallpapers to $HOME/Pictures/Wallpapers"
for w in "$SCRIPT_DIR"/wallpapers/*; do
    [ -e "$HOME/Pictures/Wallpapers/$(basename "$w")" ] \
        || run cp -a "$w" "$HOME/Pictures/Wallpapers/"
done

if command -v caelestia >/dev/null 2>&1; then
    if [ -s "$HOME/.local/state/caelestia/wallpaper/path.txt" ]; then
        info "Wallpaper already set ($(cat "$HOME/.local/state/caelestia/wallpaper/path.txt")) — leaving it"
        info "Switch any time: caelestia wallpaper -f <file> (or the shell's launcher)"
    else
        info "No wallpaper set yet — applying wallhaven-qrgqyq.jpg"
        run caelestia wallpaper -f "$HOME/Pictures/Wallpapers/wallhaven-qrgqyq.jpg"
    fi
else
    warn "caelestia CLI not found — pick a wallpaper later with: caelestia wallpaper -f <file>"
fi

# ------------------------------------------------------------------ apply ----
# A running Caelestia shell caches its config; a straight file swap only
# reaches it once restarted (the client-side watcher dies with rm -rf).
# Same for Hyprland: a reload is needed for the new decoration/variables.
if pgrep -f "qs -c caelestia" >/dev/null 2>&1; then
    info "Restarting the running Caelestia shell"
    run caelestia shell -k
    run setsid caelestia shell -d >/dev/null 2>&1 </dev/null
fi
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
    info "Reloading the running Hyprland session"
    run hyprctl reload
fi

# -------------------------------------------------------------------- done --
missing=()
for cmd in hyprland qs caelestia foot fastfetch starship fish; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
for m in "${missing[@]:-}"; do
    [ -n "$m" ] && warn "not found: $m (run ./install.sh --packages or install manually)"
done

login_shell="$(getent passwd "$(id -u)" | cut -d: -f7)"
fish_bin="$(command -v fish)"
if [ -n "$fish_bin" ] && [ "$login_shell" != "$fish_bin" ] \
   && [ "$(readlink -f "$login_shell" 2>/dev/null)" != "$(readlink -f "$fish_bin")" ]; then
    warn "your login shell is $login_shell, not fish — change it with: chsh -s $fish_bin"
fi

info "Done!"
printf '    - Fresh machine: log out and pick the Caelestia session\n'
printf '    - Inside a session: it was already reloaded/restarted by this script\n'
printf '    - New terminals: fish + greeting + glass all come up on their own\n'
