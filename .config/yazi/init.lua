local catppuccin_palette = {
	rosewater = "#f4dbd6",
	flamingo = "#f0c6c6",
	pink = "#f5bde6",
	mauve = "#c6a0f6",
	red = "#ed8796",
	maroon = "#ee99a0",
	peach = "#f5a97f",
	yellow = "#eed49f",
	green = "#a6da95",
	teal = "#8bd5ca",
	sky = "#91d7e3",
	sapphire = "#7dc4e4",
	blue = "#8aadf4",
	lavender = "#b7bdf8",
	text = "#cad3f5",
	subtext1 = "#b8c0e0",
	subtext0 = "#a5adcb",
	overlay2 = "#939ab7",
	overlay1 = "#8087a2",
	overlay0 = "#6e738d",
	surface2 = "#5b6078",
	surface1 = "#494d64",
	surface0 = "#363a4f",
	base = "#24273a",
	mantle = "#1e2030",
	crust = "#181926",
}

-- Plugins
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

require("zoxide"):setup({
	update_db = true,
})

require("session"):setup({
	sync_yanked = true,
})

local term_bg = "#1b1a23"

require("yatline")

Yatline.notch = {
	has_separator = false,
	get = {
		left = function()
			return ""
		end,
		right = function()
			return ""
		end,
	},
	create = function(glyph, component_type)
		local style = Yatline.config.style_a
		local mode = cx.active.mode
		local bg = style.bg_mode.normal
		if mode.is_select then
			bg = style.bg_mode.select
		elseif mode.is_unset then
			bg = style.bg_mode.un_set
		end
		return ui.Line({ ui.Span(glyph):fg(bg):bg(term_bg) })
	end,
}

require("yatline"):setup({
	section_separator = { open = "", close = "" },
	part_separator = { open = "", close = "" },
	inverse_separator = { open = "", close = "" },

	style_a = {
		fg = "#1c1b22",
		bg = "#242130",
		fg_mode = { normal = "#1c1b22", select = "#1c1b22", un_set = "#1c1b22" },
		bg_mode = { normal = "#b0a9d1", select = "#c3adcd", un_set = "#cbafc6" },
	},
	style_b = { bg = "#242130", fg = "#b0afb6" },
	style_c = { bg = "#242130", fg = "#f2f2f3" },

	header_line = {
		left = {
			section_a = {
				{ type = "notch", custom = false, name = "left" },
				{ type = "line", custom = false, name = "tabs" },
			},
			section_b = {},
			section_c = {},
		},
		right = {
			section_a = {
				{ type = "notch", custom = false, name = "right" },
				{ type = "string", custom = false, name = "date", params = { "%A, %d %B %Y" } },
			},
			section_b = {
				{ type = "string", custom = false, name = "date", params = { "%X" } },
			},
			section_c = {},
		},
	},

	status_line = {
		left = {
			section_a = {
				{ type = "notch", custom = false, name = "left" },
				{ type = "string", custom = false, name = "tab_mode" },
			},
			section_b = {
				{ type = "string", custom = false, name = "hovered_size" },
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_path" },
				{ type = "coloreds", custom = false, name = "count" },
			},
		},
		right = {
			section_a = {
				{ type = "notch", custom = false, name = "right" },
				{ type = "string", custom = false, name = "cursor_position" },
			},
			section_b = {
				{ type = "string", custom = false, name = "cursor_percentage" },
			},
			section_c = {
				{ type = "string", custom = false, name = "hovered_file_extension", params = { true } },
				{ type = "coloreds", custom = false, name = "permissions" },
			},
		},
	},
})

require("yatline-githead"):setup({
	show_branch = true,
	branch_prefix = "",
	branch_symbol = "",
	branch_borders = "",

	commit_symbol = " ",

	show_stashes = true,
	stashes_symbol = " ",

	show_state = true,
	show_state_prefix = true,
	state_symbol = "󱅉",

	show_staged = true,
	staged_symbol = " ",

	show_unstaged = true,
	unstaged_symbol = " ",

	show_untracked = true,
	untracked_symbol = " ",

	prefix_color = catppuccin_palette.pink,
	branch_color = catppuccin_palette.pink,
	commit_color = catppuccin_palette.mauve,
	stashes_color = catppuccin_palette.teal,
	state_color = catppuccin_palette.lavender,
	staged_color = catppuccin_palette.green,
	unstaged_color = catppuccin_palette.yellow,
	untracked_color = catppuccin_palette.pink,
})

require("git"):setup()

require("recycle-bin"):setup()
require("restore"):setup()
