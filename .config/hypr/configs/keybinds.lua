local helper = dofile(os.getenv("HOME") .. "/.config/hypr/lua/user_keybinds_helper.lua")
local exec_cmd = helper.exec_cmd
local bind = helper.bind
local unbind = helper.unbind
local dispatch = helper.dispatch

local scriptsDir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/scripts"

local defaults = rawget(_G, "KOOLDOTS_DEFAULTS") or {}
local term = defaults.term or os.getenv("TERMINAL") or "kitty"
local files = defaults.files or "pcmanfm-qt"

-- Converted from configs/Keybinds.conf
bind(
	"SUPER",
	"D",
	exec_cmd("pkill rofi || true && rofi -show drun -modi drun, filebrowser, run, window"),
	{ description = "app launcher" }
)
bind("SUPER", "B", exec_cmd('xdg-open "https://"'), { description = "open default browser" })
bind("SUPER", "A", exec_cmd("$HOME/.config/hypr/scripts/OverviewToggle.sh"), { description = "desktop overview" })
bind(
	"SUPER",
	"Return",
	exec_cmd("$HOME/.config/hypr/scripts/LaunchTerminal.sh " .. term),
	{ description = "Open terminal" }
)
bind(
	"SUPER",
	"E",
	exec_cmd("$HOME/.config/hypr/scripts/LaunchFileManager.sh " .. files .. " " .. term),
	{ description = "file manager" }
)
bind("SUPER", "C", exec_cmd("$HOME/.config/hypr/scripts/rofi-ssh-menu.sh"), { description = "SSH session manager" })
bind(
	"SUPER",
	"T",
	exec_cmd("$HOME/.config/hypr/scripts/ThemeChanger.sh"),
	{ description = "Global theme switcher using Wallust" }
)
bind("SUPER", "H", exec_cmd("$HOME/.config/hypr/scripts/KeyHints.sh"), { description = "help / cheat sheet" })
bind("SUPER ALT", "R", exec_cmd("$HOME/.config/hypr/scripts/Refresh.sh"), { description = "refresh bar and menus" })
bind("SUPER ALT", "E", exec_cmd("$HOME/.config/hypr/scripts/RofiEmoji.sh"), { description = "emoji menu" })
bind("SUPER", "S", exec_cmd("$HOME/.config/hypr/scripts/RofiSearch.sh"), { description = "web search" })
bind("SUPER CTRL", "S", exec_cmd("rofi -show window"), { description = "window switcher" })
bind("SUPER ALT", "O", exec_cmd("$HOME/.config/hypr/scripts/ChangeBlur.sh"), { description = "toggle blur" })
bind("SUPER SHIFT", "G", exec_cmd("$HOME/.config/hypr/scripts/GameMode.sh"), { description = "toggle game mode" })
bind(
	"SUPER ALT",
	"L",
	exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh toggle"),
	{ description = "toggle layouts" }
)
bind("SUPER ALT", "V", exec_cmd("$HOME/.config/hypr/scripts/ClipManager.sh"), { description = "clipboard manager" })
bind(
	"SUPER CTRL",
	"R",
	exec_cmd("$HOME/.config/hypr/scripts/RofiThemeSelector.sh"),
	{ description = "rofi theme selector" }
)
bind(
	"SUPER CTRL SHIFT",
	"R",
	exec_cmd("pkill rofi || true && $HOME/.config/hypr/scripts/RofiThemeSelector-modified.sh"),
	{ description = "rofi theme selector (modified)" }
)
bind(
	"SUPER CTRL",
	"K",
	exec_cmd("$HOME/.config/hypr/scripts/Kitty_themes.sh"),
	{ description = "Kitty theme selector" }
)
bind(
	"SUPER SHIFT",
	"B",
	exec_cmd("$HOME/.config/hypr/UserScripts/RainbowBorders-low-cpu.sh  --run-once"),
	{ description = "Set static Rainbow Border" }
)
bind(
	"SUPER SHIFT",
	"H",
	exec_cmd("$HOME/.config/hypr/scripts/Toggle-Active-Window-Audio.sh"),
	{ description = "Toggle Mute/Unmute for Active-Window" }
)
bind(
	"ALT SHIFT",
	"S",
	exec_cmd("$HOME/.config/hypr/scripts/hyprshot.sh -m region -o $HOME/Pictures/Screenshots"),
	{ description = "Hyprshot Screen Capture" }
)
bind("SUPER SHIFT", "F", dispatch("fullscreen", ""), { description = "fullscreen" })
bind("SUPER", "F", dispatch("fullscreen", "1"), { description = "maximize window" })
bind("SUPER", "SPACE", dispatch("togglefloating", ""), { description = "Float current window" })
bind(
	"SUPER ALT",
	"SPACE",
	exec_cmd("$HOME/.config/hypr/scripts/Float-all-Windows.sh"),
	{ description = "Float all windows" }
)
bind(
	"SUPER SHIFT",
	"Return",
	exec_cmd("$HOME/.config/hypr/scripts/Dropterminal.sh kitty"),
	{ description = "DropDown terminal" }
)
bind(
	"SUPER ALT",
	"mouse_down",
	exec_cmd(
		"hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')\""
	),
	{ description = "zoom in" }
)
bind(
	"SUPER ALT",
	"mouse_up",
	exec_cmd(
		"hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')\""
	),
	{ description = "zoom out" }
)
bind("SUPER CTRL ALT", "B", exec_cmd("pkill -SIGUSR1 waybar"), { description = "toggle waybar on/off" })
bind("SUPER CTRL", "B", exec_cmd("$HOME/.config/hypr/scripts/WaybarStyles.sh"), { description = "waybar styles menu" })
bind("SUPER ALT", "B", exec_cmd("$HOME/.config/hypr/scripts/WaybarLayout.sh"), { description = "waybar layout menu" })
bind(
	"SUPER",
	"N",
	exec_cmd("$HOME/.config/hypr/scripts/Hyprsunset.sh toggle"),
	{ description = "Toggle Hyprsunset - night light" }
)
bind("SUPER SHIFT", "M", exec_cmd("$HOME/.config/hypr/UserScripts/RofiBeats.sh"), { description = "online music" })
bind("SUPER", "W", exec_cmd("$HOME/.config/hypr/scripts/WallpaperSelect.sh"), { description = "select wallpaper" })
bind(
	"SUPER SHIFT",
	"W",
	exec_cmd("$HOME/.config/hypr/scripts/WallpaperEffects.sh"),
	{ description = "wallpaper effects" }
)
bind(
	"CTRL ALT",
	"W",
	exec_cmd("$HOME/.config/hypr/UserScripts/WallpaperRandom.sh"),
	{ description = "random wallpaper" }
)
bind("SUPER CTRL", "O", dispatch("setprop", "active opaque toggle"), { description = "toggle active window opacity" })
bind("SUPER SHIFT", "K", exec_cmd("$HOME/.config/hypr/scripts/KeyBinds.sh"), { description = "search keybinds" })
bind("SUPER SHIFT", "A", exec_cmd("$HOME/.config/hypr/scripts/Animations.sh"), { description = "animations menu" })
bind(
	"SUPER SHIFT",
	"R",
	exec_cmd("$HOME/.config/hypr/scripts/ZshChangeTheme.sh"),
	{ description = "change oh-my-zsh theme" }
)
bind(
	"ALT_L",
	"SHIFT_L",
	exec_cmd("$HOME/.config/hypr/scripts/KeyboardLayout.sh switch"),
	{ description = "switch keyboard layout globally", locked = true }
)
bind(
	"SHIFT_L",
	"ALT_L",
	exec_cmd("$HOME/.config/hypr/scripts/Tak0-Per-Window-Switch.sh"),
	{ description = "switch keyboard layout per-window", locked = true }
)
bind("SUPER ALT", "C", exec_cmd("$HOME/.config/hypr/UserScripts/RofiCalc.sh"), { description = "calculator" })
bind(
	"SUPER CTRL",
	"F9",
	dispatch("movecurrentworkspacetomonitor", "l"),
	{ description = "move workspace to left monitor" }
)
bind(
	"SUPER CTRL",
	"F10",
	dispatch("movecurrentworkspacetomonitor", "r"),
	{ description = "move workspace to right monitor" }
)
bind(
	"SUPER CTRL",
	"F11",
	dispatch("movecurrentworkspacetomonitor", "u"),
	{ description = "move workspace to up monitor" }
)
bind(
	"SUPER CTRL",
	"F12",
	dispatch("movecurrentworkspacetomonitor", "d"),
	{ description = "move workspace to down monitor" }
)
bind("CTRL ALT", "Delete", exec_cmd("$HOME/.config/hypr/scripts/Logout.sh"), { description = "exit Hyprland" })
bind("SUPER", "Q", dispatch("killactive", ""), { description = "close active window" })
bind(
	"SUPER SHIFT",
	"Q",
	exec_cmd("$HOME/.config/hypr/scripts/KillActiveProcess.sh"),
	{ description = "Terminate active process" }
)
bind("CTRL ALT", "L", exec_cmd("$HOME/.config/hypr/scripts/LockScreen.sh"), { description = "lock screen" })
bind("CTRL ALT", "P", exec_cmd("$HOME/.config/hypr/scripts/Wlogout.sh"), { description = "powermenu" })
bind("SUPER SHIFT", "N", exec_cmd("swaync-client -t -sw"), { description = "notification panel" })
bind(
	"SUPER SHIFT",
	"E",
	exec_cmd("$HOME/.config/hypr/scripts/Kool_Quick_Settings.sh"),
	{ description = "Quick settings menu" }
)
bind("SUPER CTRL", "D", dispatch("layoutmsg", "removemaster"), { description = "remove master" })
bind("SUPER", "I", dispatch("layoutmsg", "addmaster"), { description = "add master" })
bind(
	"SUPER",
	"j",
	exec_cmd("$HOME/.config/hypr/scripts/LayoutKeybindDispatch.sh cycle-next"),
	{ description = "cycle next (layout-aware)" }
)
bind(
	"SUPER",
	"k",
	exec_cmd("$HOME/.config/hypr/scripts/LayoutKeybindDispatch.sh cycle-prev"),
	{ description = "cycle previous (layout-aware)" }
)
bind("SUPER CTRL", "Return", dispatch("layoutmsg", "swapwithmaster"), { description = "swap with master" })
bind("SUPER SHIFT", "I", dispatch("layoutmsg", "togglesplit"), { description = "toggle split (dwindle)" })
bind("SUPER", "P", dispatch("pseudo", ""), { description = "toggle pseudo (dwindle)" })
bind("SUPER", "M", exec_cmd("hyprctl dispatch splitratio 0.3"), { description = "set split ratio 0.3" })
bind(
	"SUPER ALT",
	"1",
	exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh dwindle"),
	{ description = "layout dwindle" }
)
bind("SUPER ALT", "2", exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh master"), { description = "layout master" })
bind(
	"SUPER ALT",
	"3",
	exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh scrolling"),
	{ description = "layout scrolling" }
)
bind(
	"SUPER ALT",
	"4",
	exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh monocle"),
	{ description = "layout monocle" }
)
bind("SUPER SHIFT", "period", dispatch("layoutmsg", "move +col"), { description = "move to right column" })
bind("SUPER SHIFT", "comma", dispatch("layoutmsg", "move -col"), { description = "move to left column" })
bind("SUPER ALT", "comma", dispatch("layoutmsg", "swapcol l"), { description = "swap columns left" })
bind("SUPER ALT", "period", dispatch("layoutmsg", "swapcol r"), { description = "swap columns right" })
bind(
	"SUPER ALT",
	"H",
	exec_cmd("hyprctl keyword scrolling:direction right"),
	{ description = "Horizonal scroll right" }
)
bind("SUPER ALT", "V", exec_cmd("hyprctl keyword scrolling:direction down"), { description = "Vertical Scroll down" })
bind(
	"SUPER ALT",
	"S",
	exec_cmd(
		'bash -c \'[[ $(hyprctl getoption scrolling:direction -j | jq -r ".str") == "right" ]] && hyprctl keyword scrolling:direction down || hyprctl keyword scrolling:direction right\''
	),
	{ description = "toggle scrolling V/H" }
)
bind("ALT", "Tab", dispatch("cyclenext", ""), { description = "cycle next window" })
bind("ALT", "Tab", dispatch("bringactivetotop", ""), { description = "bring active to top" })
bind(
	"",
	"xf86audioraisevolume",
	exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --inc"),
	{ description = "volume up", locked = true, ["repeat"] = true }
)
bind(
	"",
	"xf86audiolowervolume",
	exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --dec"),
	{ description = "volume down", locked = true, ["repeat"] = true }
)
bind(
	"ALT",
	"xf86audioraisevolume",
	exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --inc-precise"),
	{ description = "volume up precise", locked = true, ["repeat"] = true }
)
bind(
	"ALT",
	"xf86audiolowervolume",
	exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --dec-precise"),
	{ description = "volume down precise", locked = true, ["repeat"] = true }
)
bind(
	"",
	"xf86AudioMicMute",
	exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle-mic"),
	{ description = "toggle mic mute", locked = true }
)
bind(
	"",
	"xf86audiomute",
	exec_cmd("$HOME/.config/hypr/scripts/Volume.sh --toggle"),
	{ description = "toggle mute", locked = true }
)
bind("", "xf86Sleep", exec_cmd("systemctl suspend"), { description = "sleep", locked = true })
bind(
	"",
	"xf86Rfkill",
	exec_cmd("$HOME/.config/hypr/scripts/AirplaneMode.sh"),
	{ description = "airplane mode", locked = true }
)
bind(
	"",
	"xf86AudioPlayPause",
	exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"),
	{ description = "play/pause", locked = true }
)
bind(
	"",
	"xf86AudioPause",
	exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"),
	{ description = "pause", locked = true }
)
bind(
	"",
	"xf86AudioPlay",
	exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --pause"),
	{ description = "play", locked = true }
)
bind(
	"",
	"xf86AudioNext",
	exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --nxt"),
	{ description = "next track", locked = true }
)
bind(
	"",
	"xf86AudioPrev",
	exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --prv"),
	{ description = "previous track", locked = true }
)
bind(
	"",
	"xf86audiostop",
	exec_cmd("$HOME/.config/hypr/scripts/MediaCtrl.sh --stop"),
	{ description = "stop", locked = true }
)
bind("SUPER", "Print", exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --now"), { description = "screenshot now" })
bind(
	"SUPER SHIFT",
	"Print",
	exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"),
	{ description = "screenshot (area)" }
)
bind(
	"SUPER CTRL",
	"Print",
	exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in5"),
	{ description = "screenshot in 5s" }
)
bind(
	"SUPER CTRL SHIFT",
	"Print",
	exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --in10"),
	{ description = "screenshot in 10s" }
)
bind(
	"ALT",
	"Print",
	exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --active"),
	{ description = "screenshot active window" }
)
bind(
	"SUPER SHIFT",
	"S",
	exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --swappy"),
	{ description = "screenshot (swappy)" }
)
bind("SUPER SHIFT", "left", dispatch("resizeactive", "-50 0"), { description = "resize left (-50)", ["repeat"] = true })
bind(
	"SUPER SHIFT",
	"right",
	dispatch("resizeactive", "50 0"),
	{ description = "resize right (+50)", ["repeat"] = true }
)
bind("SUPER SHIFT", "up", dispatch("resizeactive", "0 -50"), { description = "resize up (-50)", ["repeat"] = true })
bind("SUPER SHIFT", "down", dispatch("resizeactive", "0 50"), { description = "resize down (+50)", ["repeat"] = true })
bind("SUPER CTRL", "left", dispatch("movewindow", "l"), { description = "move window left" })
bind("SUPER CTRL", "right", dispatch("movewindow", "r"), { description = "move window right" })
bind("SUPER CTRL", "up", dispatch("movewindow", "u"), { description = "move window up" })
bind("SUPER CTRL", "down", dispatch("movewindow", "d"), { description = "move window down" })
bind("SUPER ALT", "left", dispatch("swapwindow", "l"), { description = "swap window left" })
bind("SUPER ALT", "right", dispatch("swapwindow", "r"), { description = "swap window right" })
bind("SUPER ALT", "up", dispatch("swapwindow", "u"), { description = "swap window up" })
bind("SUPER ALT", "down", dispatch("swapwindow", "d"), { description = "swap window down" })
bind("SUPER", "G", dispatch("togglegroup", ""), { description = "toggle group" })
bind("SUPER", "Tab", dispatch("changegroupactive", "f"), { description = "Change Group Forward" })
bind("SUPER CTRL", "tab", dispatch("changegroupactive", ""), { description = "change active in group" })
bind("SUPER SHIFT", "Tab", dispatch("changegroupactive", "b"), { description = "Change Group Back" })
bind("SUPER CTRL", "K", dispatch("moveintogroup", "l"), { description = "Move left into group" })
bind("SUPER CTRL", "L", dispatch("moveintogroup", "r"), { description = "Move Right into group" })
bind("SUPER CTRL", "H", dispatch("moveoutofgroup", ""), { description = "Move active out of group" })
bind(
	"SUPER",
	"left",
	exec_cmd("$HOME/.config/hypr/scripts/LayoutKeybindDispatch.sh focus-left"),
	{ description = "focus left (layout-aware)" }
)
bind(
	"SUPER",
	"right",
	exec_cmd("$HOME/.config/hypr/scripts/LayoutKeybindDispatch.sh focus-right"),
	{ description = "focus right (layout-aware)" }
)
bind(
	"SUPER",
	"up",
	exec_cmd("$HOME/.config/hypr/scripts/LayoutKeybindDispatch.sh focus-up"),
	{ description = "focus up (layout-aware)" }
)
bind(
	"SUPER",
	"down",
	exec_cmd("$HOME/.config/hypr/scripts/LayoutKeybindDispatch.sh focus-down"),
	{ description = "focus down (layout-aware)" }
)
bind("SUPER", "tab", dispatch("workspace", "m+1"), { description = "next workspace" })
bind("SUPER SHIFT", "tab", dispatch("workspace", "m-1"), { description = "previous workspace" })
bind("SUPER SHIFT", "U", dispatch("movetoworkspace", "special"), { description = "move to special workspace" })
bind("SUPER", "U", dispatch("togglespecialworkspace", ""), { description = "toggle special workspace" })
bind("SUPER", "code:10", dispatch("workspace", "1"), { description = "workspace 1" })
bind("SUPER", "code:11", dispatch("workspace", "2"), { description = "workspace 2" })
bind("SUPER", "code:12", dispatch("workspace", "3"), { description = "workspace 3" })
bind("SUPER", "code:13", dispatch("workspace", "4"), { description = "workspace 4" })
bind("SUPER", "code:14", dispatch("workspace", "5"), { description = "workspace 5" })
bind("SUPER", "code:15", dispatch("workspace", "6"), { description = "workspace 6" })
bind("SUPER", "code:16", dispatch("workspace", "7"), { description = "workspace 7" })
bind("SUPER", "code:17", dispatch("workspace", "8"), { description = "workspace 8" })
bind("SUPER", "code:18", dispatch("workspace", "9"), { description = "workspace 9" })
bind("SUPER", "code:19", dispatch("workspace", "10"), { description = "workspace 10" })
bind("SUPER SHIFT", "code:10", dispatch("movetoworkspace", "1"), { description = "move to workspace 1" })
bind("SUPER SHIFT", "code:11", dispatch("movetoworkspace", "2"), { description = "move to workspace 2" })
bind("SUPER SHIFT", "code:12", dispatch("movetoworkspace", "3"), { description = "move to workspace 3" })
bind("SUPER SHIFT", "code:13", dispatch("movetoworkspace", "4"), { description = "move to workspace 4" })
bind("SUPER SHIFT", "code:14", dispatch("movetoworkspace", "5"), { description = "move to workspace 5" })
bind("SUPER SHIFT", "code:15", dispatch("movetoworkspace", "6"), { description = "move to workspace 6" })
bind("SUPER SHIFT", "code:16", dispatch("movetoworkspace", "7"), { description = "move to workspace 7" })
bind("SUPER SHIFT", "code:17", dispatch("movetoworkspace", "8"), { description = "move to workspace 8" })
bind("SUPER SHIFT", "code:18", dispatch("movetoworkspace", "9"), { description = "move to workspace 9" })
bind("SUPER SHIFT", "code:19", dispatch("movetoworkspace", "10"), { description = "move to workspace 10" })
bind("SUPER SHIFT", "bracketleft", dispatch("movetoworkspace", "-1"), { description = "move to previous workspace" })
bind("SUPER SHIFT", "bracketright", dispatch("movetoworkspace", "+1"), { description = "move to next workspace" })
bind("SUPER CTRL", "code:10", dispatch("movetoworkspacesilent", "1"), { description = "move silently to workspace 1" })
bind("SUPER CTRL", "code:11", dispatch("movetoworkspacesilent", "2"), { description = "move silently to workspace 2" })
bind("SUPER CTRL", "code:12", dispatch("movetoworkspacesilent", "3"), { description = "move silently to workspace 3" })
bind("SUPER CTRL", "code:13", dispatch("movetoworkspacesilent", "4"), { description = "move silently to workspace 4" })
bind("SUPER CTRL", "code:14", dispatch("movetoworkspacesilent", "5"), { description = "move silently to workspace 5" })
bind("SUPER CTRL", "code:15", dispatch("movetoworkspacesilent", "6"), { description = "move silently to workspace 6" })
bind("SUPER CTRL", "code:16", dispatch("movetoworkspacesilent", "7"), { description = "move silently to workspace 7" })
bind("SUPER CTRL", "code:17", dispatch("movetoworkspacesilent", "8"), { description = "move silently to workspace 8" })
bind("SUPER CTRL", "code:18", dispatch("movetoworkspacesilent", "9"), { description = "move silently to workspace 9" })
bind(
	"SUPER CTRL",
	"code:19",
	dispatch("movetoworkspacesilent", "10"),
	{ description = "move silently to workspace 10" }
)
bind(
	"SUPER CTRL",
	"bracketleft",
	dispatch("movetoworkspacesilent", "-1"),
	{ description = "move silently to previous workspace" }
)
bind(
	"SUPER CTRL",
	"bracketright",
	dispatch("movetoworkspacesilent", "+1"),
	{ description = "move silently to next workspace" }
)
bind("SUPER", "mouse_down", dispatch("workspace", "e+1"), { description = "next workspace" })
bind("SUPER", "mouse_up", dispatch("workspace", "e-1"), { description = "previous workspace" })
bind("SUPER", "period", dispatch("workspace", "e+1"), { description = "next workspace" })
bind("SUPER", "comma", dispatch("workspace", "e-1"), { description = "previous workspace" })
bind("SUPER", "mouse:272", dispatch("movewindow", ""), { description = "move window" })
bind("SUPER", "mouse:273", dispatch("resizewindow", ""), { description = "resize window" })

-- ============================================================
-- User overrides
-- ============================================================

unbind("SUPER SHIFT", "left")
unbind("SUPER SHIFT", "right")
unbind("SUPER SHIFT", "up")
unbind("SUPER SHIFT", "down")

unbind("SUPER", "A")
unbind("SUPER", "F")

unbind("SUPER", "left")
unbind("SUPER", "right")
unbind("SUPER", "up")
unbind("SUPER", "down")

unbind("SUPER", "H")
unbind("SUPER", "J")
unbind("SUPER", "K")

unbind("SUPER", "D")
unbind("SUPER", "SPACE")

unbind("SUPER", "P")
unbind("SUPER SHIFT", "H")
unbind("SUPER SHIFT", "K")

bind("ALT", "SPACE", exec_cmd("vicinae toggle"), { description = "Toggle vicinae" })

bind("SUPER SHIFT", "left", exec_cmd("movewindow l"), { description = "Move window left" })
bind("SUPER SHIFT", "right", exec_cmd("movewindow r"), { description = "Move window right" })
bind("SUPER SHIFT", "up", exec_cmd("movewindow u"), { description = "Move window up" })
bind("SUPER SHIFT", "down", exec_cmd("movewindow d"), { description = "Move window down" })
bind("SUPER SHIFT", "H", exec_cmd(scriptsDir .. "/MoveWrap.sh l"), { description = "Move window left" })
bind("SUPER SHIFT", "L", exec_cmd(scriptsDir .. "/MoveWrap.sh r"), { description = "Move window right" })
bind("SUPER SHIFT", "K", exec_cmd(scriptsDir .. "/MoveWrap.sh u"), { description = "Move window up / prev workspace" })
bind("SUPER SHIFT", "J", exec_cmd(scriptsDir .. "/MoveWrap.sh d"), { description = "Move window down / next workspace" })

bind("SUPER", "A", exec_cmd("movecurrentworkspacetomonitor l"), { description = "Move workspace left" })
bind("SUPER", "F", exec_cmd("movecurrentworkspacetomonitor r"), { description = "Move workspace right" })

bind("SUPER CTRL", "A", exec_cmd(scriptsDir .. "/OverviewToggle.sh"), { description = "Desktop overview" })
bind("SUPER CTRL", "F", exec_cmd("fullscreen 1"), { description = "Maximize window" })

bind("SUPER", "D", exec_cmd("togglefloating"), { description = "Toggle float" })
bind("SUPER", "SPACE", exec_cmd("pkill rofi || true; " .. scriptsDir .. "/RofiFocusedWallpaperLink.sh >/dev/null 2>&1 || true; rofi -show drun -modi drun,filebrowser,run,window"), { description = "App launcher" })

bind("SUPER", "H", exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh focus-left"), { description = "Focus left" })
bind("SUPER", "J", exec_cmd(scriptsDir .. "/FocusWrap.sh d"), { description = "Focus down / next workspace" })
bind("SUPER", "K", exec_cmd(scriptsDir .. "/FocusWrap.sh u"), { description = "Focus up / prev workspace" })
bind("SUPER", "L", exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh focus-right"), { description = "Focus right" })

bind("SUPER", "slash", exec_cmd(scriptsDir .. "/KeyHints.sh"), { description = "Help / cheat sheet" })

bind("SUPER", "bracketleft", exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh cycle-next"), { description = "Cycle next (layout-aware)" })
bind("SUPER", "bracketright", exec_cmd(scriptsDir .. "/LayoutKeybindDispatch.sh cycle-prev"), { description = "Cycle previous (layout-aware)" })

bind("SUPER", "P", exec_cmd("hyprpicker -a -f hex --lowercase-hex"), { description = "Color picker" })
