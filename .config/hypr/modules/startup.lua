---@param value any
---@return string
local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param cmd string
---@param opts table|nil
local function exec_once(cmd, opts)
	-- Why this wrapper exists:
	-- 1) Enforce once-per-Hypr-session startup behavior using marker files.
	-- 2) Avoid startup race conditions by waiting for Wayland/Hypr sockets.
	-- 3) Capture per-command logs to simplify troubleshooting in user setups.

	opts = opts or {}
	local session = opts.session or os.getenv("HYPRLAND_INSTANCE_SIGNATURE") or "default"
	local marker_prefix = opts.marker_prefix or "/tmp/hypr-lua-user-exec-once-"
	local log_prefix = opts.log_prefix or "/tmp/hypr-lua-user-startup-"

	local key = cmd:gsub("[^%w_.-]", "_"):sub(1, 80)
	local marker = marker_prefix .. session .. "-" .. key
	local log = log_prefix .. key .. ".log"
	local readiness =
		[[runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}; export XDG_RUNTIME_DIR="$runtime"; for _ in $(seq 1 200); do if [ -n "$WAYLAND_DISPLAY" ] && [ -S "$runtime/$WAYLAND_DISPLAY" ]; then break; fi; for sock in "$runtime"/wayland-[0-9]*; do [ -S "$sock" ] || continue; case "$(basename "$sock")" in *awww*) continue ;; esac; export WAYLAND_DISPLAY="$(basename "$sock")"; break 2; done; sleep 0.1; done; if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then hypr_sock="$runtime/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock"; for _ in $(seq 1 200); do [ -S "$hypr_sock" ] && break; sleep 0.1; done; fi]]
	local inner = readiness .. "; " .. cmd
	local script = "[ -e "
		.. shell_quote(marker)
		.. " ] || { touch "
		.. shell_quote(marker)
		.. " && sh -lc "
		.. shell_quote(inner)
		.. " >>"
		.. shell_quote(log)
		.. " 2>&1 & }"
	os.execute("sh -c " .. shell_quote(script))
end

-- Auto-reload Hyprland when configs/*.lua change
exec_once("$HOME/.config/hypr/scripts/LuaAutoReload.sh")

-- DBus / systemd environment
exec_once("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
exec_once("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
exec_once("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'")
exec_once("gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-blue'")
exec_once("gsettings set org.gnome.desktop.interface cursor-size 24")

-- Core services
exec_once("$HOME/.config/hypr/scripts/Polkit.sh")
exec_once("nm-applet")

-- Portals and theme
exec_once("$HOME/.config/hypr/scripts/PortalHyprland.sh")

-- Caelestia shell (bar, launcher, notifications, session, OSD)
-- Waybar kept on disk as fallback but no longer autostarted.
-- exec_once("sh $HOME/.config/hypr/scripts/WaybarStartup.sh")

-- Cursor refresh
exec_once(
	'sh -c \'sleep 0.3; hyprctl setcursor "${HYPRCURSOR_THEME:-catppuccin-mocha-blue}" "${HYPRCURSOR_SIZE:-24}"\''
)

-- Noctalia shell
exec_once("noctalia --daemon")

-- Idle manager
-- exec_once("hypridle")

-- Hypr plugins
exec_once("hyprpm reload")

-- Vicinae
exec_once("vicinae server")

-- Hyprsunset
exec_once("$HOME/.config/hypr/scripts/Hyprsunset.sh init")

-- Drop terminal
exec_once("$HOME/.config/hypr/scripts/Dropterminal.sh --startup kitty")

-- Clipboard manager
exec_once("wl-paste --type text --watch cliphist store")
exec_once("wl-paste --type image --watch cliphist store")

-- Bluetooth
exec_once("blueman-applet")

-- pm2
exec_once("pm2 resurrect")
