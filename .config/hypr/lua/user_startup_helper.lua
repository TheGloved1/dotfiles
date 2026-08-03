---@param value any
---@return string
local function shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---@param cmd string
---@param opts table|nil
---@field session string|nil Hyprland instance signature override
---@field marker_prefix string|nil Temp directory prefix for marker files
---@field log_prefix string|nil Temp directory prefix for log files
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
	os.execute("sh -lc " .. shell_quote(script))
end

return {
	exec_once = exec_once,
}
