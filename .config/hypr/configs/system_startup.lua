-- These run on every Hyprland session start.

local user_startup_helper = nil
do
	local source = (debug.getinfo(1, "S") or {}).source or ""
	local source_path = source:match("^@(.+)$")
	local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
	local home = os.getenv("HOME") or ""
	local candidate_paths = {
		source_dir and (source_dir .. "/../lua/user_startup_helper.lua") or nil,
		home ~= "" and (home .. "/.config/hypr/lua/user_startup_helper.lua") or nil,
		home ~= "" and (home .. "/.config/hypr/user_startup_helper.lua") or nil,
	}

	local tried_paths = {}
	for _, helper_path in ipairs(candidate_paths) do
		if helper_path then
			table.insert(tried_paths, helper_path)
			local f = io.open(helper_path, "r")
			if f then
				f:close()
				local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
				if loaded_ok and type(loaded_helpers) == "table" and loaded_helpers.exec_once then
					user_startup_helper = loaded_helpers
					break
				end
			end
		end
	end

	if not user_startup_helper then
		error("Failed to load user_startup_helper.lua from: " .. table.concat(tried_paths, ", "))
	end
end

local exec_once = user_startup_helper.exec_once

-- Wallpaper (with sleep for startup)
exec_once("sh -c 'sleep 2; $HOME/.config/hypr/scripts/WallpaperDaemon.sh'")

-- Initial boot
exec_once("$HOME/.config/hypr/initial-boot.sh")

-- DBus / systemd environment
exec_once("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
exec_once("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

-- Core services
exec_once("$HOME/.config/hypr/scripts/Polkit.sh")
exec_once("nm-applet")
exec_once("swaync")

-- Portals and theme
exec_once("$HOME/.config/hypr/scripts/PortalHyprland.sh")
exec_once("sh $HOME/.config/hypr/scripts/ApplyThemeMode.sh")

-- Waybar
exec_once("sh $HOME/.config/hypr/scripts/WaybarStartup.sh")

-- Cursor refresh
exec_once(
	'sh -c \'sleep 0.3; hyprctl setcursor "${HYPRCURSOR_THEME:-Catppuccin-Mocha-Lavender}" "${HYPRCURSOR_SIZE:-24}"\''
)

-- Quickshell overview
exec_once("qs -c overview")

-- Idle manager
exec_once("hypridle")

-- Hyprsunset
exec_once("$HOME/.config/hypr/scripts/Hyprsunset.sh init")

-- Drop terminal
exec_once("$HOME/.config/hypr/scripts/Dropterminal.sh --startup kitty")

-- Clipboard manager
exec_once("wl-paste --type text --watch cliphist store")
exec_once("wl-paste --type image --watch cliphist store")

-- Bluetooth
exec_once("blueman-applet")

-- Keybinds layout init
exec_once("$HOME/.config/hypr/scripts/KeybindsLayoutInit.sh")

-- AGS
exec_once("ags")
