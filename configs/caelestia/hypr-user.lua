-- User Hyprland config for Caelestia
local home = os.getenv("HOME")

hl.on("hyprland.start", function()
    hl.exec_cmd(home .. "/.local/bin/caelestia-session-services")
end)
