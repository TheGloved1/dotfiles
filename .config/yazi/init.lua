-- Plugins

-- Theme-driven palette — no hardcoding, same as full-border uses th.mgr.border_style
-- full-border succeeds via `ui.Border:style(th.mgr.border_style)` at plugins/full-border.yazi/main.lua:15
-- yatline expects hex strings, but th.* are Style userdata (th.mode.normal_main.bg is function, not "#ea9a97"),
-- so extracting via th.*.bg = nil caused the blank. We read flavor.toml directly instead.
local function load_flavor_colors()
	local fallback = {
		rose = "#ea9a97",
		foam = "#9ccfd8",
		pine = "#3e8fb0",
		base = "#232136",
		overlay = "#393552",
		muted = "#908caa",
		text = "#e0def4",
		iris = "#c4a7e7",
		love = "#eb6f92",
	}
	-- read theme.toml to find active flavor (like yazi does)
	local theme_path = os.getenv("HOME") .. "/.config/yazi/theme.toml"
	local flavor = "noctalia"
	local tf = io.open(theme_path, "r")
	if tf then
		local data = tf:read("*a")
		tf:close()
		local use = data:match('use%s*=%s*"([^"]+)"') or data:match("use%s*=%s*'([^']+)'")
		if use then
			flavor = use
		end
	end
	local flavor_path = os.getenv("HOME") .. "/.config/yazi/flavors/" .. flavor .. ".yazi/flavor.toml"
	local f = io.open(flavor_path, "r")
	if not f then
		return fallback
	end
	local txt = f:read("*a")
	f:close()
	local function grab(section, key)
		-- match [section] ... key = { ... bg = "#xxxxxx" ... fg = "#xxxxxx" }
		local pat = "%[" .. section .. "%][%s%S]-" .. key .. "%s*=%s*%{([^}]+)%}"
		local block = txt:match(pat)
		if not block then
			return nil
		end
		local bg = block:match('bg%s*=%s*"([^"]+)"') or block:match("bg%s*=%s*'([^']+)'")
		local fg = block:match('fg%s*=%s*"([^"]+)"') or block:match("fg%s*=%s*'([^']+)'")
		return { bg = bg, fg = fg }
	end
	local function grab_status(key)
		local block = txt:match("%[status%][%s%S]-" .. key .. "%s*=%s*%{([^}]+)%}")
		if not block then
			return nil
		end
		return block:match('fg%s*=%s*"([^"]+)"')
	end
	local nm = grab("mode", "normal_main") or { bg = fallback.rose, fg = fallback.base }
	local sm = grab("mode", "select_main") or { bg = fallback.foam, fg = fallback.base }
	local um = grab("mode", "unset_main") or { bg = fallback.pine, fg = fallback.text }
	local alt = grab("mode", "normal_alt") or { bg = fallback.overlay, fg = fallback.muted }
	local perm_t = grab_status("perm_type") or fallback.foam
	local perm_r = grab_status("perm_read") or fallback.text
	local perm_w = grab_status("perm_write") or fallback.pine
	local perm_x = grab_status("perm_exec") or fallback.love
	local perm_s = grab_status("perm_sep") or "#6e6a86"
	if perm_r == "#112f3c" then
		perm_r = fallback.text
	end -- fix invisible from noctalia
	return {
		rose = nm.bg or fallback.rose,
		base = nm.fg or fallback.base,
		foam = sm.bg or fallback.foam,
		pine = um.bg or fallback.pine,
		overlay = alt.bg or fallback.overlay,
		muted = alt.fg or fallback.muted,
		text = fallback.text,
		iris = fallback.iris,
		love = fallback.love,
		perm_t = perm_t,
		perm_r = perm_r,
		perm_w = perm_w,
		perm_x = perm_x,
		perm_s = perm_s,
	}
end

require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

require("zoxide"):setup({
	update_db = true,
})

require("session"):setup({
	sync_yanked = true,
})

require("git"):setup()

-- require("mobile-auto-layout"):setup()

local pal = load_flavor_colors()

local ok, err = pcall(function()
	require("yatline"):setup({
		-- section_separator = { open = "", close = "" },
		-- part_separator = { open = "", close = "" },
		-- inverse_separator = { open = "", close = "" },
		padding = { inner = 1, outer = 1 },

		-- now derived from flavor.toml, not hardcoded — matches full-border's th-driven approach
		style_a = {
			fg = pal.base,
			bg = pal.rose,
			bg_mode = {
				normal = pal.rose,
				select = pal.foam,
				un_set = pal.pine,
			},
		},
		style_b = { bg = pal.overlay, fg = pal.muted },
		style_c = { bg = pal.base, fg = pal.text },

		permissions_t_fg = pal.perm_t,
		permissions_r_fg = pal.perm_r,
		permissions_w_fg = pal.perm_w,
		permissions_x_fg = pal.perm_x,
		permissions_s_fg = pal.perm_s,

		show_background = true,
		display_header_line = true,
		display_status_line = true,

		status_line = {
			left = {
				section_a = { { type = "string", name = "tab_mode" } },
				section_b = { { type = "string", name = "hovered_size" }, { type = "string", name = "hovered_name" } },
				section_c = { { type = "coloreds", name = "count" } }, -- githead added later after visible
			},
			right = {
				section_a = { { type = "string", name = "cursor_position" } },
				section_b = { { type = "string", name = "cursor_percentage" } },
				section_c = {
					{ type = "string", name = "hovered_file_extension", params = { true } },
					{ type = "coloreds", name = "permissions" },
				},
			},
		},
		header_line = {
			left = { section_a = { { type = "line", name = "tabs" } }, section_b = {}, section_c = {} },
			right = {
				section_a = { { type = "string", name = "date", params = { "%A, %d %B %Y" } } },
				section_b = { { type = "string", name = "date", params = { "%X" } } },
				section_c = {},
			},
		},
	})
end)

if not ok then
	local f = io.open("/tmp/yazi_yatline_err.log", "w")
	if f then
		f:write(tostring(err) .. "\n")
		f:close()
	end
end
