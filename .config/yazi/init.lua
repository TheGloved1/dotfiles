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

-- require("yatline"):setup({
-- 	section_separator = { open = "", close = "" },
-- 	part_separator = { open = "", close = "" },
-- 	inverse_separator = { open = "", close = "" },
--
-- 	style_a = {
-- 		fg = "#1c1b22",
-- 		bg = "#242130",
-- 		fg_mode = { normal = "#1c1b22", select = "#1c1b22", un_set = "#1c1b22" },
-- 		bg_mode = { normal = "#b0a9d1", select = "#c3adcd", un_set = "#cbafc6" },
-- 	},
-- 	style_b = { bg = "#242130", fg = "#b0afb6" },
-- 	style_c = { bg = "#242130", fg = "#f2f2f3" },
--
-- 	header_line = {
-- 		left = {
-- 			section_a = {
-- 				{ type = "notch", custom = false, name = "left" },
-- 				{ type = "line", custom = false, name = "tabs" },
-- 			},
-- 			section_b = {},
-- 			section_c = {},
-- 		},
-- 		right = {
-- 			section_a = {
-- 				{ type = "notch", custom = false, name = "right" },
-- 				{ type = "string", custom = false, name = "date", params = { "%A, %d %B %Y" } },
-- 			},
-- 			section_b = {
-- 				{ type = "string", custom = false, name = "date", params = { "%X" } },
-- 			},
-- 			section_c = {},
-- 		},
-- 	},
--
-- 	status_line = {
-- 		left = {
-- 			section_a = {
-- 				{ type = "notch", custom = false, name = "left" },
-- 				{ type = "string", custom = false, name = "tab_mode" },
-- 			},
-- 			section_b = {
-- 				{ type = "string", custom = false, name = "hovered_size" },
-- 			},
-- 			section_c = {
-- 				{ type = "string", custom = false, name = "hovered_path" },
-- 				{ type = "coloreds", custom = false, name = "count" },
-- 			},
-- 		},
-- 		right = {
-- 			section_a = {
-- 				{ type = "notch", custom = false, name = "right" },
-- 				{ type = "string", custom = false, name = "cursor_position" },
-- 			},
-- 			section_b = {
-- 				{ type = "string", custom = false, name = "cursor_percentage" },
-- 			},
-- 			section_c = {
-- 				{ type = "string", custom = false, name = "hovered_file_extension", params = { true } },
-- 				{ type = "coloreds", custom = false, name = "permissions" },
-- 			},
-- 		},
-- 	},
-- })

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
})

require("git"):setup()

require("recycle-bin"):setup()
require("restore"):setup()
