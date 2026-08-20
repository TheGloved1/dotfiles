local defaults = DEFAULTS
local term = defaults.term
local files = defaults.files

-- ============================================
--  LAUNCHERS
-- ============================================
hl.bind("SUPER + Return", function()
	Utils.launch_terminal(term)
end, { description = "Open terminal" })
hl.bind("SUPER + E", function()
	Utils.launch_file_manager(files, term)
end, { description = "file manager" })
hl.bind("SUPER + B", hl.dsp.exec_cmd('xdg-open "https://"'), { description = "open default browser" })
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { description = "App launcher" })
hl.bind(
	"SUPER + SPACE",
	hl.dsp.exec_cmd("noctalia msg panel-toggle control-center home"),
	{ description = "App launcher" }
)
-- bind("SUPER + SHIFT + Return", function() Utils.dropterminal("toggle", "kitty") end, { description = "DropDown terminal" })
hl.bind(
	"SUPER + slash",
	hl.dsp.exec_cmd("noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
	{ description = "Help / cheat sheet" }
)
hl.bind(
	"SUPER + SHIFT + slash",
	hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all toggle"),
	{ description = "Noctalia Screen Toolkit" }
)
hl.bind("SUPER + P", hl.dsp.exec_cmd("hyprpicker -a -f hex --lowercase-hex"), { description = "Color picker" })
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("vicinae toggle"), { description = "Toggle vicinae" })

-- ============================================
--  DESKTOP / OVERVIEW
-- ============================================
hl.bind("SUPER + A", hl.dsp.exec_cmd("noctalia msg window-switcher"), { description = "desktop overview" })
-- bind("SUPER + CTRL + S", exec("rofi -show window"), { description = "window switcher" })
if hl.plugin.scrolloverview then
	hl.bind("SUPER + tab", function()
		hl.plugin.scrolloverview.overview("toggle all")
	end, { description = "overview" })
end

-- ============================================
--  WINDOW MANAGEMENT
-- ============================================
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "close active window" })
hl.bind("SUPER + SHIFT + Q", function()
	Utils.kill_active_process()
end, { description = "Terminate active process" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "maximize window" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen(), { description = "fullscreen" })
hl.bind("SUPER + D", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle float" })
hl.bind("SUPER + ALT + SPACE", function()
	Utils.float_all_windows()
end, { description = "Float all windows" })
hl.bind(
	"SUPER + CTRL + O",
	hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }),
	{ description = "toggle active window opacity" }
)
local blur_opaque_rule = hl.window_rule({
	name = "blur-toggle-opaque",
	match = { class = ".*" },
	opaque = true,
})
blur_opaque_rule:set_enabled(false)
hl.bind("SUPER + ALT + O", function()
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
hl.bind("SUPER + H", function()
	Utils.layout_keybind_dispatch("focus-left")
end, { description = "Focus left", repeating = true })
hl.bind("SUPER + L", function()
	Utils.layout_keybind_dispatch("focus-right")
end, { description = "Focus right", repeating = true })
hl.bind("SUPER + J", function()
	Utils.focus_wrap("d")
end, { description = "Focus down / next workspace", repeating = true })
hl.bind("SUPER + K", function()
	Utils.focus_wrap("u")
end, { description = "Focus up / prev workspace", repeating = true })
hl.bind("SUPER + up", function()
	Utils.layout_keybind_dispatch("focus-up")
end, { description = "focus up (layout-aware)" })
hl.bind("SUPER + down", function()
	Utils.layout_keybind_dispatch("focus-down")
end, { description = "focus down (layout-aware)" })
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "cycle next window" })
hl.bind("SUPER + bracketleft", function()
	Utils.layout_keybind_dispatch("cycle-next")
end, { description = "Cycle next (layout-aware)" })
hl.bind("SUPER + bracketright", function()
	Utils.layout_keybind_dispatch("cycle-prev")
end, { description = "Cycle previous (layout-aware)" })

