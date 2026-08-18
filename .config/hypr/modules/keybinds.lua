local defaults = DEFAULTS
local term = defaults.term
local files = defaults.files

local bind = hl.bind
local cmd = hl.dsp.exec_cmd
local layout = hl.dsp.layout
local focus = hl.dsp.focus
local window = hl.dsp.window
local workspace = hl.dsp.workspace
local group = hl.dsp.group

-- ============================================
--  LAUNCHERS
-- ============================================
bind("SUPER + Return", function()
	Utils.launch_terminal(term)
end, { description = "Open terminal" })
bind("SUPER + E", function()
	Utils.launch_file_manager(files, term)
end, { description = "file manager" })
bind("SUPER + B", cmd('xdg-open "https://"'), { description = "open default browser" })
bind("SUPER + SUPER_L", cmd("noctalia msg panel-toggle launcher"), { description = "App launcher" })
bind("SUPER + SPACE", cmd("noctalia msg panel-toggle control-center home"), { description = "App launcher" })
-- bind("SUPER + SHIFT + Return", function() Utils.dropterminal("toggle", "kitty") end, { description = "DropDown terminal" })
bind(
	"SUPER + slash",
	cmd("noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
	{ description = "Help / cheat sheet" }
)
bind(
	"SUPER + SHIFT + slash",
	cmd("noctalia msg plugin alexander/screen-toolkit:service all toggle"),
	{ description = "Noctalia Screen Toolkit" }
)
bind("SUPER + P", cmd("hyprpicker -a -f hex --lowercase-hex"), { description = "Color picker" })
bind("ALT + SPACE", cmd("vicinae toggle"), { description = "Toggle vicinae" })

-- ============================================
--  DESKTOP / OVERVIEW
-- ============================================
bind("SUPER + A", cmd("noctalia msg window-switcher"), { description = "desktop overview" })
-- bind("SUPER + CTRL + S", exec("rofi -show window"), { description = "window switcher" })
if hl.plugin.scrolloverview then
	bind("SUPER + tab", function()
		hl.plugin.scrolloverview.overview("toggle all")
	end, { description = "niri-style overview" })
end

-- ============================================
--  WINDOW MANAGEMENT
-- ============================================
bind("SUPER + Q", window.close(), { description = "close active window" })
bind("SUPER + SHIFT + Q", function()
	Utils.kill_active_process()
end, { description = "Terminate active process" })
bind("SUPER + F", window.fullscreen({ mode = "maximized" }), { description = "maximize window" })
bind("SUPER + SHIFT + F", window.fullscreen(), { description = "fullscreen" })
bind("SUPER + D", window.float({ action = "toggle" }), { description = "Toggle float" })
bind("SUPER + ALT + SPACE", function()
	Utils.float_all_windows()
end, { description = "Float all windows" })
bind(
	"SUPER + CTRL + O",
	window.set_prop({ prop = "opaque", value = "toggle" }),
	{ description = "toggle active window opacity" }
)
local blur_opaque_rule = hl.window_rule({
	name = "blur-toggle-opaque",
	match = { class = ".*" },
	opaque = true,
})
blur_opaque_rule:set_enabled(false)
bind("SUPER + ALT + O", function()
	local enabled = hl.get_config("decoration.blur.enabled")
	if enabled then
		hl.config({
			decoration = {
				blur = { enabled = false },
				active_opacity = 1,
				inactive_opacity = 1,
			},
		})
		blur_opaque_rule:set_enabled(true)
	else
		hl.config({
			decoration = {
				blur = { enabled = true },
				active_opacity = 0.95,
				inactive_opacity = 0.85,
			},
		})
		blur_opaque_rule:set_enabled(false)
	end
end, { description = "toggle blur & opacity" })

-- ============================================
--  FOCUS / NAVIGATION
-- ============================================
bind("SUPER + H", function()
	Utils.layout_keybind_dispatch("focus-left")
end, { description = "Focus left", repeating = true })
bind("SUPER + L", function()
	Utils.layout_keybind_dispatch("focus-right")
end, { description = "Focus right", repeating = true })
bind("SUPER + J", function()
	Utils.focus_wrap("d")
end, { description = "Focus down / next workspace", repeating = true })
bind("SUPER + K", function()
	Utils.focus_wrap("u")
end, { description = "Focus up / prev workspace", repeating = true })
bind("SUPER + up", function()
	Utils.layout_keybind_dispatch("focus-up")
end, { description = "focus up (layout-aware)" })
bind("SUPER + down", function()
	Utils.layout_keybind_dispatch("focus-down")
end, { description = "focus down (layout-aware)" })
bind("ALT + Tab", window.cycle_next(), { description = "cycle next window" })
bind("SUPER + bracketleft", function()
	Utils.layout_keybind_dispatch("cycle-next")
end, { description = "Cycle next (layout-aware)" })
bind("SUPER + bracketright", function()
	Utils.layout_keybind_dispatch("cycle-prev")
end, { description = "Cycle previous (layout-aware)" })

-- ============================================
--  MOVE / SWAP / RESIZE
-- ============================================
bind("SUPER + CTRL + H", window.move({ direction = "left" }), { description = "move window left" })
bind("SUPER + CTRL + L", window.move({ direction = "right" }), { description = "move window right" })
bind("SUPER + CTRL + K", window.move({ direction = "up" }), { description = "move window up" })
bind("SUPER + CTRL + J", window.move({ direction = "down" }), { description = "move window down" })
bind("SUPER + ALT + left", window.swap({ direction = "left" }), { description = "swap window left" })
bind("SUPER + ALT + right", window.swap({ direction = "right" }), { description = "swap window right" })
bind("SUPER + ALT + up", window.swap({ direction = "up" }), { description = "swap window up" })
bind("SUPER + ALT + down", window.swap({ direction = "down" }), { description = "swap window down" })
bind("SUPER + SHIFT + H", function()
	Utils.move_wrap("l")
end, { description = "Move window left", repeating = true })
bind("SUPER + SHIFT + L", function()
	Utils.move_wrap("r")
end, { description = "Move window right", repeating = true })
bind("SUPER + SHIFT + K", function()
	Utils.move_wrap("u")
end, { description = "Move window up / prev workspace", repeating = true })
bind("SUPER + SHIFT + J", function()
	Utils.move_wrap("d")
end, { description = "Move window down / next workspace", repeating = true })
bind(
	"SUPER + ALT + H",
	window.resize({ x = -50, y = 0, relative = true }),
	{ description = "resize left (-50)", repeating = true }
)
bind(
	"SUPER + ALT + L",
	window.resize({ x = 50, y = 0, relative = true }),
	{ description = "resize right (+50)", repeating = true }
)
bind(
	"SUPER + ALT + K",
	window.resize({ x = 0, y = -50, relative = true }),
	{ description = "resize up (-50)", repeating = true }
)
bind(
	"SUPER + ALT + J",
	window.resize({ x = 0, y = 50, relative = true }),
	{ description = "resize down (+50)", repeating = true }
)
bind("SUPER + mouse:272", window.drag(), { description = "move window", mouse = true })
bind("SUPER + mouse:273", window.resize(), { description = "resize window", mouse = true })

-- ============================================
--  LAYOUT
-- ============================================
bind("SUPER + I", layout("addmaster"), { description = "add master" })
bind("SUPER + CTRL + D", layout("removemaster"), { description = "remove master" })
bind("SUPER + CTRL + Return", layout("swapwithmaster"), { description = "swap with master" })
bind("SUPER + SHIFT + I", layout("togglesplit"), { description = "toggle split (dwindle)" })
bind("SUPER + ALT + 1", function()
	Utils.change_layout("dwindle")
end, { description = "layout dwindle" })
bind("SUPER + ALT + 2", function()
	Utils.change_layout("master")
end, { description = "layout master" })
bind("SUPER + ALT + 3", function()
	Utils.change_layout("scrolling")
end, { description = "layout scrolling" })
bind("SUPER + ALT + 4", function()
	Utils.change_layout("monocle")
end, { description = "layout monocle" })
bind("SUPER + SHIFT + period", layout("move +col"), { description = "move to right column" })
bind("SUPER + SHIFT + comma", layout("move -col"), { description = "move to left column" })
bind("SUPER + ALT + comma", layout("swapcol l"), { description = "swap columns left" })
bind("SUPER + ALT + period", layout("swapcol r"), { description = "swap columns right" })

-- ============================================
--  WORKSPACES
-- ============================================
bind("SUPER + mouse_down", focus({ workspace = "e+1" }), { description = "next workspace" })
bind("SUPER + mouse_up", focus({ workspace = "e-1" }), { description = "previous workspace" })
bind("SUPER + U", workspace.toggle_special(), { description = "toggle special workspace" })
bind("SUPER + SHIFT + U", window.move({ workspace = "special" }), { description = "move to special workspace" })
bind("SUPER + 1", focus({ workspace = 1 }), { description = "workspace 1" })
bind("SUPER + 2", focus({ workspace = 2 }), { description = "workspace 2" })
bind("SUPER + 3", focus({ workspace = 3 }), { description = "workspace 3" })
bind("SUPER + 4", focus({ workspace = 4 }), { description = "workspace 4" })
bind("SUPER + 5", focus({ workspace = 5 }), { description = "workspace 5" })
bind("SUPER + 6", focus({ workspace = 6 }), { description = "workspace 6" })
bind("SUPER + 7", focus({ workspace = 7 }), { description = "workspace 7" })
bind("SUPER + 8", focus({ workspace = 8 }), { description = "workspace 8" })
bind("SUPER + 9", focus({ workspace = 9 }), { description = "workspace 9" })
bind("SUPER + 0", focus({ workspace = 10 }), { description = "workspace 10" })
bind("SUPER + SHIFT + 1", window.move({ workspace = 1 }), { description = "move to workspace 1" })
bind("SUPER + SHIFT + 2", window.move({ workspace = 2 }), { description = "move to workspace 2" })
bind("SUPER + SHIFT + 3", window.move({ workspace = 3 }), { description = "move to workspace 3" })
bind("SUPER + SHIFT + 4", window.move({ workspace = 4 }), { description = "move to workspace 4" })
bind("SUPER + SHIFT + 5", window.move({ workspace = 5 }), { description = "move to workspace 5" })
bind("SUPER + SHIFT + 6", window.move({ workspace = 6 }), { description = "move to workspace 6" })
bind("SUPER + SHIFT + 7", window.move({ workspace = 7 }), { description = "move to workspace 7" })
bind("SUPER + SHIFT + 8", window.move({ workspace = 8 }), { description = "move to workspace 8" })
bind("SUPER + SHIFT + 9", window.move({ workspace = 9 }), { description = "move to workspace 9" })
bind("SUPER + SHIFT + 0", window.move({ workspace = 10 }), { description = "move to workspace 10" })

-- ============================================
--  GROUPS
-- ============================================
bind("SUPER + G", group.toggle(), { description = "toggle group" })

-- ============================================
--  SCREENSHOTS / RECORD
-- ============================================
bind("SUPER + Print", cmd("noctalia msg screenshot-fullscreen"), { description = "screenshot fullscreen" })
bind("SUPER + SHIFT + Print", cmd("noctalia msg screenshot-region"), { description = "screenshot region" })
bind(
	"SUPER + CTRL + Print",
	cmd("noctalia msg screenshot-fullscreen pick"),
	{ description = "screenshot pick monitor" }
)
bind(
	"SUPER + CTRL + SHIFT + Print",
	cmd("noctalia msg screenshot-fullscreen all"),
	{ description = "screenshot all monitors" }
)
bind("ALT + Print", cmd("noctalia msg screenshot-fullscreen monitor"), { description = "screenshot active monitor" })
bind(
	"SUPER + SHIFT + S",
	cmd("noctalia msg plugin gloves/screenshot-actions:service all capture"),
	{ description = "screenshot region → menu (Swappy/OCR)" }
)
bind(
	"SUPER + S",
	cmd("noctalia msg panel-toggle gloves/screenshot-actions:history"),
	{ description = "Screenshot history" }
)
bind(
	"SUPER + ALT + S",
	cmd("noctalia msg plugin alexander/screen-toolkit:service all toggle"),
	{ description = "screen toolkit panel" }
)
bind(
	"SUPER + SHIFT + O",
	cmd("noctalia msg plugin alexander/screen-toolkit:service all ocr"),
	{ description = "screenshot region → OCR" }
)
bind(
	"SUPER + SHIFT + C",
	cmd("noctalia msg plugin alexander/screen-toolkit:service all colorPicker"),
	{ description = "pick color from screen" }
)
bind(
	"ALT + SHIFT + S",
	cmd("noctalia msg panel-toggle alexander/screen-toolkit:panel-legacy"),
	{ description = "screen toolkit panel (legacy)" }
)
bind(
	"CTRL + ALT + R",
	cmd("noctalia msg plugin alexander/screen-toolkit:service all start"),
	{ description = "record screen (region)" }
)
bind(
	"SUPER + ALT + R",
	cmd("noctalia msg plugin alexander/screen-toolkit:service all start-fullscreen"),
	{ description = "record screen (fullscreen)" }
)
bind(
	"SUPER + SHIFT + ALT + R",
	cmd("noctalia msg plugin alexander/screen-toolkit:service all stop"),
	{ description = "stop screen recording" }
)
bind(
	"SUPER + SHIFT + CTRL + R",
	cmd("noctalia msg plugin noctalia/screen_recorder:service all replay-start"),
	{ description = "Start replay buffer / Save replay" }
)

-- ============================================
--  MEDIA / VOLUME
-- ============================================
bind(
	"XF86AudioRaiseVolume",
	cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ description = "volume up", locked = true, repeating = true }
)
bind(
	"XF86AudioLowerVolume",
	cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ description = "volume down", locked = true, repeating = true }
)
bind(
	"ALT + XF86AudioRaiseVolume",
	cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%+"),
	{ description = "volume up precise", locked = true, repeating = true }
)
bind(
	"ALT + XF86AudioLowerVolume",
	cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),
	{ description = "volume down precise", locked = true, repeating = true }
)
bind(
	"XF86AudioMicMute",
	cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ description = "toggle mic mute", locked = true }
)
bind("XF86AudioMute", cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "toggle mute", locked = true })
bind("XF86AudioPlay", cmd("noctalia msg media toggle"), { description = "play/pause", locked = true })
bind("XF86AudioPause", cmd("noctalia msg media toggle"), { description = "pause", locked = true })
bind("XF86AudioNext", cmd("noctalia msg media next"), { description = "next track", locked = true })
bind("XF86AudioPrev", cmd("noctalia msg media previous"), { description = "previous track", locked = true })
bind("XF86AudioStop", cmd("noctalia msg media stop"), { description = "stop", locked = true })

