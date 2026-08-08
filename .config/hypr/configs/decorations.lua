-- Converted from config/hypr/UserConfigs/UserDecorations.conf.
-- Wallust colors loaded dynamically at startup via user_decorations_helper.lua.

-- Try to load wallust colors for dynamic theming
local wallust_colors = {}
do
	local f = io.open(WALLUST_FILE, "r")
	if f then
		for line in f:lines() do
			local var, val = line:match("^%s*source%?=(%$%w+)%s*=%s*(.+)%s*$")
			if var and val then
				wallust_colors[var] = val
			end
			-- Also match: $color0 = #hex
			local name, hex = line:match("^%s*(%$color%d+)%s*=%s*(%S+)")
			if name and hex then
				wallust_colors[name] = hex
			end
		end
		f:close()
	end
end

-- Fallback colors if wallust not loaded
local function get_color(var, fallback)
	return wallust_colors[var] or fallback
end

hl.config({
	general = {
		border_size = 1,
		gaps_in = 6,
		gaps_out = 6,
		col = {
			active_border = get_color("$color12", "rgba(8db4ffff)"),
			inactive_border = get_color("$color10", "rgba(5f6578ff)"),
		},
	},
	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 0.9,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.1,
		dim_special = 0.8,
		shadow = {
			enabled = true,
			range = 1,
			render_power = 1,
			color = get_color("$color12", "rgba(8db4ffff)"),
			color_inactive = get_color("$color10", "rgba(5f6578ff)"),
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
			border_active = get_color("$color15", "rgba(ffffffff)"),
		},
		groupbar = {
			col = {
				active = get_color("$color0", "rgba(0f111aff)"),
			},
		},
	},
})
