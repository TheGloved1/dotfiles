-- Converted from config/hypr/UserConfigs/UserDecorations.conf.
-- Wallust colors loaded dynamically at startup via user_decorations_helper.lua.

hl.config({
	general = {
		border_size = 1,
		gaps_in = 6,
		gaps_out = 6,
		col = {
			active_border = COLORS.color12,
			inactive_border = COLORS.color10,
		},
	},
	decoration = {
		rounding = 4,
		active_opacity = 0.95,
		inactive_opacity = 0.85,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.05,
		dim_special = 0.8,
		shadow = {
			enabled = true,
			range = 1,
			render_power = 1,
			color = COLORS.color12,
			color_inactive = COLORS.color10,
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 3,
			new_optimizations = true,
			xray = false,
			ignore_opacity = true,
			special = true,
			popups = true,
		},
		-- Not released yet in v0.56
		-- wobble = {
		--   enabled = true,
		-- },
	},
	group = {
		col = {
			border_active = COLORS.color15,
		},
		groupbar = {
			col = {
				active = COLORS.color0,
			},
		},
	},
})
