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
hl.env("QT_QUICK_CONTROLS_STYLE", "Darkly")
hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("DISPLAY", ":0")

-- Cursor theme
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
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
hl.env("XDG_DATA_DIRS", Utils.xdg_data_dirs())
