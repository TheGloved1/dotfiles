-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- Wallust color loader for the Lua config workflow.
--
-- wallust regenerates ~/.config/hypr/wallust/wallust-hyprland.conf in
-- hyprlang format (e.g. "$color12 = rgb(89B4FA)"). Hyprland's Lua config has
-- no `source=` keyword, so we parse that file here and expose color0..color15
-- as globals (both as `wallust.colors` and as top-level `colorN` variables)
-- for use in decoration/animation config files.

local WALLUST_CONF = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config"))
	.. "/hypr/wallust/wallust-hyprland.conf"

-- Convert an rgb() hex color to Hyprland rgba() form: rgba(RRGGBBAA)
-- Hyprland Lua colors are given as rgba(RRGGBBFF).
local function to_rgba(hex)
	hex = (hex or ""):gsub("#", ""):gsub("[^0-9A-Fa-f]", "")
	if hex:len() == 6 then
		return "rgba(" .. hex:lower() .. "ff)"
	elseif hex:len() == 8 then
		return "rgba(" .. hex:lower() .. ")"
	end
	return nil
end

local colors = {}
local f, err = io.open(WALLUST_CONF, "r")
if f then
	for line in f:lines() do
		local name, value = line:match("^%$([%w_]+)%s*=%s*(.+)$")
		if name and value then
			local hex = value:match("rgb%(([0-9A-Fa-f]+)%)") or value:match("^%s*(%x+)%s*$")
			if hex then
				local rgba = to_rgba(hex)
				if rgba then
					colors[name:lower()] = rgba
					colors[name] = rgba
				end
			end
		end
	end
	f:close()
end

WALLUST = WALLUST or {}
WALLUST.colors = colors

-- Expose color0..color15 as top-level globals so legacy-style lua files can
-- reference e.g. `color12` directly without a WALLUST prefix.
for k, v in pairs(colors) do
	if k:match("^color%d+$") then
		_G[k] = v
	end
end

_G.color_background = colors.background or "rgba(1e1e2eff)"
_G.color_foreground = colors.foreground or "rgba(cdd6f4ff)"
