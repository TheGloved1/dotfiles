local defaults = DEFAULTS
local term = defaults.term
local files = defaults.files

local bind = hl.bind
local exec = hl.dsp.exec_cmd
local layout = hl.dsp.layout
local focus = hl.dsp.focus
local window = hl.dsp.window
local workspace = hl.dsp.workspace
local group = hl.dsp.group

---@param name string
---@return string
local script = function(name)
	return SCRIPTS_DIR .. "/" .. name
end

-- ============================================
--  LAUNCHERS
-- ============================================
bind("SUPER + Return", exec(script("LaunchTerminal.sh") .. " " .. term), { description = "Open terminal" })
bind("SUPER + E", exec(script("LaunchFileManager.sh") .. " " .. files .. " " .. term), { description = "file manager" })
bind("SUPER + B", exec('xdg-open "https://"'), { description = "open default browser" })
bind("SUPER + SUPER_L", exec("noctalia msg panel-toggle launcher"), { description = "App launcher" })
bind("SUPER + SPACE", exec("noctalia msg panel-toggle control-center home"), { description = "App launcher" })
bind("SUPER + SHIFT + Return", exec(script("Dropterminal.sh kitty")), { description = "DropDown terminal" })
bind("SUPER + slash", exec(script("KeyHints.sh")), { description = "Help / cheat sheet" })
bind("SUPER + P", exec("hyprpicker -a -f hex --lowercase-hex"), { description = "Color picker" })
bind("ALT + SPACE", exec("vicinae toggle"), { description = "Toggle vicinae" })

-- ============================================
--  DESKTOP / OVERVIEW
-- ============================================
bind("SUPER + A", exec("noctalia msg window-switcher"), { description = "desktop overview" })
-- bind("SUPER + CTRL + S", exec("rofi -show window"), { description = "window switcher" })

-- ============================================
--  WINDOW MANAGEMENT
-- ============================================
bind("SUPER + Q", window.close(), { description = "close active window" })
bind("SUPER + SHIFT + Q", exec(script("KillActiveProcess.sh")), { description = "Terminate active process" })
bind("SUPER + F", window.fullscreen({ mode = "maximized" }), { description = "maximize window" })
bind("SUPER + SHIFT + F", window.fullscreen(), { description = "fullscreen" })
bind("SUPER + D", window.float({ action = "toggle" }), { description = "Toggle float" })
bind("SUPER + ALT + SPACE", exec(script("Float-all-Windows.sh")), { description = "Float all windows" })
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
bind("SUPER + H", exec(script("LayoutKeybindDispatch.sh focus-left")), { description = "Focus left" })
bind("SUPER + L", exec(script("LayoutKeybindDispatch.sh focus-right")), { description = "Focus right" })
bind("SUPER + J", exec(script("FocusWrap.sh d")), { description = "Focus down / next workspace" })
bind("SUPER + K", exec(script("FocusWrap.sh u")), { description = "Focus up / prev workspace" })
bind("SUPER + up", exec(script("LayoutKeybindDispatch.sh focus-up")), { description = "focus up (layout-aware)" })
bind("SUPER + down", exec(script("LayoutKeybindDispatch.sh focus-down")), { description = "focus down (layout-aware)" })
bind("ALT + Tab", window.cycle_next(), { description = "cycle next window" })
bind(
	"SUPER + bracketleft",
	exec(script("LayoutKeybindDispatch.sh cycle-next")),
	{ description = "Cycle next (layout-aware)" }
)
bind(
	"SUPER + bracketright",
	exec(script("LayoutKeybindDispatch.sh cycle-prev")),
	{ description = "Cycle previous (layout-aware)" }
)

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
bind("SUPER + SHIFT + H", window.swap({ direction = "left" }), { description = "Move window left" })
bind("SUPER + SHIFT + L", window.swap({ direction = "right" }), { description = "Move window right" })
bind("SUPER + SHIFT + K", exec(script("MoveWrap.sh u")), { description = "Move window up / prev workspace" })
bind("SUPER + SHIFT + J", exec(script("MoveWrap.sh d")), { description = "Move window down / next workspace" })
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
bind("SUPER + ALT + 1", exec(script("ChangeLayout.sh dwindle")), { description = "layout dwindle" })
bind("SUPER + ALT + 2", exec(script("ChangeLayout.sh master")), { description = "layout master" })
bind("SUPER + ALT + 3", exec(script("ChangeLayout.sh scrolling")), { description = "layout scrolling" })
bind("SUPER + ALT + 4", exec(script("ChangeLayout.sh monocle")), { description = "layout monocle" })
bind("SUPER + SHIFT + period", layout("move +col"), { description = "move to right column" })
bind("SUPER + SHIFT + comma", layout("move -col"), { description = "move to left column" })
bind("SUPER + ALT + comma", layout("swapcol l"), { description = "swap columns left" })
bind("SUPER + ALT + period", layout("swapcol r"), { description = "swap columns right" })

