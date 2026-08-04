local scriptsDir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/scripts"

local defaults = rawget(_G, "KOOLDOTS_DEFAULTS") or {}
local term = defaults.term or os.getenv("TERMINAL") or "kitty"
local files = defaults.files or "pcmanfm-qt"

local E = hl.dsp.exec_cmd
local W = hl.dsp.window
local WS = hl.dsp.workspace
local F = hl.dsp.focus

local script = function(name)
	return scriptsDir .. "/" .. name
end

-- Converted from configs/Keybinds.conf
hl.bind("SUPER + B", E('xdg-open "https://"'), { description = "open default browser" })
hl.bind("SUPER + A", E(script("OverviewToggle.sh")), { description = "desktop overview" })
hl.bind("SUPER + Return", E(script("LaunchTerminal.sh") .. " " .. term), { description = "Open terminal" })
hl.bind("SUPER + E", E(script("LaunchFileManager.sh") .. " " .. files .. " " .. term), { description = "file manager" })
hl.bind("SUPER + C", E(script("rofi-ssh-menu.sh")), { description = "SSH session manager" })
hl.bind("SUPER + T", E(script("ThemeChanger.sh")), { description = "Global theme switcher using Wallust" })
hl.bind("SUPER + ALT + R", E(script("Refresh.sh")), { description = "refresh bar and menus" })
hl.bind("SUPER + ALT + E", E(script("RofiEmoji.sh")), { description = "emoji menu" })
hl.bind("SUPER + S", E(script("RofiSearch.sh")), { description = "web search" })
hl.bind("SUPER + CTRL + S", E("rofi -show window"), { description = "window switcher" })
hl.bind("SUPER + ALT + O", E(script("ChangeBlur.sh")), { description = "toggle blur" })
hl.bind("SUPER + SHIFT + G", E(script("GameMode.sh")), { description = "toggle game mode" })
hl.bind("SUPER + ALT + L", E(script("ChangeLayout.sh toggle")), { description = "toggle layouts" })
hl.bind("SUPER + ALT + V", E(script("ClipManager.sh")), { description = "clipboard manager" })
hl.bind("SUPER + CTRL + R", E(script("RofiThemeSelector.sh")), { description = "rofi theme selector" })
hl.bind(
	"SUPER + CTRL + SHIFT + R",
	E("pkill rofi || true && " .. script("RofiThemeSelector-modified.sh")),
	{ description = "rofi theme selector (modified)" }
)
hl.bind("SUPER + CTRL + K", E(script("Kitty_themes.sh")), { description = "Kitty theme selector" })
hl.bind(
	"SUPER + SHIFT + B",
	E(script("RainbowBorders-low-cpu.sh  --run-once")),
	{ description = "Set static Rainbow Border" }
)
hl.bind(
	"ALT + SHIFT + S",
	E(script("hyprshot.sh -m region -o $HOME/Pictures/Screenshots")),
	{ description = "Hyprshot Screen Capture" }
)
hl.bind("SUPER + SHIFT + F", W.fullscreen(), { description = "fullscreen" })
hl.bind("SUPER + F", W.fullscreen({ mode = "maximized" }), { description = "maximize window" })
hl.bind("SUPER + ALT + SPACE", E(script("Float-all-Windows.sh")), { description = "Float all windows" })
hl.bind("SUPER + SHIFT + Return", E(script("Dropterminal.sh kitty")), { description = "DropDown terminal" })
hl.bind(
	"SUPER + ALT + mouse_down",
	E(
		"hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')\""
	),
	{ description = "zoom in" }
)
hl.bind(
	"SUPER + ALT + mouse_up",
	E(
		"hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')\""
	),
	{ description = "zoom out" }
)
hl.bind("SUPER + CTRL + ALT + B", E("pkill -SIGUSR1 waybar"), { description = "toggle waybar on/off" })
hl.bind("SUPER + CTRL + B", E(script("WaybarStyles.sh")), { description = "waybar styles menu" })
hl.bind("SUPER + ALT + B", E(script("WaybarLayout.sh")), { description = "waybar layout menu" })
hl.bind("SUPER + N", E(script("Hyprsunset.sh toggle")), { description = "Toggle Hyprsunset - night light" })
hl.bind("SUPER + SHIFT + M", E(script("RofiBeats.sh")), { description = "online music" })
hl.bind("SUPER + W", E(script("WallpaperSelect.sh")), { description = "select wallpaper" })
hl.bind("SUPER + SHIFT + W", E(script("WallpaperEffects.sh")), { description = "wallpaper effects" })
hl.bind("CTRL + ALT + W", E(script("WallpaperRandom.sh")), { description = "random wallpaper" })
hl.bind(
	"SUPER + CTRL + O",
	W.set_prop({ prop = "opaque", value = "toggle" }),
	{ description = "toggle active window opacity" }
)
hl.bind("SUPER + SHIFT + A", E(script("Animations.sh")), { description = "animations menu" })
hl.bind("SUPER + SHIFT + R", E(script("ZshChangeTheme.sh")), { description = "change oh-my-zsh theme" })
hl.bind(
	"ALT_L + SHIFT_L",
	E(script("KeyboardLayout.sh switch")),
	{ description = "switch keyboard layout globally", locked = true }
)
hl.bind(
	"SHIFT_L + ALT_L",
	E(script("Tak0-Per-Window-Switch.sh")),
	{ description = "switch keyboard layout per-window", locked = true }
)
hl.bind("SUPER + ALT + C", E(script("RofiCalc.sh")), { description = "calculator" })
hl.bind(
	"SUPER + CTRL + F9",
	E("hyprctl dispatch movecurrentworkspacetomonitor left"),
	{ description = "move workspace to left monitor" }
)
hl.bind(
	"SUPER + CTRL + F10",
	E("hyprctl dispatch movecurrentworkspacetomonitor right"),
	{ description = "move workspace to right monitor" }
)
hl.bind(
	"SUPER + CTRL + F11",
	E("hyprctl dispatch movecurrentworkspacetomonitor up"),
	{ description = "move workspace to up monitor" }
)
hl.bind(
	"SUPER + CTRL + F12",
	E("hyprctl dispatch movecurrentworkspacetomonitor down"),
	{ description = "move workspace to down monitor" }
)
hl.bind("CTRL + ALT + Delete", E(script("Logout.sh")), { description = "exit Hyprland" })
hl.bind("SUPER + Q", W.close(), { description = "close active window" })
hl.bind("SUPER + SHIFT + Q", E(script("KillActiveProcess.sh")), { description = "Terminate active process" })
hl.bind("CTRL + ALT + L", E(script("LockScreen.sh")), { description = "lock screen" })
hl.bind("CTRL + ALT + P", E(script("Wlogout.sh")), { description = "powermenu" })
hl.bind("SUPER + SHIFT + N", E("swaync-client -t -sw"), { description = "notification panel" })
hl.bind("SUPER + SHIFT + E", E(script("Kool_Quick_Settings.sh")), { description = "Quick settings menu" })
hl.bind("SUPER + CTRL + D", hl.dsp.layout("removemaster"), { description = "remove master" })
hl.bind("SUPER + I", hl.dsp.layout("addmaster"), { description = "add master" })
hl.bind("SUPER + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "swap with master" })
hl.bind("SUPER + SHIFT + I", hl.dsp.layout("togglesplit"), { description = "toggle split (dwindle)" })
hl.bind("SUPER + M", E("hyprctl dispatch splitratio 0.3"), { description = "set split ratio 0.3" })
hl.bind("SUPER + ALT + 1", E(script("ChangeLayout.sh dwindle")), { description = "layout dwindle" })
hl.bind("SUPER + ALT + 2", E(script("ChangeLayout.sh master")), { description = "layout master" })
hl.bind("SUPER + ALT + 3", E(script("ChangeLayout.sh scrolling")), { description = "layout scrolling" })
hl.bind("SUPER + ALT + 4", E(script("ChangeLayout.sh monocle")), { description = "layout monocle" })
hl.bind("SUPER + SHIFT + period", hl.dsp.layout("move +col"), { description = "move to right column" })
hl.bind("SUPER + SHIFT + comma", hl.dsp.layout("move -col"), { description = "move to left column" })
hl.bind("SUPER + ALT + comma", hl.dsp.layout("swapcol l"), { description = "swap columns left" })
hl.bind("SUPER + ALT + period", hl.dsp.layout("swapcol r"), { description = "swap columns right" })
hl.bind("SUPER + ALT + H", E("hyprctl keyword scrolling:direction right"), { description = "Horizonal scroll right" })
hl.bind(
	"SUPER + ALT + S",
	E(
		'bash -c \'[[ $(hyprctl getoption scrolling:direction -j | jq -r ".str") == "right" ]] && hyprctl keyword scrolling:direction down || hyprctl keyword scrolling:direction right\''
	),
	{ description = "toggle scrolling V/H" }
)
hl.bind("ALT + Tab", W.cycle_next(), { description = "cycle next window" })
hl.bind(
	"XF86AudioRaiseVolume",
	E(script("Volume.sh --inc")),
	{ description = "volume up", locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	E(script("Volume.sh --dec")),
	{ description = "volume down", locked = true, repeating = true }
)
hl.bind(
	"ALT + XF86AudioRaiseVolume",
	E(script("Volume.sh --inc-precise")),
	{ description = "volume up precise", locked = true, repeating = true }
)
hl.bind(
	"ALT + XF86AudioLowerVolume",
	E(script("Volume.sh --dec-precise")),
	{ description = "volume down precise", locked = true, repeating = true }
)
hl.bind("XF86AudioMicMute", E(script("Volume.sh --toggle-mic")), { description = "toggle mic mute", locked = true })
hl.bind("XF86AudioMute", E(script("Volume.sh --toggle")), { description = "toggle mute", locked = true })
hl.bind("XF86Sleep", E("systemctl suspend"), { description = "sleep", locked = true })
hl.bind("XF86Rfkill", E(script("AirplaneMode.sh")), { description = "airplane mode", locked = true })
hl.bind("XF86AudioPlay", E(script("MediaCtrl.sh --pause")), { description = "play/pause", locked = true })
hl.bind("XF86AudioPause", E(script("MediaCtrl.sh --pause")), { description = "pause", locked = true })
hl.bind("XF86AudioNext", E(script("MediaCtrl.sh --nxt")), { description = "next track", locked = true })
hl.bind("XF86AudioPrev", E(script("MediaCtrl.sh --prv")), { description = "previous track", locked = true })
hl.bind("XF86AudioStop", E(script("MediaCtrl.sh --stop")), { description = "stop", locked = true })
hl.bind("SUPER + Print", E(script("ScreenShot.sh --now")), { description = "screenshot now" })
hl.bind("SUPER + SHIFT + Print", E(script("ScreenShot.sh --area")), { description = "screenshot (area)" })
hl.bind("SUPER + CTRL + Print", E(script("ScreenShot.sh --in5")), { description = "screenshot in 5s" })
hl.bind("SUPER + CTRL + SHIFT + Print", E(script("ScreenShot.sh --in10")), { description = "screenshot in 10s" })
hl.bind("ALT + Print", E(script("ScreenShot.sh --active")), { description = "screenshot active window" })
hl.bind("SUPER + SHIFT + S", E(script("ScreenShot.sh --swappy")), { description = "screenshot (swappy)" })
hl.bind(
	"SUPER + SHIFT + left",
	W.resize({ x = -50, y = 0, relative = true }),
	{ description = "resize left (-50)", repeating = true }
)
hl.bind(
	"SUPER + SHIFT + right",
	W.resize({ x = 50, y = 0, relative = true }),
	{ description = "resize right (+50)", repeating = true }
)
hl.bind(
	"SUPER + SHIFT + up",
	W.resize({ x = 0, y = -50, relative = true }),
	{ description = "resize up (-50)", repeating = true }
)
hl.bind(
	"SUPER + SHIFT + down",
	W.resize({ x = 0, y = 50, relative = true }),
	{ description = "resize down (+50)", repeating = true }
)
hl.bind("SUPER + CTRL + left", W.move({ direction = "left" }), { description = "move window left" })
hl.bind("SUPER + CTRL + right", W.move({ direction = "right" }), { description = "move window right" })
hl.bind("SUPER + CTRL + up", W.move({ direction = "up" }), { description = "move window up" })
hl.bind("SUPER + CTRL + down", W.move({ direction = "down" }), { description = "move window down" })
hl.bind("SUPER + ALT + left", W.swap({ direction = "left" }), { description = "swap window left" })
hl.bind("SUPER + ALT + right", W.swap({ direction = "right" }), { description = "swap window right" })
hl.bind("SUPER + ALT + up", W.swap({ direction = "up" }), { description = "swap window up" })
hl.bind("SUPER + ALT + down", W.swap({ direction = "down" }), { description = "swap window down" })
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "toggle group" })
hl.bind(
	"SUPER + CTRL + L",
	hl.dsp.group.move_window({ direction = "right" }),
	{ description = "Move Right into group" }
)
hl.bind(
	"SUPER + CTRL + H",
	hl.dsp.group.move_window({ direction = "out" }),
	{ description = "Move active out of group" }
)
hl.bind("SUPER + up", E(script("LayoutKeybindDispatch.sh focus-up")), { description = "focus up (layout-aware)" })
hl.bind("SUPER + down", E(script("LayoutKeybindDispatch.sh focus-down")), { description = "focus down (layout-aware)" })
hl.bind("SUPER + tab", F({ workspace = "m+1" }), { description = "next workspace" })
hl.bind("SUPER + SHIFT + tab", F({ workspace = "m-1" }), { description = "previous workspace" })
hl.bind("SUPER + SHIFT + U", W.move({ workspace = "special" }), { description = "move to special workspace" })
hl.bind("SUPER + U", WS.toggle_special(), { description = "toggle special workspace" })
hl.bind("SUPER + 1", F({ workspace = 1 }), { description = "workspace 1" })
hl.bind("SUPER + 2", F({ workspace = 2 }), { description = "workspace 2" })
hl.bind("SUPER + 3", F({ workspace = 3 }), { description = "workspace 3" })
hl.bind("SUPER + 4", F({ workspace = 4 }), { description = "workspace 4" })
hl.bind("SUPER + 5", F({ workspace = 5 }), { description = "workspace 5" })
hl.bind("SUPER + 6", F({ workspace = 6 }), { description = "workspace 6" })
hl.bind("SUPER + 7", F({ workspace = 7 }), { description = "workspace 7" })
hl.bind("SUPER + 8", F({ workspace = 8 }), { description = "workspace 8" })
hl.bind("SUPER + 9", F({ workspace = 9 }), { description = "workspace 9" })
hl.bind("SUPER + 0", F({ workspace = 10 }), { description = "workspace 10" })
hl.bind("SUPER + SHIFT + 1", W.move({ workspace = 1 }), { description = "move to workspace 1" })
hl.bind("SUPER + SHIFT + 2", W.move({ workspace = 2 }), { description = "move to workspace 2" })
hl.bind("SUPER + SHIFT + 3", W.move({ workspace = 3 }), { description = "move to workspace 3" })
hl.bind("SUPER + SHIFT + 4", W.move({ workspace = 4 }), { description = "move to workspace 4" })
hl.bind("SUPER + SHIFT + 5", W.move({ workspace = 5 }), { description = "move to workspace 5" })
hl.bind("SUPER + SHIFT + 6", W.move({ workspace = 6 }), { description = "move to workspace 6" })
hl.bind("SUPER + SHIFT + 7", W.move({ workspace = 7 }), { description = "move to workspace 7" })
hl.bind("SUPER + SHIFT + 8", W.move({ workspace = 8 }), { description = "move to workspace 8" })
hl.bind("SUPER + SHIFT + 9", W.move({ workspace = 9 }), { description = "move to workspace 9" })
hl.bind("SUPER + SHIFT + 0", W.move({ workspace = 10 }), { description = "move to workspace 10" })
hl.bind("SUPER + mouse_down", F({ workspace = "e+1" }), { description = "next workspace" })
hl.bind("SUPER + mouse_up", F({ workspace = "e-1" }), { description = "previous workspace" })
hl.bind("SUPER + period", F({ workspace = "e+1" }), { description = "next workspace" })
hl.bind("SUPER + comma", F({ workspace = "e-1" }), { description = "previous workspace" })
hl.bind("SUPER + mouse:272", W.drag(), { description = "move window", mouse = true })
hl.bind("SUPER + mouse:273", W.resize(), { description = "resize window", mouse = true })
hl.bind("ALT + SPACE", E("vicinae toggle"), { description = "Toggle vicinae" })
hl.bind("SUPER + SHIFT + H", E(script("MoveWrap.sh l")), { description = "Move window left" })
hl.bind("SUPER + SHIFT + L", E(script("MoveWrap.sh r")), { description = "Move window right" })
hl.bind("SUPER + SHIFT + K", E(script("MoveWrap.sh u")), { description = "Move window up / prev workspace" })
hl.bind("SUPER + SHIFT + J", E(script("MoveWrap.sh d")), { description = "Move window down / next workspace" })
hl.bind("SUPER + CTRL + A", E(script("OverviewToggle.sh")), { description = "Desktop overview" })
hl.bind(
	"SUPER + CTRL + F",
	hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }),
	{ description = "Toggle maximize" }
)
hl.bind("SUPER + D", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle float" })
hl.bind(
	"SUPER + SPACE",
	E(
		"pkill rofi || true; "
			.. script("RofiFocusedWallpaperLink.sh")
			.. " >/dev/null 2>&1 || true; rofi -show drun -modi drun,filebrowser,run,window"
	),
	{ description = "App launcher" }
)
hl.bind("SUPER + H", E(script("LayoutKeybindDispatch.sh focus-left")), { description = "Focus left" })
hl.bind("SUPER + J", E(script("FocusWrap.sh d")), { description = "Focus down / next workspace" })
hl.bind("SUPER + K", E(script("FocusWrap.sh u")), { description = "Focus up / prev workspace" })
hl.bind("SUPER + L", E(script("LayoutKeybindDispatch.sh focus-right")), { description = "Focus right" })
hl.bind("SUPER + slash", E(script("KeyHints.sh")), { description = "Help / cheat sheet" })
hl.bind(
	"SUPER + bracketleft",
	E(script("LayoutKeybindDispatch.sh cycle-next")),
	{ description = "Cycle next (layout-aware)" }
)
hl.bind(
	"SUPER + bracketright",
	E(script("LayoutKeybindDispatch.sh cycle-prev")),
	{ description = "Cycle previous (layout-aware)" }
)

hl.bind("SUPER + P", E("hyprpicker -a -f hex --lowercase-hex"), { description = "Color picker" })
