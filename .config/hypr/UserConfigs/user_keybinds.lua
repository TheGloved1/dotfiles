-- User keybind overrides.
-- Ported from UserConfigs/UserKeybinds.conf
local user_keybinds_helper = nil
do
	local source = (debug.getinfo(1, "S") or {}).source or ""
	local source_path = source:match("^@(.+)$")
	local source_dir = source_path and source_path:match("^(.*)/[^/]+$") or nil
	local home = os.getenv("HOME") or ""
	local candidate_paths = {
		source_dir and (source_dir .. "/../lua/user_keybinds_helper.lua") or nil,
		home ~= "" and (home .. "/.config/hypr/lua/user_keybinds_helper.lua") or nil,
		home ~= "" and (home .. "/.config/hypr/user_keybinds_helper.lua") or nil,
	}

	local tried_paths = {}
	for _, helper_path in ipairs(candidate_paths) do
		if helper_path then
			table.insert(tried_paths, helper_path)
			local f = io.open(helper_path, "r")
			if f then
				f:close()
				local loaded_ok, loaded_helpers = pcall(dofile, helper_path)
				if loaded_ok and type(loaded_helpers) == "table" and loaded_helpers.bind then
					user_keybinds_helper = loaded_helpers
					break
				end
			end
		end
	end

	if not user_keybinds_helper then
		error("Failed to load user_keybinds_helper.lua from: " .. table.concat(tried_paths, ", "))
	end
end
local exec_cmd = user_keybinds_helper.exec_cmd
local bind = user_keybinds_helper.bind
local unbind = user_keybinds_helper.unbind

local scriptsDir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/scripts"

-- ==================
-- Unbinds
-- ==================

-- Unbind resize on SUPER+SHIFT+arrows (conflicts with move window)
unbind("SUPER SHIFT", "left")
unbind("SUPER SHIFT", "right")
unbind("SUPER SHIFT", "up")
unbind("SUPER SHIFT", "down")

-- Unbind system SUPER+A/F (rebinding to workspace move)
unbind("SUPER", "A")
unbind("SUPER", "F")

-- Unbind arrow focus keys (rebinding to HJKL)
unbind("SUPER", "left")
unbind("SUPER", "right")
unbind("SUPER", "up")
unbind("SUPER", "down")

-- Unbind H/J/K (rebinding to focus)
unbind("SUPER", "H")
unbind("SUPER", "J")
unbind("SUPER", "K")

-- Unbind SUPER+SHIFT+H (rebinding to MoveWrap.sh)
unbind("SUPER SHIFT", "H")

-- Unbind D and SPACE (swapping)
unbind("SUPER", "D")
unbind("SUPER", "SPACE")

-- Unbind P (rebinding to color picker)
unbind("SUPER", "P")

-- ==================
-- Rebinds
-- ==================

-- ALT+SPACE: Toggle vicinae
bind("ALT", "SPACE", exec_cmd("vicinae toggle"), { description = "Toggle vicinae" })

-- Move window in direction (crosses displays)
bind("SUPER SHIFT", "left", exec_cmd("movewindow l"), { description = "Move window left" })
bind("SUPER SHIFT", "right", exec_cmd("movewindow r"), { description = "Move window right" })
bind("SUPER SHIFT", "up", exec_cmd("movewindow u"), { description = "Move window up" })
bind("SUPER SHIFT", "down", exec_cmd("movewindow d"), { description = "Move window down" })
bind("SUPER SHIFT", "H", exec_cmd(scriptsDir .. "/MoveWrap.sh l"), { description = "Move window left" })
bind("SUPER SHIFT", "L", exec_cmd(scriptsDir .. "/MoveWrap.sh r"), { description = "Move window right" })
bind("SUPER SHIFT", "K", exec_cmd(scriptsDir .. "/MoveWrap.sh u"), { description = "Move window up / prev workspace" })
bind(
	"SUPER SHIFT",
	"J",
	exec_cmd(scriptsDir .. "/MoveWrap.sh d"),
	{ description = "Move window down / next workspace" }
)

-- Move workspace across displays (SUPER+A/F)
bind("SUPER", "A", exec_cmd("movecurrentworkspacetomonitor l"), { description = "Move workspace left" })
bind("SUPER", "F", exec_cmd("movecurrentworkspacetomonitor r"), { description = "Move workspace right" })

-- Displaced app rebinds (CTRL variants)
bind("SUPER CTRL", "A", exec_cmd(scriptsDir .. "/OverviewToggle.sh"), { description = "Desktop overview" })
bind("SUPER CTRL", "F", exec_cmd("fullscreen 1"), { description = "Maximize window" })

-- Swapped D and SPACE
bind("SUPER", "D", exec_cmd("togglefloating"), { description = "Toggle float" })
bind(
	"SUPER",
	"SPACE",
	exec_cmd(
		"pkill rofi || true; "
			.. scriptsDir
			.. "/RofiFocusedWallpaperLink.sh >/dev/null 2>&1 || true; rofi -show drun -modi drun,filebrowser,run,window"
	),
	{ description = "App launcher" }
)

-- VIM-style window focus (replaces arrows)
bind("SUPER", "H", exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh focus-left"), { description = "Focus left" })
bind("SUPER", "J", exec_cmd(scriptsDir .. "/FocusWrap.sh d"), { description = "Focus down / next workspace" })
bind("SUPER", "K", exec_cmd(scriptsDir .. "/FocusWrap.sh u"), { description = "Focus up / prev workspace" })
bind("SUPER", "L", exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh focus-right"), { description = "Focus right" })

-- Help menu moved from SUPER+H
bind("SUPER", "slash", exec_cmd(scriptsDir .. "/KeyHints.sh"), { description = "Help / cheat sheet" })

-- Cycle next/prev moved from SUPER+J/K
bind(
	"SUPER",
	"bracketleft",
	exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh cycle-next"),
	{ description = "Cycle next (layout-aware)" }
)
bind(
	"SUPER",
	"bracketright",
	exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh cycle-prev"),
	{ description = "Cycle previous (layout-aware)" }
)

-- Color picker (replaces pseudo toggle)
bind("SUPER", "P", exec_cmd("hyprpicker -a -f hex --lowercase-hex"), { description = "Color picker" })
