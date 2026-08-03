local HOME = os.getenv("HOME") or ""
-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- Commands and Apps to be executed at launch (vendor defaults)

local scriptsDir = HOME .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
    hl.exec_cmd("sh -c 'sleep 2; $HOME/.config/hypr/scripts/WallpaperDaemon.sh'")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(scriptsDir .. "/Polkit.sh")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("swaync")
    hl.exec_cmd(scriptsDir .. "/PortalHyprland.sh")
    hl.exec_cmd("sh $HOME/.config/hypr/scripts/ApplyThemeMode.sh")
    hl.exec_cmd("sh " .. scriptsDir .. "/WaybarStartup.sh")
    hl.exec_cmd("sh -c 'sleep 0.3; hyprctl setcursor \"${HYPRCURSOR_THEME:-Catppuccin-Mocha-Lavender}\" \"${HYPRCURSOR_SIZE:-24}\"'")
    hl.exec_cmd("qs -c overview")
    hl.exec_cmd("hypridle")
    hl.exec_cmd(scriptsDir .. "/LuaAutoReload.sh")
    hl.exec_cmd(scriptsDir .. "/Hyprsunset.sh init")
    hl.exec_cmd(scriptsDir .. "/Dropterminal.sh --startup kitty")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd(scriptsDir .. "/KeybindsLayoutInit.sh")
    hl.exec_cmd("ags")
end)
