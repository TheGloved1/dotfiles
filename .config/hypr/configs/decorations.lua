-- Converted from config/hypr/UserConfigs/UserDecorations.conf.
-- Wallust colors loaded dynamically at startup via user_decorations_helper.lua.

hl.config({
	general = {
		border_size = 1,
		gaps_in = 6,
		gaps_out = 6,
		col = {
			active_border = WALLUST.color12,
			inactive_border = WALLUST.color10,
		},
	},
	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 0.85,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.1,
		dim_special = 0.8,
		shadow = {
			enabled = true,
			range = 1,
			render_power = 1,
			color = WALLUST.color12,
			color_inactive = WALLUST.color10,
		},
		blur = {
			enabled = true,
			size = 6,
			passes = 3,
			new_optimizations = true,
			xray = true,
			ignore_opacity = true,
			special = true,
			popups = true,
		},
		-- Not released yet in v0.56
		-- wobble = {
		-- 	enabled = true,
		-- },
	},
	group = {
		col = {
			border_active = WALLUST.color15,
		},
		groupbar = {
			col = {
				active = WALLUST.color0,
			},
		},
	},
})