-- ============================================
--  BRIGHTNESS
-- ============================================
bind("XF86MonBrightnessUp", cmd("noctalia msg brightness-up"), { description = "brightness up", locked = true })
bind("XF86MonBrightnessDown", cmd("noctalia msg brightness-down"), { description = "brightness down", locked = true })

-- ============================================
--  SYSTEM / POWER / SESSION
-- ============================================
bind("CTRL + ALT + Delete", cmd("noctalia msg panel-toggle session"), { description = "session menu" })
bind("CTRL + ALT + L", cmd("noctalia msg session lock"), { description = "lock screen" })
bind(
	"SUPER + SHIFT + N",
	cmd("noctalia msg panel-toggle control-center notification"),
	{ description = "notification sidebar" }
)
bind("XF86Sleep", cmd("systemctl suspend"), { description = "sleep", locked = true })

-- ============================================
--  APPEARANCE / THEMES
-- ============================================
bind("SUPER + T", cmd("noctalia msg settings-open theme"), { description = "Noctalia theme settings" })
bind("SUPER + SHIFT + A", function()
	Utils.animations()
end, { description = "animations menu" })
bind("SUPER + N", function()
	Utils.hyprsunset("toggle")
end, { description = "Toggle Hyprsunset - night light" })

-- ============================================
--  WALLPAPER
-- ============================================
bind("SUPER + W", cmd("noctalia msg panel-toggle wallpaper"), { description = "select wallpaper" })
bind(
	"SUPER + SHIFT + W",
	cmd("noctalia msg panel-toggle noctalia/wallhaven:browser"),
	{ description = "download wallpapers" }
)

-- ============================================
--  UTILITIES
-- ============================================
bind("SUPER + SHIFT + R", function()
	Utils.refresh()
end, { description = "refresh bar and menus" })
bind("SUPER + ALT + E", cmd('noctalia msg panel-toggle launcher "/emo "'), { description = "emoji menu" })
bind("SUPER + V", cmd("noctalia msg panel-toggle clipboard"), { description = "clipboard manager" })
bind("SUPER + SHIFT + E", function()
	Utils.quick_settings()
end, { description = "Quick settings menu" })

-- ============================================
--  MOUSE / ZOOM
-- ============================================
bind("SUPER + ALT + mouse_up", function()
	local current = hl.get_config("cursor.zoom_factor") or 1
	current = math.max(1, current * 2)
	hl.config({ cursor = { zoom_factor = current } })
end, { description = "zoom in", mouse = true })
bind("SUPER + ALT + mouse_down", function()
	local current = hl.get_config("cursor.zoom_factor") or 1
	current = math.max(1, current / 2)
	hl.config({ cursor = { zoom_factor = current } })
end, { description = "zoom out", mouse = true })