-- ============================================
--  MOVE / SWAP / RESIZE
-- ============================================
hl.bind("SUPER + ALT + H", hl.dsp.window.move({ direction = "left" }), { description = "move window left" })
hl.bind("SUPER + ALT + L", hl.dsp.window.move({ direction = "right" }), { description = "move window right" })
hl.bind("SUPER + ALT + K", hl.dsp.window.move({ direction = "up" }), { description = "move window up" })
hl.bind("SUPER + ALT + J", hl.dsp.window.move({ direction = "down" }), { description = "move window down" })
hl.bind("SUPER + ALT + left", hl.dsp.window.swap({ direction = "left" }), { description = "swap window left" })
hl.bind("SUPER + ALT + right", hl.dsp.window.swap({ direction = "right" }), { description = "swap window right" })
hl.bind("SUPER + ALT + up", hl.dsp.window.swap({ direction = "up" }), { description = "swap window up" })
hl.bind("SUPER + ALT + down", hl.dsp.window.swap({ direction = "down" }), { description = "swap window down" })
hl.bind("SUPER + SHIFT + H", function()
	Utils.move_wrap("l")
end, { description = "Move window left", repeating = true })
hl.bind("SUPER + SHIFT + L", function()
	Utils.move_wrap("r")
end, { description = "Move window right", repeating = true })
hl.bind("SUPER + SHIFT + K", function()
	Utils.move_wrap("u")
end, { description = "Move window up / prev workspace", repeating = true })
hl.bind("SUPER + SHIFT + J", function()
	Utils.move_wrap("d")
end, { description = "Move window down / next workspace", repeating = true })
hl.bind(
	"SUPER + CTRL + H",
	hl.dsp.window.resize({ x = -50, y = 0, relative = true }),
	{ description = "resize left (-50)", repeating = true }
)
hl.bind(
	"SUPER + CTRL + L",
	hl.dsp.window.resize({ x = 50, y = 0, relative = true }),
	{ description = "resize right (+50)", repeating = true }
)
hl.bind(
	"SUPER + CTRL + K",
	hl.dsp.window.resize({ x = 0, y = -50, relative = true }),
	{ description = "resize up (-50)", repeating = true }
)
hl.bind(
	"SUPER + CTRL + J",
	hl.dsp.window.resize({ x = 0, y = 50, relative = true }),
	{ description = "resize down (+50)", repeating = true }
)
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { description = "move window", mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { description = "resize window", mouse = true })

-- ============================================
--  LAYOUT
-- ============================================
hl.bind("SUPER + I", hl.dsp.layout("addmaster"), { description = "add master" })
hl.bind("SUPER + CTRL + D", hl.dsp.layout("removemaster"), { description = "remove master" })
hl.bind("SUPER + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "swap with master" })
hl.bind("SUPER + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "toggle split (dwindle)" })
hl.bind("SUPER + ALT + 1", function()
	Utils.change_layout("dwindle")
end, { description = "layout dwindle" })
hl.bind("SUPER + ALT + 2", function()
	Utils.change_layout("master")
end, { description = "layout master" })
hl.bind("SUPER + ALT + 3", function()
	Utils.change_layout("scrolling")
end, { description = "layout scrolling" })
hl.bind("SUPER + ALT + 4", function()
	Utils.change_layout("monocle")
end, { description = "layout monocle" })
hl.bind("SUPER + SHIFT + period", hl.dsp.layout("move +col"), { description = "move to right column" })
hl.bind("SUPER + SHIFT + comma", hl.dsp.layout("move -col"), { description = "move to left column" })
hl.bind("SUPER + ALT + comma", hl.dsp.layout("swapcol l"), { description = "swap columns left" })
hl.bind("SUPER + ALT + period", hl.dsp.layout("swapcol r"), { description = "swap columns right" })

-- ============================================
--  WORKSPACES
-- ============================================
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })
hl.bind("SUPER + U", hl.dsp.workspace.toggle_special(), { description = "toggle special workspace" })
hl.bind(
	"SUPER + SHIFT + U",
	hl.dsp.window.move({ workspace = "special" }),
	{ description = "move to special workspace" }
)
for i = 1, 10 do
	local key = i == 10 and 0 or i
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), { description = "workspace " .. i })
	hl.bind(
		"SUPER + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "move to workspace " .. i }
	)
end

-- ============================================
--  GROUPS
-- ============================================
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "toggle group" })

-- ============================================
--  SCREENSHOTS / RECORD
-- ============================================
hl.bind("SUPER + CTRL + S", function()
	local w = hl.get_active_window()
	if not w then
		Utils.notify("Screenshare Block", "No active window", { urgency = "low" })
		return
	end
	local tags = w.tags
	local has_tag = false
	if type(tags) == "string" then
		has_tag = tags:find("screenshare-block") ~= nil
	elseif type(tags) == "table" then
		for _, t in ipairs(tags) do
			if t == "screenshare-block" then
				has_tag = true
				break
			end
		end
	end
	hl.dispatch(hl.dsp.window.tag({ tag = "screenshare-block" }))
	if has_tag then
		Utils.notify("Screensharing Enabled", "Re-enabled for " .. w.initial_title, {
			urgency = "low",
			replace = "screenshare-block-" .. w.initial_class,
		})
	else
		Utils.notify("Screensharing Disabled", "Disabled for " .. w.initial_title, {
			urgency = "low",
			replace = "screenshare-block-" .. w.initial_class,
		})
	end
end, { description = "toggle screen share for active window" })