-- ============================================
--  WORKSPACES
-- ============================================
bind("SUPER + tab", focus({ workspace = "m+1" }), { description = "next workspace" })
bind("SUPER + SHIFT + tab", focus({ workspace = "m-1" }), { description = "previous workspace" })
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
--  SCREENSHOTS / RECORD (Caelestia)
-- ============================================
bind("SUPER + Print", exec("noctalia msg screenshot-fullscreen"), { description = "screenshot now" })
bind("SUPER + SHIFT + Print", exec("noctalia msg screenshot-region"), { description = "screenshot (area)" })
bind("SUPER + CTRL + Print", exec(script("ScreenShot.sh --in5")), { description = "screenshot in 5s" })
bind("SUPER + CTRL + SHIFT + Print", exec(script("ScreenShot.sh --in10")), { description = "screenshot in 10s" })
bind("ALT + Print", exec(script("ScreenShot.sh --active")), { description = "screenshot active window" })
bind("SUPER + SHIFT + S", exec(script("ScreenShot.sh --swappy")), { description = "screenshot (region)" })
bind("SUPER + S", exec(script("ScreenShotHistory.sh")), { description = "screenshot history" })
bind(
	"ALT + SHIFT + S",
	exec("noctalia msg screenshot-region"),
	{ description = "screenshot (freeze) [fallback to region]" }
)

-- ============================================
--  MEDIA / VOLUME (Caelestia OSD)
-- ============================================
bind(
	"XF86AudioRaiseVolume",
	exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ description = "volume up", locked = true, repeating = true }
)
bind(
	"XF86AudioLowerVolume",
	exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ description = "volume down", locked = true, repeating = true }
)
bind(
	"ALT + XF86AudioRaiseVolume",
	exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%+"),
	{ description = "volume up precise", locked = true, repeating = true }
)
bind(
	"ALT + XF86AudioLowerVolume",
	exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),
	{ description = "volume down precise", locked = true, repeating = true }
)
bind(
	"XF86AudioMicMute",
	exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ description = "toggle mic mute", locked = true }
)
bind(
	"XF86AudioMute",
	exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ description = "toggle mute", locked = true }
)
bind("XF86AudioPlay", exec("noctalia msg media toggle"), { description = "play/pause", locked = true })
bind("XF86AudioPause", exec("noctalia msg media toggle"), { description = "pause", locked = true })
bind("XF86AudioNext", exec("noctalia msg media next"), { description = "next track", locked = true })
bind("XF86AudioPrev", exec("noctalia msg media previous"), { description = "previous track", locked = true })
bind("XF86AudioStop", exec("noctalia msg media stop"), { description = "stop", locked = true })

-- ============================================
--  BRIGHTNESS (Caelestia OSD)
-- ============================================
bind("XF86MonBrightnessUp", exec("noctalia msg brightness-up"), { description = "brightness up", locked = true })
bind("XF86MonBrightnessDown", exec("noctalia msg brightness-down"), { description = "brightness down", locked = true })

-- ============================================
--  SYSTEM / POWER / SESSION
-- ============================================
bind("CTRL + ALT + Delete", exec("noctalia msg panel-toggle session"), { description = "session menu" })
bind("CTRL + ALT + L", exec("noctalia msg session lock"), { description = "lock screen" })
bind(
	"SUPER + SHIFT + N",
	exec("noctalia msg panel-toggle control-center notification"),
	{ description = "notification sidebar" }
)
bind("XF86Sleep", exec("systemctl suspend"), { description = "sleep", locked = true })

-- ============================================
--  APPEARANCE / THEMES
-- ============================================
bind("SUPER + T", exec("noctalia msg settings-open theme"), { description = "Noctalia theme settings" })
bind("SUPER + SHIFT + A", exec(script("Animations.sh")), { description = "animations menu" })
bind("SUPER + N", exec(script("Hyprsunset.sh toggle")), { description = "Toggle Hyprsunset - night light" })

-- ============================================
--  WALLPAPER
-- ============================================
bind("SUPER + W", exec("noctalia msg panel-toggle wallpaper"), { description = "select wallpaper" })

-- ============================================
--  UTILITIES
-- ============================================
bind("SUPER + SHIFT + R", exec(script("Refresh.sh")), { description = "refresh bar and menus" })
bind("SUPER + ALT + E", exec('noctalia msg panel-toggle launcher "/emo "'), { description = "emoji menu" })
bind("SUPER + V", exec("noctalia msg panel-toggle clipboard"), { description = "clipboard manager" })
bind("SUPER + SHIFT + E", exec(script("QuickSettings.sh")), { description = "Quick settings menu" })

-- ============================================
--  SCREEN RECORD
-- ============================================
bind(
	"CTRL + ALT + R",
	exec("noctalia msg plugin noctalia/screen_recorder:service all start"),
	{ description = "record screen" }
)
bind(
	"SUPER + ALT + R",
	exec("noctalia msg plugin noctalia/screen_recorder:service all start"),
	{ description = "record screen with sound" }
)
bind(
	"SUPER + SHIFT + ALT + R",
	exec("noctalia msg plugin noctalia/screen_recorder:service all start region"),
	{ description = "record region" }
)

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
