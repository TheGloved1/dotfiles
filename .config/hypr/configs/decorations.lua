-- Caelestia styling applied to the existing config structure.
-- Colours follow the caelestia scheme (~/.config/hypr/scheme/current.lua).

local SCHEME = require("scheme.current")

local active_border = "rgba(" .. SCHEME.primary .. "e6)"
local inactive_border = "rgba(" .. SCHEME.onSurfaceVariant .. "11)"
local shadow_colour = "rgba(" .. SCHEME.inversePrimary .. "10)"

hl.config({
	general = {
		border_size = 2,
		gaps_in = 6,
		gaps_out = 6,
		col = {
			active_border = active_border,
			inactive_border = inactive_border,
		},
	},
	decoration = {
		rounding = 12,
		active_opacity = 0.95,
		inactive_opacity = 0.85,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.05,
		dim_special = 0.8,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = shadow_colour,
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 2,
			new_optimizations = true,
			xray = false,
			ignore_opacity = true,
			special = false,
			popups = true,
			input_methods = true,
			vibrancy = 0.1696,
		},
		-- Not released yet in v0.56
		-- wobble = {
		--   enabled = true,
		-- },
	},
	group = {
		col = {
			border_active = active_border,
			border_inactive = inactive_border,
		},
		groupbar = {
			font_family = "JetBrainsMono Nerd Font",
			font_size = 12,
			gradients = true,
			gradient_rounding = 5,
			height = 25,
			indicator_height = 0,
			gaps_in = 2,
			gaps_out = 2,
			text_color = "rgb(" .. SCHEME.onPrimary .. ")",
			col = {
				active = "rgba(" .. SCHEME.primary .. "d4)",
				inactive = "rgba(" .. SCHEME.outline .. "d4)",
				locked_active = "rgba(" .. SCHEME.primary .. "d4)",
				locked_inactive = "rgba(" .. SCHEME.secondary .. "d4)",
			},
		},
	},
})
