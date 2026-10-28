#!/usr/bin/env bash
#
# Kiyra's Caelestia rice — one-shot installer for a fresh (Artix/Arch) system.
#
#   ./install.sh              apply the rice: configs, wallpaper, cursor, scheme
#   ./install.sh --packages   also install the required pacman/AUR packages
#   ./install.sh --dry-run    print what would happen, change nothing
#   ./install.sh --no-backup  don't back up the existing configs
#
# Everything replaced by this script is backed up to
# ~/.config-backup-rice-<timestamp>/ (unless --no-backup).

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
    hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    foot fuzzel fastfetch starship
    grim slurp swappy wl-clipboard cliphist trash-cli
    polkit-gnome gnome-keyring gammastep geoclue bluez-utils
    networkmanager brightnessctl ddcutil libcava libqalculate
    power-profiles-daemon dart-sass psmisc
    btop htop cava
    ttf-jetbrains-mono-nerd ttf-material-symbols-variable
    ttf-rubik-vf ttf-cascadia-code-nerd
    papirus-icon-theme dolphin
    eza zoxide direnv lazygit
)
AUR_PKGS=(caelestia-cli caelestia-shell quickshell-git qt6-m3shapes-git qtengine gpu-screen-recorder)

install_packages() {
    command -v pacman >/dev/null 2>&1 || {
        warn "pacman not found — --packages targets Arch/Artix, install manually (see README)"
        return 0
    }

    info "Installing repo packages (may ask for your password)"
    local p
    for p in "${REPO_PKGS[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 && continue
        run sudo pacman -S --needed "$p" || warn "could not install: $p"
    done

    local helper=""
    if command -v paru >/dev/null 2>&1; then helper="paru"
    elif command -v yay >/dev/null 2>&1; then helper="yay"
    else
        warn "no AUR helper (paru/yay) found — install these manually: ${AUR_PKGS[*]}"
        return 0
    fi

    info "Installing AUR packages with $helper"
    for p in "${AUR_PKGS[@]}"; do
        pacman -Q "$p" >/dev/null 2>&1 && continue
        run "$helper" -S --needed "$p" || warn "could not install: $p"
    done
}

$WITH_PACKAGES && install_packages

# ---------------------------------------------------------------- services --
# Caelestia's battery panel talks to power-profiles-daemon. On non-systemd
# installs the packaged D-Bus service is often a /bin/false stub, so the
# daemon has to be enabled in the init system explicitly.
if [ -x /usr/lib/power-profiles-daemon ] || command -v power-profiles-daemon >/dev/null 2>&1; then
    if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
        info "Enabling power-profiles-daemon (systemd)"
        run sudo systemctl enable --now power-profiles-daemon || warn "could not enable power-profiles-daemon"
    elif command -v dinitctl >/dev/null 2>&1 && [ -f /etc/dinit.d/power-profiles-daemon ]; then
        info "Enabling power-profiles-daemon (dinit)"
        run sudo dinitctl enable power-profiles-daemon || warn "could not enable power-profiles-daemon"
        run sudo dinitctl start power-profiles-daemon || warn "power-profiles-daemon may already be running"
    else
        warn "enable power-profiles-daemon with your init system (battery power profiles need it)"
    fi
fi

# ------------------------------------------------------------------ backup --
TARGETS=(
    "$XDG_CONFIG_HOME/caelestia"
    "$XDG_CONFIG_HOME/hypr"
    "$XDG_CONFIG_HOME/foot"
    "$XDG_CONFIG_HOME/fuzzel"
    "$XDG_CONFIG_HOME/fastfetch"
    "$XDG_CONFIG_HOME/starship.toml"
    "$HOME/.bashrc"
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
    fi
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
run rm -f "$HOME/.bashrc" && run cp -a "$SCRIPT_DIR/configs/bash/.bashrc" "$HOME/.bashrc"

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
    warn "gsettings not found (GNOME not fully installed?) — set the cursor theme manually"
fi

# -------------------------------------------------------- wallpaper/scheme --
WALL_FILE="wallhaven-qrgqyq.jpg"
WALL_DIR="$HOME/Pictures/Wallpapers"
info "Installing wallpaper to $WALL_DIR"
run mkdir -p "$WALL_DIR"
run cp -a "$SCRIPT_DIR/wallpapers/$WALL_FILE" "$WALL_DIR/"

if command -v caelestia >/dev/null 2>&1; then
    info "Applying the wallpaper"
    run caelestia wallpaper -f "$WALL_DIR/$WALL_FILE"
    info "Pinning the olive-gold scheme (dynamic/hard/tonalspot, dark)"
    run caelestia scheme set -n dynamic -f hard -m dark -v tonalspot
else
    warn "caelestia CLI not found — set the wallpaper later with: caelestia wallpaper -f $WALL_DIR/$WALL_FILE"
fi

# -------------------------------------------------------------------- done --
missing=()
for cmd in hyprland quickshell caelestia foot fuzzel fastfetch starship; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
for m in "${missing[@]:-}"; do
    [ -n "$m" ] && warn "not found: $m (run ./install.sh --packages or install manually)"
done

info "Done! Next steps:"
printf '    1. Log out and pick the Caelestia session (or run: caelestia shell -d)\n'
printf '    2. If already inside Hyprland: hyprctl reload\n'
printf '    3. New terminals will use the glassy foot config; old ones need a restart\n'
