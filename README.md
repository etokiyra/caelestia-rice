# caelestia-rice

<p align="center">
  <b>Kiyra's EndeavourOS rice</b> — Caelestia shell + Hyprland (Lua config)<br>
  heavy frosted glass, <b>zero pinned colors</b>: the dynamic scheme re-themes<br>
  the whole desktop from whichever wallpaper is active.
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/EndeavourOS-Arch%20%2B%20systemd-606ca8?style=flat-square">
  <img alt="compositor" src="https://img.shields.io/badge/Hyprland-0.55%2B%20Lua%20config-1a96c9?style=flat-square">
  <img alt="shell" src="https://img.shields.io/badge/fish-login%20shell-00a67d?style=flat-square">
  <img alt="shell ui" src="https://img.shields.io/badge/Caelestia%20shell-2.5-ae4bd1?style=flat-square">
</p>

![desktop](screenshots/01-desktop.png)

## The look

| What | Where | Value |
| --- | --- | --- |
| Shell transparency | `configs/caelestia/shell.json` | `base 0.28`, `layers 0.16` — launcher, dashboard, sidebar, OSD are all see-through glass |
| Shell blur over windows | `configs/hypr/variables.lua` | `blurXray = false`, size 10, passes 2 — panels frost whatever is behind them |
| Glass terminal | `configs/foot/foot.ini` | `alpha 0.68`, `alpha-mode all`, `blur yes` + Hyprland rule `opacity = "0.85 0.8"` for class `foot` |
| Borders | `configs/hypr/variables.lua` | 2px gradient, 20px rounding, deep shadows, gaps 8/16/28 |
| Cursor | `install.sh` | [Bibata-Modern-Ice](https://github.com/ful1e5/Bibata_Cursor) v2.0.7, size 24 |
| Colors | Caelestia dynamic scheme | derived from the active wallpaper — never pinned, switch and watch everything re-theme |
| Terminal | `configs/foot/foot.ini` | `shell=fish`, starship prompt, caelestia palette sequences, foot prompt-jumping |
| Shell extras | `configs/caelestia/shell.json` | glass desktop clock, wallpaper lock screen, bigger launcher items |
| Column bar / animations | `configs/caelestia/shell-tokens.json`, `configs/hypr/hyprland/animations.lua` | narrow 44px glass rail; stock Hyprland animations |

![launcher](screenshots/02-launcher.png)
![dashboard](screenshots/03-dashboard.png)
![terminal](screenshots/05-terminal-glass.png)

## What's in the box

```
configs/
├── fish/
│   ├── config.fish             starship, direnv, zoxide, eza, abbrs, palette, prompt-marks
│   └── functions/
│       └── fish_greeting.fish  the greeting (verbatim from upstream caelestia)
├── caelestia/                  Caelestia shell + Hyprland user config
│   ├── shell.json              transparency, border/corner, bar entries, clock, lock screen
│   ├── shell-tokens.json       bar width, launcher item sizes
│   ├── hypr-vars.lua           user prefs only (editor, cursor, sleep gesture)
│   ├── hypr-user.lua           per-session services
│   └── monitors/eDP-1/         per-monitor shell settings
├── fastfetch/config.jsonc      the fetch in the terminal greeting
├── foot/foot.ini               glassy terminal (shell=fish)
├── fuzzel/fuzzel.ini           app launcher / search
├── hypr/                       full Hyprland Lua config (blur, shadows, gaps, borders, rules, binds)
│   └── variables.lua           app paths & look defaults (browser=firefox, editor, file manager…)
└── starship/starship.toml      the prompt
bin/          caelestia-session-services (pipewire stack for the session)
wallpapers/   wallhaven-qrgqyq.jpg · wallhaven-pomg5p.jpg
install.sh    the installer (EndeavourOS/Arch + systemd)
```

## Installing on a fresh EndeavourOS/Arch system

```sh
git clone git@github.com:etokiyra/caelestia-rice.git
cd caelestia-rice

# 1. Requirements + Caelestia itself — pacman pass, then yay -S caelestia-cli
#    gpu-screen-recorder, then the upstream `caelestia install` (skips
#    everything already installed)
./install.sh --packages

# 2. Apply the rice
./install.sh

# 3. Log out → pick the Caelestia session (or, inside Hyprland: nothing to do,
#    the installer already restarted the shell and reloaded the compositor)
```

`./install.sh` backs everything it touches up to `~/.config-backup-rice-<timestamp>`
before changing anything and copies the configs. It never pins colors — both
wallpapers are just added to `~/Pictures/Wallpapers`, and a wallpaper is only
applied on a machine where none is set yet. Use `--dry-run` to preview the steps.

Because the scheme is dynamic, switching wallpapers

```sh
caelestia wallpaper -f ~/Pictures/Wallpapers/wallhaven-pomg5p.jpg
```

…instantly re-themes the shell, the terminal palette, GTK/Qt accents and the
borders. The install folder keeps the palette regeneration details
(`configs/hypr/scheme/`) so everything works from a cold boot too.

### What the installer does NOT touch

- `~/.bashrc` / `~/.bash_profile` — fish is the login shell of this rice; the
  installer only writes `~/.config/fish/config.fish` and the greeting function.
  If the login shell is still bash, switch once: `chsh -s /usr/bin/fish`.
- Your other dotfiles (Discord clients, Spicetify, micro, zed, …) — only the
  directories listed in `TARGETS` are replaced, and all of them are copied to
  the backup folder first.
- Display manager — on EndeavourOS enable whichever login manager you use with
  `systemctl enable`; the Caelestia session shows up on its own.

### Inside a live session

Run `./install.sh` while logged in and it finishes the job for you:
a running Caelestia shell is restarted (`caelestia shell -k` + `-d` — it caches
its config and its file watcher dies with the config dir swap) and Hyprland
gets `hyprctl reload`. Skipping that is what makes an install look stale —
no blur, no transparency — until the next logout.

### Manual package list (`--packages`)

Repo packages:

> fish hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk foot fuzzel
> fastfetch starship grim slurp swappy wl-clipboard cliphist trash-cli
> polkit-gnome gnome-keyring gammastep geoclue bluez-utils networkmanager
> brightnessctl ddcutil libqalculate power-profiles-daemon dart-sass psmisc
> btop cava ttf-jetbrains-mono-nerd ttf-material-symbols-variable ttf-rubik-vf
> ttf-cascadia-code-nerd papirus-icon-theme thunar eza zoxide direnv lazygit

AUR packages (yay/paru):

> caelestia-cli gpu-screen-recorder

The rest of the stack — `caelestia-shell`, `quickshell`, `qtengine`, fonts and
the base deployment of the Caelestia dots — is installed by the upstream CLI
itself: `--packages` runs `caelestia install --noconfirm` right after `yay` (it
supports `paru` too). On re-runs the installer detects
`~/.local/state/caelestia/dots-state.json` and skips straight ahead; to pull in
upstream changes later use `caelestia update`.

## Notes

- **Hyprland Lua config** is native since Hyprland 0.55 — any current build works.
- `configs/hypr/hyprland/execs.lua` uses Arch-style paths
  (`/usr/lib/polkit-gnome/...`, `/usr/lib/geoclue-2.0/demos/agent`); on other
  distros adjust those two lines.
- `configs/caelestia/monitors/eDP-1/shell.json` is keyed to the laptop panel
  `eDP-1`; on different hardware rename or drop that folder.
- Apps: defaults live in `configs/hypr/variables.lua`
  (`browser = "firefox"`); user overrides go in
  `~/.config/caelestia/hypr-vars.lua`, merged on top — keep that file to
  preferences only, don't put app paths there.
- The fish greeting lives in `configs/fish/functions/fish_greeting.fish`
  (autoloaded). Never define `fish_greeting` inside `config.fish` — that inline
  definition shadows the autoload and breaks the greeting.
- Personal fish tweaks go in `~/.config/caelestia/user-config.fish`, sourced at
  the end of `config.fish`.

## Tweaking knobs

- Shell glass strength: `configs/caelestia/shell.json` → `appearance.transparency.base` / `.layers`
- Terminal glass: `configs/foot/foot.ini` → `alpha` / `alpha-mode`
- Blur cost vs. looks: `configs/hypr/variables.lua` → `blurXray`, `blurPasses`, `blurSize`
- Border gradient/rounding: `configs/hypr/variables.lua` → `activeWindowBorderColour` / `windowRoundingPower`
- Per-app exceptions: `configs/hypr/hyprland/rules.lua`

## Credits

- [Caelestia dotfiles](https://github.com/caelestia-dots/caelestia) — the base dots & shell
- [Hyprland](https://github.com/hyprwm/Hyprland) — the compositor (Lua config)
- [Bibata cursor](https://github.com/ful1e5/Bibata_Cursor) by ful1e5
- Wallpapers from wallhaven (`qrgqyq`, `pomg5p`)
