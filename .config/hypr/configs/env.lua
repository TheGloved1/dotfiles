-- Converted from:
-- - config/hypr/configs/ENVariables.conf
-- - config/hypr/UserConfigs/ENVariables.conf (active values only)

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
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-blue")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-mocha-blue")
hl.env("XCURSOR_SIZE", "24")

-- DEFAULTS is populated by lua/defaults.lua (loaded before this).
do
	local defaults = DEFAULTS or {}
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

-- Fix XDG_DATA_DIRS with flatpak support.
-- Dedup against the current value so repeated config reloads never re-append
-- the same dirs (previously grew XDG_DATA_DIRS to thousands of entries).
local current_data_dirs = os.getenv("XDG_DATA_DIRS") or ""
local user_home = os.getenv("HOME") or ""
local canonical_dirs = { "/usr/local/share", "/usr/share", "/var/lib/flatpak/exports/share" }
if user_home ~= "" then
	canonical_dirs[#canonical_dirs + 1] = user_home .. "/.local/share/flatpak/exports/share"
end

local seen, parts = {}, {}
local function append_dir(dir)
	if dir ~= "" and not seen[dir] then
		seen[dir] = true
		parts[#parts + 1] = dir
	end
end

for _, dir in ipairs(canonical_dirs) do
	append_dir(dir)
end
for dir in current_data_dirs:gmatch("[^:]+") do
	append_dir(dir)
end

hl.env("XDG_DATA_DIRS", table.concat(parts, ":"))
