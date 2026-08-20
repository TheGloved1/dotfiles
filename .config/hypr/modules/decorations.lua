local colors = Noctalia.colors

hl.config({
	general = {
		border_size = 2,
		gaps_in = 6,
		gaps_out = 8,
		col = {
			active_border = colors.primary,
			inactive_border = colors.surface,
		},
	},
	decoration = {
		rounding = 4,
		rounding_power = 32,
		active_opacity = 0.95,
		inactive_opacity = 0.95,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0,
		dim_special = 0.8,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(00000070)",
		},
		blur = {
			enabled = true,
			size = 4,
			passes = 2,
			new_optimizations = true,
			xray = false,
			ignore_opacity = true,
			special = true,
			popups = true,
			input_methods = true,
		},
		-- Not released yet in v0.56
		-- wobble = {
		--   enabled = true,
		-- },
	},
	group = {
		col = {
			border_active = colors.secondary,
			border_inactive = colors.surface,
			border_locked_active = colors.error,
			border_locked_inactive = colors.surface,
		},
		groupbar = {
			font_family = "CaskaydiaCove Nerd Font",
			font_size = 12,
			gradients = true,
			gradient_rounding = 8,
			height = 16,
			indicator_height = 0,
			-- gaps_in = 80,
			gaps_out = 2,
			text_color = colors.surface,
			col = {
				active = colors.secondary,
				inactive = colors.surface,
				locked_active = colors.error,
				locked_inactive = colors.surface,
			},
		},
	},
})