hl.bind(
	"SUPER + Print",
	hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"),
	{ description = "screenshot fullscreen" }
)
hl.bind(
	"SUPER + SHIFT + Print",
	hl.dsp.exec_cmd("noctalia msg screenshot-region"),
	{ description = "screenshot region" }
)
hl.bind(
	"SUPER + CTRL + Print",
	hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen pick"),
	{ description = "screenshot pick monitor" }
)
hl.bind(
	"SUPER + CTRL + SHIFT + Print",
	hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen all"),
	{ description = "screenshot all monitors" }
)
hl.bind(
	"ALT + Print",
	hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen monitor"),
	{ description = "screenshot active monitor" }
)
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd("noctalia msg plugin gloves/screenshot-actions:service all capture"),
	{ description = "screenshot region → menu (Swappy/OCR)" }
)
hl.bind(
	"SUPER + S",
	hl.dsp.exec_cmd("noctalia msg panel-toggle gloves/screenshot-actions:history"),
	{ description = "Screenshot history" }
)
hl.bind(
	"SUPER + ALT + S",
	hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all toggle"),
	{ description = "screen toolkit panel" }
)
hl.bind(
	"SUPER + SHIFT + O",
	hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all ocr"),
	{ description = "screenshot region → OCR" }
)
hl.bind(
	"SUPER + SHIFT + C",
	hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all colorPicker"),
	{ description = "pick color from screen" }
)
hl.bind(
	"ALT + SHIFT + S",
	hl.dsp.exec_cmd("noctalia msg panel-toggle alexander/screen-toolkit:panel-legacy"),
	{ description = "screen toolkit panel (legacy)" }
)
hl.bind(
	"CTRL + ALT + R",
	hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all start"),
	{ description = "record screen (region)" }
)
hl.bind(
	"SUPER + ALT + R",
	hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all start-fullscreen"),
	{ description = "record screen (fullscreen)" }
)
hl.bind(
	"SUPER + SHIFT + ALT + R",
	hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all stop"),
	{ description = "stop screen recording" }
)
hl.bind(
	"SUPER + SHIFT + CTRL + R",
	hl.dsp.exec_cmd("noctalia msg plugin noctalia/screen_recorder:service all replay-start"),
	{ description = "Start replay buffer / Save replay" }
)

-- ============================================
--  MEDIA / VOLUME
-- ============================================
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ description = "volume up", locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ description = "volume down", locked = true, repeating = true }
)
hl.bind(
	"ALT + XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%+"),
	{ description = "volume up precise", locked = true, repeating = true }
)
hl.bind(
	"ALT + XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),
	{ description = "volume down precise", locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ description = "toggle mic mute", locked = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ description = "toggle mute", locked = true }
)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("noctalia msg media toggle"), { description = "play/pause", locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("noctalia msg media toggle"), { description = "pause", locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("noctalia msg media next"), { description = "next track", locked = true })
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("noctalia msg media previous"),
	{ description = "previous track", locked = true }
)
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("noctalia msg media stop"), { description = "stop", locked = true })

-- ============================================
--  BRIGHTNESS
-- ============================================
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("noctalia msg brightness-up"),
	{ description = "brightness up", locked = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("noctalia msg brightness-down"),
	{ description = "brightness down", locked = true }
)

-- ============================================
--  SYSTEM / POWER / SESSION
-- ============================================
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { description = "session menu" })
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock"), { description = "lock screen" })
hl.bind(
	"SUPER + SHIFT + N",
	hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notification"),
	{ description = "notification sidebar" }
)
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { description = "sleep", locked = true })

-- ============================================
--  APPEARANCE / THEMES
-- ============================================
hl.bind("SUPER + T", hl.dsp.exec_cmd("noctalia msg settings-open theme"), { description = "Noctalia theme settings" })
hl.bind("SUPER + SHIFT + A", function()
	Utils.animations()
end, { description = "animations menu" })
hl.bind("SUPER + N", function()
	Utils.hyprsunset("toggle")
end, { description = "Toggle Hyprsunset - night light" })

-- ============================================
--  WALLPAPER
-- ============================================
hl.bind("SUPER + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"), { description = "select wallpaper" })
hl.bind(
	"SUPER + SHIFT + W",
	hl.dsp.exec_cmd("noctalia msg panel-toggle noctalia/wallhaven:browser"),
	{ description = "download wallpapers" }
)

-- ============================================
--  UTILITIES
-- ============================================
hl.bind("SUPER + SHIFT + R", function()
	Utils.refresh()
end, { description = "refresh bar and menus" })
hl.bind(
	"SUPER + ALT + E",
	hl.dsp.exec_cmd('noctalia msg panel-toggle launcher "/emo "'),
	{ description = "emoji menu" }
)
hl.bind("SUPER + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"), { description = "clipboard manager" })
hl.bind("SUPER + SHIFT + E", function()
	Utils.quick_settings()
end, { description = "Quick settings menu" })

-- ============================================
--  MOUSE / ZOOM
-- ============================================
hl.bind("SUPER + ALT + mouse_up", function()
	local current = hl.get_config("cursor.zoom_factor") or 1
	current = math.max(1, current * 2)
	hl.config({ cursor = { zoom_factor = current } })
end, { description = "zoom in", mouse = true })
hl.bind("SUPER + ALT + mouse_down", function()
	local current = hl.get_config("cursor.zoom_factor") or 1
	current = math.max(1, current / 2)
	hl.config({ cursor = { zoom_factor = current } })
end, { description = "zoom out", mouse = true })
