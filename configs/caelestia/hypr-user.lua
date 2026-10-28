-- User Hyprland config for Caelestia
hl.on("hyprland.start", function()
    hl.exec_cmd("caelestia-session-services")
end)

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_CONFIG_HOME", "/home/kiyra/.config")
