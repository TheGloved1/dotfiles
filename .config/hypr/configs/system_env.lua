-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================

-- Converted from:
-- - config/hypr/configs/ENVariables.conf
-- - config/hypr/UserConfigs/ENVariables.conf (active values only)

hl.env("DOTS_VERSION", "2.3.25")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("GTK_CSD", "0")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QUICK_CONTROLS_STYLE", "Basic")
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Cursor theme
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-lavender")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-mocha-lavender")
hl.env("XCURSOR_SIZE", "24")

-- User defaults applied as env (parity with 01-UserDefaults.conf env entries).
-- KOOLDOTS_DEFAULTS is populated by lua/user_defaults.lua (loaded before this).
do
	local defaults = rawget(_G, "KOOLDOTS_DEFAULTS") or {}
	if defaults.edit and defaults.edit ~= "" then
		hl.env("EDITOR", defaults.edit)
	end
	if defaults.visual and defaults.visual ~= "" then
		hl.env("VISUAL", defaults.visual)
	end
	if defaults.term and defaults.term ~= "" then
		hl.env("TERMINAL", defaults.term)
	end
end

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GSK_RENDERER", "ngl")

-- VM / Software rendering
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")

-- Fix XDG_DATA_DIRS with flatpak support
local current_data_dirs = os.getenv("XDG_DATA_DIRS") or ""
local user_home = os.getenv("HOME") or ""
local flatpak_paths = "/var/lib/flatpak/exports/share"
if user_home ~= "" then
	flatpak_paths = flatpak_paths .. ":" .. user_home .. "/.local/share/flatpak/exports/share"
end
local new_data_dirs = "/usr/local/share:/usr/share:" .. flatpak_paths
if current_data_dirs ~= "" then
	new_data_dirs = new_data_dirs .. ":" .. current_data_dirs
end
hl.env("XDG_DATA_DIRS", new_data_dirs)
