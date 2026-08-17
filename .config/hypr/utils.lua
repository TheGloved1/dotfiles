-- Shared helpers plus the former scripts/ directory converted to Lua.
-- Loaded by setup.lua and exposed globally as `Utils`.

local Utils = {}

local HOME = os.getenv("HOME") or ""
local CONFIG_HOME = os.getenv("XDG_CONFIG_HOME") or (HOME .. "/.config")
local HYPR_DIR = CONFIG_HOME .. "/hypr"
local IMAGES_DIR = CONFIG_HOME .. "/noctalia/images"
local ICONS_DIR = CONFIG_HOME .. "/noctalia/icons"

-- ============================================
--  BASIC HELPERS
-- ============================================

---Trim surrounding whitespace.
function Utils.trim(value)
	return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

---Shell single-quote a value safely.
function Utils.shell_quote(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

---Check whether a command is on PATH.
function Utils.is_exec(cmd)
	local pipe = io.popen("command -v " .. cmd .. " 2>/dev/null", "r")
	if not pipe then
		return false
	end
	local out = pipe:read("*a")
	pipe:close()
	return out:match("%S") ~= nil
end

---Check if path is a file.
function Utils.is_file(path)
	return os.execute("test -f " .. path) == 0
end

---Check if path is a directory.
function Utils.is_dir(path)
	return os.execute("test -d " .. path) == 0
end

---Capture stdout (and stderr) of a command.
function Utils.capture(cmd)
	local pipe = io.popen(cmd .. " 2>&1", "r")
	if not pipe then
		return ""
	end
	local out = pipe:read("*a") or ""
	pipe:close()
	return out
end

---Run a command fully detached, discarding its output.
function Utils.detach(cmd)
	os.execute(cmd .. " >/dev/null 2>&1 &")
end

---Blocking sleep.
function Utils.sleep(sec)
	os.execute("sleep " .. tostring(sec))
end

---Run fn once after a delay (non-blocking).
function Utils.delayed(ms, fn)
	if hl and hl.timer then
		hl.timer(fn, { timeout = ms, type = "oneshot" })
	else
		fn()
	end
end

---notify-send wrapper.
---@param title string
---@param body string
---@param opts table|nil {urgency, expire, icon, replace}
function Utils.notify(title, body, opts)
	opts = opts or {}
	if not Utils.is_exec("notify-send") then
		return
	end
	local cmd = "notify-send"
	if opts.urgency then
		cmd = cmd .. " -u " .. opts.urgency
	end
	if opts.expire then
		cmd = cmd .. " -t " .. tostring(opts.expire)
	end
	if opts.icon then
		cmd = cmd .. " -i " .. Utils.shell_quote(opts.icon)
	end
	if opts.replace then
		cmd = cmd .. " -h string:x-canonical-private-synchronous:" .. tostring(opts.replace)
	end
	cmd = cmd .. " " .. Utils.shell_quote(tostring(title or ""))
	if body ~= nil and body ~= "" then
		cmd = cmd .. " " .. Utils.shell_quote(tostring(body))
	end
	Utils.detach(cmd)
end

---Check for a process by exact name.
function Utils.process_running(name)
	local pipe = io.popen("pgrep -x " .. name .. " 2>/dev/null", "r")
	if not pipe then
		return false
	end
	local out = pipe:read("*a")
	pipe:close()
	return out:match("%S") ~= nil
end

---Read a whole file, nil when missing.
function Utils.read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

---Write a whole file.
function Utils.write_file(path, content)
	local f = io.open(path, "w")
	if not f then
		return false
	end
	f:write(content)
	f:close()
	return true
end

---Extract an x/y component from a Vec2-like or 1-indexed array.
function Utils.vec(v, i)
	if type(v) == "table" then
		if v.x ~= nil or v.y ~= nil then
			if i == 1 then
				return v.x or 0
			end
			return v.y or 0
		end
		if v.width ~= nil or v.height ~= nil then
			if i == 1 then
				return v.width or 0
			end
			return v.height or 0
		end
		return tonumber(v[i]) or 0
	end
	return tonumber(v) or 0
end

---Interactive picker (noctalia dmenu by default). Non-blocking; the
---selection is delivered to `cb` (nil when the picker was cancelled).
---@param items table|string list of choices, or raw input when opts.raw
---@param prompt string
---@param cb function
---@param opts table|nil {command, args, raw, prompt_arg}
function Utils.pick(items, prompt, cb, opts)
	opts = opts or {}
	local command = opts.command or "noctalia dmenu"
	if not Utils.is_exec(command) then
		if cb then
			cb(nil)
		end
		return
	end
	local prompt_arg = opts.prompt_arg ~= false
	local args = opts.args
	if not args and prompt_arg then
		args = "-p " .. Utils.shell_quote(prompt)
	end
	local nonce = tostring(os.time()) .. "-" .. tostring(math.random(10000, 99999))
	local input = "/tmp/hypr-lua-pick-" .. nonce .. ".in"
	local output = "/tmp/hypr-lua-pick-" .. nonce .. ".out"
	local pidfile = "/tmp/hypr-lua-pick-" .. nonce .. ".pid"

	local content = opts.raw and tostring(items) or (type(items) == "table" and (table.concat(items, "\n") .. "\n") or tostring(items))
	if not Utils.write_file(input, content) then
		if cb then
			cb(nil)
		end
		return
	end

	local spawn = command
		.. " "
		.. (args or "")
		.. " < "
		.. input
		.. " > "
		.. output
		.. " 2>/dev/null & echo $! > "
		.. pidfile
	os.execute("sh -c " .. Utils.shell_quote(spawn) .. " &")

	local tries = 0
	local timer
	local function finish()
		if timer then
			timer:set_enabled(false)
		end
		os.remove(input)
		os.remove(output)
		os.remove(pidfile)
	end

	timer = hl.timer(function()
		tries = tries + 1
		if tries > 900 then
			finish()
			if cb then
				cb(nil)
			end
			return
		end
		local pid = Utils.trim(Utils.read_file(pidfile) or "")
		if pid == "" then
			return
		end
		if not Utils.is_exec("kill") then
			-- kill not available, assume process alive
		elseif os.execute("kill -0 " .. pid .. " 2>/dev/null") ~= 0 then
			-- process no longer alive
			finish()
			local sel = Utils.trim(Utils.read_file(output) or "")
			if cb then
				cb(sel ~= "" and sel or nil)
			end
			return
		end
		-- process still alive, continue polling
	end, { timeout = 100, type = "repeat" })
end

---Minimal JSON decoder (used for `hyprctl binds -j`).
do
	local function decode_string(text, pos)
		pos = pos + 1
		local buf = {}
		while pos <= #text do
			local ch = text:sub(pos, pos)
			if ch == '"' then
				pos = pos + 1
				break
			elseif ch == "\\" then
				pos = pos + 1
				local esc = text:sub(pos, pos)
				if esc == "n" then
					buf[#buf + 1] = "\n"
				elseif esc == "t" then
					buf[#buf + 1] = "\t"
				elseif esc == "r" then
					buf[#buf + 1] = "\r"
				elseif esc == "b" then
					buf[#buf + 1] = "\b"
				elseif esc == "f" then
					buf[#buf + 1] = "\f"
				elseif esc == "u" then
					local hex = text:sub(pos + 1, pos + 4)
					local n = tonumber(hex, 16) or 63
					buf[#buf + 1] = string.char(n)
					pos = pos + 4
				else
					buf[#buf + 1] = esc
				end
			else
				buf[#buf + 1] = ch
			end
			pos = pos + 1
		end
		return table.concat(buf), pos
	end

	local function skip_space(text, pos)
		while pos <= #text and text:sub(pos, pos):match("%s") do
			pos = pos + 1
		end
		return pos
	end

	local parse
	parse = function(text, pos)
		pos = skip_space(text, pos)
		if pos > #text then
			return nil, pos
		end
		local ch = text:sub(pos, pos)
		if ch == "{" then
			pos = pos + 1
			local obj = {}
			pos = skip_space(text, pos)
			if text:sub(pos, pos) == "}" then
				return obj, pos + 1
			end
			while true do
				pos = skip_space(text, pos)
				if text:sub(pos, pos) ~= '"' then
					return nil, pos
				end
				local key
				key, pos = decode_string(text, pos)
				pos = skip_space(text, pos)
				if text:sub(pos, pos) ~= ":" then
					return nil, pos
				end
				local value
				value, pos = parse(text, pos + 1)
				obj[key] = value
				pos = skip_space(text, pos)
				local sep = text:sub(pos, pos)
				if sep == "," then
					pos = pos + 1
				elseif sep == "}" then
					return obj, pos + 1
				else
					return nil, pos
				end
			end
		elseif ch == "[" then
			pos = pos + 1
			local arr = {}
			pos = skip_space(text, pos)
			if text:sub(pos, pos) == "]" then
				return arr, pos + 1
			end
			while true do
				local value
				value, pos = parse(text, pos)
				arr[#arr + 1] = value
				pos = skip_space(text, pos)
				local sep = text:sub(pos, pos)
				if sep == "," then
					pos = pos + 1
				elseif sep == "]" then
					return arr, pos + 1
				else
					return nil, pos
				end
			end
		elseif ch == '"' then
			return decode_string(text, pos)
		elseif text:sub(pos, pos + 3) == "true" then
			return true, pos + 4
		elseif text:sub(pos, pos + 4) == "false" then
			return false, pos + 5
		elseif text:sub(pos, pos + 3) == "null" then
			return nil, pos + 4
		else
			local num = text:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
			if num and num ~= "" then
				return tonumber(num), pos + #num
			end
			return nil, pos
		end
	end

	Utils.json = {}
	function Utils.json.decode(text)
		local ok, result = pcall(parse, tostring(text or ""), 1)
		if not ok then
			return nil
		end
		return result
	end
end

-- ============================================
--  HARVESTED MODULE HELPERS
-- ============================================

---Once-per-Hypr-session detached startup runner (from startup.lua).
---@param cmd string
---@param opts table|nil
function Utils.once(cmd, opts)
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
		.. Utils.shell_quote(marker)
		.. " ] || { touch "
		.. Utils.shell_quote(marker)
		.. " && sh -lc "
		.. Utils.shell_quote(inner)
		.. " >>"
		.. Utils.shell_quote(log)
		.. " 2>&1 & }"
	os.execute("sh -c " .. Utils.shell_quote(script))
end

---Hyprglass tint color helper (from plugins.lua).
function Utils.tint(c, alpha)
	return tonumber(c:match("%x%x%x%x%x%x"), 16) * 256 + math.floor(alpha * 255 + 0.5)
end

---Dedup XDG_DATA_DIRS keeping canonical + flatpak dirs first (from env.lua).
function Utils.xdg_data_dirs(current)
	current = current or os.getenv("XDG_DATA_DIRS") or ""
	local user_home = os.getenv("HOME") or ""
	local canonical = { "/usr/local/share", "/usr/share", "/var/lib/flatpak/exports/share" }
	if user_home ~= "" then
		canonical[#canonical + 1] = user_home .. "/.local/share/flatpak/exports/share"
	end
	local seen, parts = {}, {}
	local function append_dir(dir)
		if dir ~= "" and not seen[dir] then
			seen[dir] = true
			parts[#parts + 1] = dir
		end
	end
	for _, dir in ipairs(canonical) do
		append_dir(dir)
	end
	for dir in current:gmatch("[^:]+") do
		append_dir(dir)
	end
	return table.concat(parts, ":")
end

-- ============================================
--  LAYOUT / WINDOW HELPERS
-- ============================================

local LAYOUTS = { "master", "dwindle", "scrolling", "monocle" }

function Utils.normalize_layout(l)
	l = l or ""
	for _, name in ipairs(LAYOUTS) do
		if l == name then
			return name
		end
	end
	return nil
end

function Utils.get_active_layout()
	local ws = hl.get_active_workspace()
	if ws then
		local layout = Utils.normalize_layout(ws.tiled_layout)
		if layout then
			return layout
		end
	end
	local layout = Utils.normalize_layout(hl.get_config("general.layout"))
	if layout then
		return layout
	end
	return "dwindle"
end

---Visible windows on a workspace (same id/name), matching hyprctl clients.
function Utils.windows_on_workspace(ws)
	local wins = {}
	if not ws then
		return wins
	end
	for _, w in ipairs(hl.get_windows()) do
		if w.workspace and (w.workspace.id == ws.id or (ws.name and w.workspace.name == ws.name)) then
			wins[#wins + 1] = w
		end
	end
	return wins
end

function Utils.window_center(w)
	return Utils.vec(w.at, 1) + Utils.vec(w.size, 1) / 2, Utils.vec(w.at, 2) + Utils.vec(w.size, 2) / 2
end

---Extract the first token of a command string (shell word splitting).
function Utils.command_bin(cmd)
	cmd = Utils.trim(cmd or "")
	local bin = cmd:match("^%s*([^%s]+)")
	if not bin then
		return nil
	end
	return bin:gsub("^['\"]", ""):gsub("['\"]$", "")
end

-- ============================================
--  SCRIPTS
-- ============================================

---Refresh Noctalia shell and Hyprland (Refresh.sh).
function Utils.refresh()
	os.execute("noctalia msg config-reload >/dev/null 2>&1")
	os.execute("hyprctl reload >/dev/null 2>&1")
end

---Kill the active window's process (KillActiveProcess.sh).
function Utils.kill_active_process()
	local w = hl.get_active_window()
	if not w or not w.pid or w.pid <= 0 then
		Utils.notify(
			"Kill Active Window",
			"No active window PID found.",
			{ urgency = "low", icon = IMAGES_DIR .. "/error.png" }
		)
		return
	end
	os.execute("kill " .. tostring(w.pid))
end

---Toggle-float every window on the active workspace (Float-all-Windows.sh).
function Utils.float_all_windows()
	local ws = hl.get_active_workspace()
	if not ws then
		return
	end
	for _, w in ipairs(hl.get_windows()) do
		if w.workspace and w.workspace.id == ws.id and not w.hidden then
			hl.dispatch(hl.dsp.window.float({ window = "address:" .. w.address, action = "toggle" }))
		end
	end
end

---Play system sounds (Sounds.sh). kind: screenshot | volume | error.
function Utils.sounds(kind)
	local directSoundDir = HYPR_DIR .. "/sounds"

	local directSound, soundoption
	if kind == "screenshot" then
		directSound = directSoundDir .. "/screenshot.ogg"
		soundoption = "screen-capture.*"
	elseif kind == "volume" then
		directSound = directSoundDir .. "/volume.ogg"
		soundoption = "audio-volume-change.*"
	elseif kind == "error" then
		directSound = directSoundDir .. "/error.ogg"
		soundoption = "dialog-error.*"
	else
		return
	end

	local systemDIR = "/run/current-system/sw/share/sounds"
	if not Utils.is_dir(systemDIR) then
		systemDIR = "/usr/share/sounds"
	end
	local userDIR = HOME .. "/.local/share/sounds"
	local defaultTheme = "freedesktop"

	local sDIR = systemDIR .. "/" .. defaultTheme
	if Utils.is_dir(userDIR .. "/freedesktop") then
		sDIR = userDIR .. "/freedesktop"
	elseif Utils.is_dir(systemDIR .. "/freedesktop") then
		sDIR = systemDIR .. "/freedesktop"
	end

	local iTheme = ""
	local themeFile = Utils.read_file(sDIR .. "/index.theme")
	if themeFile then
		iTheme = themeFile:match("[Ii]nherits%s*=%s*([^\n]+)") or ""
		iTheme = Utils.trim(iTheme)
	end
	local iDIR = sDIR .. "/../" .. iTheme

	local function play_sound(file)
		for _, player in ipairs({ "paplay", "pw-play", "aplay" }) do
			if Utils.is_exec(player) then
				Utils.detach(player .. " " .. Utils.shell_quote(file))
				return true
			end
		end
		return false
	end

	if directSound and Utils.is_file(directSound) then
		play_sound(directSound)
		return
	end

	local dirs = {
		sDIR .. "/stereo",
		iDIR .. "/stereo",
		userDIR .. "/" .. defaultTheme .. "/stereo",
		systemDIR .. "/" .. defaultTheme .. "/stereo",
	}
	for _, dir in ipairs(dirs) do
		local found = Utils.trim(
			Utils.capture(
				"find -L "
					.. Utils.shell_quote(dir)
					.. " -name "
					.. Utils.shell_quote(soundoption)
					.. " -print -quit 2>/dev/null"
			)
		)
		if Utils.is_file(found) then
			play_sound(found)
			return
		end
	end
end

---Cycle focus among visible windows on the active workspace (LuaCycleWindow.sh).
function Utils.lua_cycle_window(mode)
	if mode == "previous" or mode == "prev" or mode == "back" or mode == "b" then
		mode = "previous"
	else
		mode = "next"
	end

	local active = hl.get_active_window()
	if not active or not active.workspace then
		return
	end
	local ws = active.workspace
	local wins = {}
	for _, w in ipairs(hl.get_windows()) do
		if w.workspace and w.workspace.id ~= nil and ws.id ~= nil and w.workspace.id == ws.id and w.mapped and not w.hidden then
			local at = w.at or {}
			if at then
				wins[#wins + 1] = {
					addr = w.address,
					x = Utils.vec(at, 1),
					y = Utils.vec(at, 2),
				}
			end
		end
	end
	if #wins < 2 then
		return
	end

	table.sort(wins, function(a, b)
		if a.y == b.y then
			if a.x == b.x then
				return a.addr < b.addr
			end
			return a.x < b.x
		end
		return a.y < b.y
	end)

	local index
	for i, w in ipairs(wins) do
		if w.addr and active.address and w.addr == active.address then
			index = i
			break
		end
	end
	if not index then
		return
	end

	local target
	if mode == "previous" then
		target = wins[((index - 2 + #wins) % #wins) + 1]
	else
		target = wins[(index % #wins) + 1]
	end
	if target then
		hl.dispatch(hl.dsp.focus({ window = "address:" .. target.addr }))
	end
end

---Move window with edge wrap to adjacent workspace (MoveWrap.sh).
function Utils.move_wrap(direction)
	local MAX_WORKSPACE = 10

	local ws = hl.get_active_workspace()
	if not ws then
		return
	end

	local active = hl.get_active_window()
	if not active then
		return
	end
	if (active.fullscreen or 0) ~= 0 then
		hl.dispatch(hl.dsp.window.move({ direction = "u" }))
		return
	end

	local layout = Utils.normalize_layout(ws.tiled_layout)
	if not layout then
		local cfg = hl.get_config("general.layout")
		layout = Utils.normalize_layout(cfg)
	end

	-- Left/right: wrap within same workspace using swapcol if scrolling layout
	if direction == "l" or direction == "left" then
		if layout == "scrolling" then
			hl.dispatch(hl.dsp.layout("swapcol l"))
		else
			hl.dispatch(hl.dsp.window.move({ direction = "l" }))
		end
		return
	elseif direction == "r" or direction == "right" then
		if layout == "scrolling" then
			hl.dispatch(hl.dsp.layout("swapcol r"))
		else
			hl.dispatch(hl.dsp.window.move({ direction = "r" }))
		end
		return
	end

	-- Up/down: move to adjacent workspace
	local current = (ws and ws.id) or 1
	local delta
	if direction == "u" or direction == "up" then
		delta = -1
	elseif direction == "d" or direction == "down" then
		delta = 1
	else
		return
	end

	local function move_to_workspace(target)
		if target < 1 or target > MAX_WORKSPACE then
			return
		end
		hl.dispatch(hl.dsp.window.move({ workspace = target }))
	end

	local target_ws = current + delta
	move_to_workspace(target_ws)
end

---Layout-aware focus navigation with horizontal wrap (FocusWrap.sh).
function Utils.focus_wrap(direction)
	local dir, ws_dir
	if direction == "l" or direction == "left" then
		dir, ws_dir = "l", "e-1"
	elseif direction == "r" or direction == "right" then
		dir, ws_dir = "r", "e+1"
	elseif direction == "u" or direction == "up" then
		dir, ws_dir = "u", "e-1"
	elseif direction == "d" or direction == "down" then
		dir, ws_dir = "d", "e+1"
	else
		return
	end

	local active = hl.get_active_window()
	if not active or not active.at then
		return
	end
	if active and (active.fullscreen or 0) ~= 0 then
		hl.dispatch(hl.dsp.focus({ workspace = ws_dir }))
		return
	end

	local ws = hl.get_active_workspace()
	if not active or not ws then
		return
	end
	local current_x = Utils.vec(active.at, 1)
	local current_y = Utils.vec(active.at, 2)

	if dir == "l" or dir == "r" then
		local candidates = {}
		for _, w in ipairs(Utils.windows_on_workspace(ws)) do
			if w.address and active.address and w.address ~= active.address then
				local cx, cy = Utils.window_center(w)
				candidates[#candidates + 1] = { addr = w.address, x = cx, y = cy }
			end
		end

		if dir == "l" then
			local pick
			for _, c in ipairs(candidates) do
				if c.x < current_x and (not pick or c.x > pick.x) then
					pick = c
				end
			end
			if pick then
				hl.dispatch(hl.dsp.focus({ window = "address:" .. pick.addr }))
				return
			end
			if #candidates > 0 then
				table.sort(candidates, function(a, b) return a.x > b.x end)
				hl.dispatch(hl.dsp.focus({ window = "address:" .. candidates[1].addr }))
				return
			end
			hl.dispatch(hl.dsp.focus({ workspace = ws_dir }))
		else
			local pick
			for _, c in ipairs(candidates) do
				if c.x > current_x and (not pick or c.x < pick.x) then
					pick = c
				end
			end
			if pick then
				hl.dispatch(hl.dsp.focus({ window = "address:" .. pick.addr }))
				return
			end
			if #candidates > 0 then
				table.sort(candidates, function(a, b) return a.x < b.x end)
				hl.dispatch(hl.dsp.focus({ window = "address:" .. candidates[1].addr }))
				return
			end
			hl.dispatch(hl.dsp.focus({ workspace = ws_dir }))
		end
		return
	end

	local has = false
	for _, w in ipairs(Utils.windows_on_workspace(ws)) do
		local y = Utils.vec(w.at, 2)
		if (dir == "d" and y > current_y) or (dir == "u" and y < current_y) then
			has = true
			break
		end
	end
	if has then
		hl.dispatch(hl.dsp.focus({ direction = dir }))
	else
		hl.dispatch(hl.dsp.focus({ workspace = ws_dir }))
	end
end

---Dispatch layout-sensitive navigation per active workspace (LayoutKeybindDispatch.sh).
function Utils.layout_keybind_dispatch(arg)
	local function direction_word(d)
		if d == "l" or d == "left" then
			return "left"
		elseif d == "r" or d == "right" then
			return "right"
		elseif d == "u" or d == "up" then
			return "up"
		elseif d == "d" or d == "down" then
			return "down"
		end
		return "right"
	end

	local function dispatch_lua_focus(d)
		hl.dispatch(hl.dsp.focus({ direction = direction_word(d) }))
	end

	local function dispatch_changed_focus(fn)
		local before = hl.get_active_window()
		local before_addr = before and before.address
		fn()
		local after = hl.get_active_window()
		local after_addr = after and after.address
		return before_addr ~= nil and after_addr ~= nil and before_addr ~= after_addr
	end

	local function focus_wrap_horizontal(direction)
		local ws = hl.get_active_workspace()
		local active = hl.get_active_window()
		if not ws or not active then
			return false
		end
		local candidates = {}
		for _, w in ipairs(Utils.windows_on_workspace(ws)) do
			if w.address ~= active.address then
				local cx, _ = Utils.window_center(w)
				candidates[#candidates + 1] = { addr = w.address, x = cx }
			end
		end
		if #candidates == 0 then
			return false
		end
		local current_x = Utils.vec(active.at, 1)
		local pick
		if direction == "r" or direction == "right" then
			for _, c in ipairs(candidates) do
				if c.x > current_x and (not pick or c.x < pick.x) then
					pick = c
				end
			end
			if not pick then
				for _, c in ipairs(candidates) do
					if not pick or c.x < pick.x then
						pick = c
					end
				end
			end
		else
			for _, c in ipairs(candidates) do
				if c.x < current_x and (not pick or c.x > pick.x) then
					pick = c
				end
			end
			if not pick then
				for _, c in ipairs(candidates) do
					if not pick or c.x > pick.x then
						pick = c
					end
				end
			end
		end
		if pick then
			hl.dispatch(hl.dsp.focus({ window = "address:" .. pick.addr }))
			return true
		end
		return false
	end

	local function cycle_lua(mode)
		if mode == "previous" or mode == "prev" or mode == "back" then
			Utils.lua_cycle_window("previous")
		else
			Utils.lua_cycle_window("next")
		end
	end

	local function cycle_next(layout)
		if layout == "scrolling" then
			if not dispatch_changed_focus(function()
				dispatch_lua_focus("right")
			end) then
				cycle_lua("next")
			end
		else
			if not dispatch_changed_focus(function()
				hl.dispatch(hl.dsp.window.cycle_next())
			end) then
				cycle_lua("next")
			end
		end
	end

	local function cycle_prev(layout)
		if layout == "scrolling" then
			if not dispatch_changed_focus(function()
				dispatch_lua_focus("left")
			end) then
				cycle_lua("previous")
			end
		else
			cycle_lua("previous")
		end
	end

	local function focus_by_layout(layout, direction)
		if direction == "l" or direction == "r" then
			if focus_wrap_horizontal(direction) then
				return
			end
		end

		if layout == "monocle" then
			if direction == "l" or direction == "u" then
				cycle_prev(layout)
			else
				cycle_next(layout)
			end
			return
		end

		if layout == "scrolling" then
			if not dispatch_changed_focus(function()
				dispatch_lua_focus(direction)
			end) then
				dispatch_lua_focus(direction)
			end
			return
		end

		if layout == "master" or layout == "dwindle" or layout == nil then
			if not dispatch_changed_focus(function()
				dispatch_lua_focus(direction)
			end) then
				dispatch_lua_focus(direction)
			end
		end
	end

	local layout = Utils.get_active_layout()

	if arg == "cycle-next" or arg == "next" then
		cycle_next(layout)
	elseif arg == "cycle-prev" or arg == "prev" or arg == "previous" then
		cycle_prev(layout)
	elseif arg == "focus-left" or arg == "left" then
		focus_by_layout(layout, "l")
	elseif arg == "focus-right" or arg == "right" then
		focus_by_layout(layout, "r")
	elseif arg == "focus-up" or arg == "up" then
		focus_by_layout(layout, "u")
	elseif arg == "focus-down" or arg == "down" then
		focus_by_layout(layout, "d")
	elseif arg == "layout" or arg == "current-layout" or arg == "status" then
		print(layout)
	end
	return layout
end

---Toggle/init hyprsunset night-light (Hyprsunset.sh).
---Waybar status output is intentionally not ported.
function Utils.hyprsunset(mode)
	local state_file = HOME .. "/.cache/.hyprsunset_state"
	local target_temp = os.getenv("HYPRSUNSET_TEMP") or "4500"

	local function ensure_state()
		if not Utils.is_file(state_file) then
			Utils.write_file(state_file, "off")
		end
	end

	local function stop_all()
		os.execute("pkill -x hyprsunset 2>/dev/null")
		for _ = 1, 30 do
			if not Utils.process_running("hyprsunset") then
				return true
			end
			Utils.sleep(0.1)
		end
		os.execute("pkill -9 -x hyprsunset 2>/dev/null")
		for _ = 1, 30 do
			if not Utils.process_running("hyprsunset") then
				return true
			end
			Utils.sleep(0.1)
		end
		return false
	end

	local function start()
		if Utils.is_exec("hyprsunset") then
			Utils.detach("hyprsunset -t " .. tostring(target_temp))
			Utils.sleep(0.5)
		end
	end

	local function cmd_toggle()
		ensure_state()
		local state = Utils.trim(Utils.read_file(state_file) or "off")
		if state == "on" then
			stop_all()
			Utils.write_file(state_file, "off")
			Utils.notify("Hyprsunset: Disabled", "", { urgency = "low" })
		else
			if stop_all() then
				start()
				if Utils.process_running("hyprsunset") then
					Utils.write_file(state_file, "on")
					Utils.notify("Hyprsunset: Enabled", target_temp .. "K", { urgency = "low" })
				else
					Utils.notify(
						"Hyprsunset: Failed to enable",
						"No hyprsunset process is running",
						{ urgency = "critical" }
					)
				end
			else
				Utils.notify(
					"Hyprsunset: Failed to enable",
					"A previous instance would not stop",
					{ urgency = "critical" }
				)
			end
		end
	end

	local function cmd_init()
		ensure_state()
		local state = Utils.trim(Utils.read_file(state_file) or "off")
		if state == "on" then
			stop_all()
			start()
		end
	end

	if mode == "toggle" then
		cmd_toggle()
	elseif mode == "status" then
		ensure_state()
		if Utils.process_running("hyprsunset") then
			return "on"
		end
		return Utils.trim(Utils.read_file(state_file) or "off")
	elseif mode == "init" then
		cmd_init()
	end
end

---Launch a terminal with fallback chain (LaunchTerminal.sh).
---@param term string
---@param payload string|nil
function Utils.launch_terminal(term, payload)
	term = Utils.trim(term or os.getenv("TERMINAL") or "")
	payload = Utils.trim(payload or "")

	local candidates = {}
	local function append_unique(c)
		c = Utils.trim(c or "")
		if c == "" then
			return
		end
		for _, existing in ipairs(candidates) do
			if existing == c then
				return
			end
		end
		candidates[#candidates + 1] = c
	end

	append_unique(term)
	for _, c in ipairs({ "kitty", "ghostty", "alacritty", "wezterm", "konsole", "gnome-terminal" }) do
		append_unique(c)
	end

	local reported = false
	for _, candidate in ipairs(candidates) do
		local cmd = Utils.build_terminal_command(candidate, payload)
		if Utils.launch_command_string(cmd) then
			return true
		end
		if not reported and term ~= "" and candidate == term then
			local bin = Utils.command_bin(term) or ""
			if not Utils.is_exec(bin) then
				Utils.notify(
					"KooL Launchers",
					"Preferred terminal '" .. term .. "' is not installed. Falling back.",
					{ urgency = "normal" }
				)
			else
				Utils.notify(
					"KooL Launchers",
					"Preferred terminal '" .. term .. "' failed to launch. Falling back.",
					{ urgency = "normal" }
				)
			end
			reported = true
		end
	end

	if payload ~= "" then
		Utils.notify(
			"KooL Launchers",
			"Unable to launch terminal for command '" .. payload .. "'.",
			{ urgency = "critical" }
		)
	else
		Utils.notify(
			"KooL Launchers",
			"Unable to launch terminal. Install one of: kitty, ghostty, alacritty, wezterm, konsole, gnome-terminal.",
			{ urgency = "critical" }
		)
	end
	return false
end

---Build a terminal command string with a payload argument.
function Utils.build_terminal_command(term_cmd, payload)
	term_cmd = Utils.trim(term_cmd or "")
	payload = Utils.trim(payload or "")
	if payload == "" then
		return term_cmd
	end
	local bin = Utils.command_bin(term_cmd) or ""
	local q_payload = Utils.shell_quote(payload)
	if bin == "gnome-terminal" then
		return term_cmd .. " -- " .. q_payload
	elseif bin == "wezterm" then
		if term_cmd:find(" start ") or term_cmd == "wezterm start" then
			return term_cmd .. " -- " .. q_payload
		end
		return term_cmd .. " start -- " .. q_payload
	end
	return term_cmd .. " -e sh -c " .. q_payload
end

---Spawn a command string; returns true immediately (process backgrounded via &).
function Utils.launch_command_string(cmd)
	cmd = Utils.trim(cmd or "")
	if cmd == "" then
		return false
	end
	local bin = Utils.command_bin(cmd) or ""
	if not Utils.is_exec(bin) then
		return false
	end
	os.execute("sh -c " .. Utils.shell_quote(cmd .. " &> /dev/null &") .. " >/dev/null 2>&1")
	return true
end

---Launch a file manager with fallback chain (LaunchFileManager.sh).
---@param fm string|nil
---@param term string|nil
function Utils.launch_file_manager(fm, term)
	fm = Utils.trim(fm or os.getenv("FILE_MANAGER") or "")
	term = Utils.trim(term or os.getenv("TERMINAL") or "kitty")

	local terminal_fms = { "yazi", "lf", "ranger", "broot" }
	local function is_terminal_fm(cmd)
		local bin = Utils.command_bin(cmd) or ""
		for _, t in ipairs(terminal_fms) do
			if bin == t then
				return true
			end
		end
		return false
	end

	local function build_tui_payload(fm_cmd)
		local bin = Utils.command_bin(fm_cmd) or ""
		if bin == "yazi" then
			return "f=$(mktemp); "
				.. fm_cmd
				.. ' --cwd-file="$f"; cwd=$(cat "$f" 2>/dev/null); [ -n "$cwd" ] && cd -- "$cwd" 2>/dev/null; rm -f "$f"; exec "${SHELL:-bash}"'
		end
		return fm_cmd .. '; exec "${SHELL:-bash}"'
	end

	if is_terminal_fm(fm) then
		local bin = Utils.command_bin(fm) or ""
		if not Utils.is_exec(bin) then
			Utils.notify(
				"KooL Launchers",
				"Preferred file manager '" .. fm .. "' is not installed. Falling back.",
				{ urgency = "normal" }
			)
		elseif Utils.launch_terminal(term, build_tui_payload(fm)) then
			return true
		else
			Utils.notify(
				"KooL Launchers",
				"Preferred file manager '" .. fm .. "' failed to launch. Falling back.",
				{ urgency = "normal" }
			)
		end
	end

	local candidates = {}
	if not is_terminal_fm(fm) and Utils.trim(fm) ~= "" then
		candidates[#candidates + 1] = Utils.trim(fm)
	end
	for _, c in ipairs({ "thunar", "dolphin", "nautilus" }) do
		local seen = false
		for _, existing in ipairs(candidates) do
			if existing == c then
				seen = true
				break
			end
		end
		if not seen then
			candidates[#candidates + 1] = c
		end
	end

	local reported = false
	for _, candidate in ipairs(candidates) do
		if Utils.launch_command_string(candidate) then
			return true
		end
		if not reported and fm ~= "" and candidate == fm then
			local bin = Utils.command_bin(fm) or ""
			if not Utils.is_exec(bin) then
				Utils.notify(
					"KooL Launchers",
					"Preferred file manager '" .. fm .. "' is not installed. Falling back.",
					{ urgency = "normal" }
				)
			else
				Utils.notify(
					"KooL Launchers",
					"Preferred file manager '" .. fm .. "' failed to launch. Falling back.",
					{ urgency = "normal" }
				)
			end
			reported = true
		end
	end

	if Utils.is_exec("yazi") then
		if Utils.launch_terminal(term, build_tui_payload("yazi")) then
			return true
		end
	else
		Utils.notify(
			"KooL Launchers",
			"No GUI file manager was launched and 'yazi' is not installed.",
			{ urgency = "normal" }
		)
	end

	Utils.notify(
		"KooL Launchers",
		"Unable to launch file manager. Tried preferred app, thunar, dolphin, nautilus, then terminal + yazi.",
		{ urgency = "critical" }
	)
	return false
end

---Persist active workspace layout into workspaces.conf (PersistWorkspaceLayout.sh).
function Utils.persist_workspace_layout(opts)
	opts = opts or {}
	local quiet = opts.quiet
	local workspaces_file = opts.file or (HYPR_DIR .. "/workspaces.conf")

	local ws = hl.get_active_workspace()
	local function get_workspace_selector(w)
		local id = w.id
		local name = w.name
		if type(id) == "number" and id > 0 then
			return tostring(id)
		end
		if name and name ~= "" and name ~= "null" then
			if name:find("^name:") or name:find("^special:") then
				return name
			end
			return "name:" .. name
		end
		return nil
	end

	local workspace_selector = opts.workspace or (ws and get_workspace_selector(ws))
	local monitor_name = opts.monitor or (ws and ws.monitor and ws.monitor.name)
	local layout_name = opts.layout
	if not layout_name then
		if ws then
			layout_name = ws.tiled_layout
		end
		if not Utils.normalize_layout(layout_name) then
			layout_name = hl.get_config("general.layout")
		end
	end
	layout_name = Utils.normalize_layout(layout_name)
if not workspace_selector or not monitor_name or not layout_name then
		return false
	end

	local content = Utils.read_file(workspaces_file) or ""
	local lines = {}
	for line in content:gmatch("[^\n]*") do
		lines[#lines + 1] = line
	end

	local updated = false
	local out = {}
	for _, line in ipairs(lines) do
		local content_part = line
		local comment = ""
		local hash_pos = line:find("#", 1, true)
		if hash_pos then
			content_part = line:sub(1, hash_pos - 1)
			comment = line:sub(hash_pos)
		end
		local stripped = Utils.trim(content_part)
		local indent = line:match("^%s*") or ""

		if stripped:match("^workspace%s*=") then
			stripped = stripped:gsub("^workspace%s*=%s*", "")
			local tokens = {}
			for tok in stripped:gmatch("[^,]+") do
				tokens[#tokens + 1] = Utils.trim(tok)
			end
			local ws_sel = tokens[1]
			local mon = ""
			local extras = {}
			for i = 2, #tokens do
				local token = tokens[i]
				if token == "" then
					-- skip
				elseif token:match("^monitor:") then
					mon = Utils.trim(token:sub(9))
				elseif token:match("^layout:") then
					-- skip
				else
					extras[#extras + 1] = token
				end
			end
			if ws_sel == workspace_selector and mon == monitor_name then
				if not updated then
					local rebuilt = indent
						.. "workspace = "
						.. ws_sel
						.. ", monitor:"
						.. monitor_name
						.. ", layout:"
						.. layout_name
					for _, e in ipairs(extras) do
						rebuilt = rebuilt .. ", " .. e
					end
					if comment ~= "" then
						rebuilt = rebuilt .. " " .. comment
					end
					out[#out + 1] = rebuilt
					updated = true
				end
			else
				out[#out + 1] = line
			end
		else
			out[#out + 1] = line
		end
	end
	if not updated then
		out[#out + 1] = "workspace = "
			.. workspace_selector
			.. ", monitor:"
			.. monitor_name
			.. ", layout:"
			.. layout_name
	end

	local tmp_file = workspaces_file .. "." .. tostring(os.time())
	Utils.write_file(tmp_file, table.concat(out, "\n") .. "\n")
	os.execute("mv " .. Utils.shell_quote(tmp_file) .. " " .. Utils.shell_quote(workspaces_file))
	os.remove(tmp_file)

	if not quiet then
		print("Saved workspace layout: " .. workspace_selector .. " @ " .. monitor_name .. " -> " .. layout_name)
	end
	return true
end

---Switch the active workspace layout (ChangeLayout.sh).
---Accepts "dwindle"/"master"/"scrolling"/"monocle"/"toggle"/"next"/"current",
---optionally prefixed with --quiet/--no-notify.
function Utils.change_layout(input)
	input = tostring(input or "toggle")
	local quiet = false
	local args = {}
	for tok in input:gmatch("%S+") do
		if tok == "--quiet" or tok == "--no-notify" then
			quiet = true
		else
			args[#args + 1] = tok
		end
	end
	local arg = args[1] or "toggle"

	local notif = IMAGES_DIR .. "/ja.png"

	local function get_layout()
		local ws = hl.get_active_workspace()
		if ws then
			local l = Utils.normalize_layout(ws.tiled_layout)
			if l then
				return l
			end
		end
		local l = Utils.normalize_layout(hl.get_config("general.layout"))
		if l then
			return l
		end
		return "dwindle"
	end

	local function get_workspace_selector(ws)
		local id = ws.id
		local name = ws.name
		if type(id) == "number" and id > 0 then
			return tostring(id)
		end
		if name and name ~= "" and name ~= "null" then
			if name:find("^name:") or name:find("^special:") then
				return name
			end
			return "name:" .. name
		end
		return nil
	end

	local function get_workspace_label(ws)
		if ws.name and ws.name ~= "" and ws.name ~= "null" then
			return ws.name
		end
		if ws.id then
			return tostring(ws.id)
		end
		return "current"
	end

	local function set_workspace_layout_rule(target)
		local ws = hl.get_active_workspace()
		if not ws then
			return false
		end
		local selector = get_workspace_selector(ws)
		local monitor = ws.monitor and ws.monitor.name
		if not selector or not monitor then
			return false
		end
		local output = Utils.capture(
			"hyprctl keyword workspace "
				.. Utils.shell_quote(selector .. ", monitor:" .. monitor .. ", layout:" .. target)
		)
		if output:find("keyword can't work with non-legacy parsers", 1, true) then
			hl.workspace_rule({ workspace = selector, monitor = monitor, layout = target })
		else
			local normalized = Utils.trim(output:gsub("\r", ""))
			if normalized ~= "" and normalized ~= "ok" then
				return false
			end
		end
		return true
	end

	local function set_layout(target)
		local ws = hl.get_active_workspace()
		local ws_label = ws and get_workspace_label(ws) or "?"
		local monitor = ws and ws.monitor and ws.monitor.name or ""

		if not set_workspace_layout_rule(target) then
			if not quiet then
				Utils.notify("Layout switch failed: " .. target, "", { urgency = "critical", icon = notif })
			end
			return false
		end

		local attempts = 0
		local timer
		local function finish(actual)
			if timer then
				timer:set_enabled(false)
			end
			if actual == target then
				Utils.persist_workspace_layout({ quiet = true, layout = target })
				if not quiet then
					local cap = actual:sub(1, 1):upper() .. actual:sub(2)
					local label = cap .. " Layout · WS " .. ws_label
					if monitor ~= "" then
						label = label .. " @ " .. monitor
					end
					Utils.notify(label, "", { urgency = "low", icon = notif })
				end
			elseif not quiet then
				Utils.notify("Layout switch failed: still " .. actual, "", { urgency = "critical", icon = notif })
			end
		end
		timer = hl.timer(function()
			attempts = attempts + 1
			local actual = get_layout()
			if actual == target or attempts >= 15 then
				finish(actual)
			end
		end, { timeout = 30, type = "repeat" })
		return true
	end

	local function next_layout(current)
		for i, l in ipairs(LAYOUTS) do
			if l == current then
				return LAYOUTS[(i % #LAYOUTS) + 1]
			end
		end
		return LAYOUTS[1]
	end

	local current = get_layout()
	if arg == "init" then
		return true
	elseif arg == "current" or arg == "status" or arg == "get" then
		return current
	elseif arg == "toggle" or arg == "next" then
		set_layout(next_layout(current))
		return true
	elseif Utils.normalize_layout(arg) then
		set_layout(arg)
		return true
	end
	print("Usage: change_layout [--quiet|--no-notify] [toggle|next|init|current|master|dwindle|scrolling|monocle]")
	return false
end

---Pick an animation preset and install it into modules/animations.lua (Animations.sh).
---Note: writes to modules/ (was the stale configs/ path).
function Utils.animations()
	local animations_dir = HYPR_DIR .. "/animations"
	local target = HYPR_DIR .. "/modules/animations.lua"
	local ext = "lua"
	local msg = "NOTE: This will overwrite modules/animations.lua"

	local output = Utils.capture(
		"find -L " .. Utils.shell_quote(animations_dir) .. " -maxdepth 1 -type f -name '*." .. ext .. "' 2>/dev/null"
	)
	local list = {}
	for line in output:gmatch("[^\n]+") do
		local name = line:match("([^/]+)$") or line
		name = name:gsub("%." .. ext .. "$", "")
		if name ~= "" then
			list[#list + 1] = name
		end
	end
	table.sort(list)

	if #list == 0 then
		Utils.notify(
			"No animation presets found",
			"Expected *." .. ext .. " in " .. animations_dir,
			{ urgency = "normal", icon = IMAGES_DIR .. "/ja.png" }
		)
		return
	end

	Utils.pick(list, msg, function(chosen)
		if not chosen then
			return
		end
		os.execute(
			"cp "
				.. Utils.shell_quote(animations_dir .. "/" .. chosen .. "." .. ext)
				.. " "
				.. Utils.shell_quote(target)
		)
		Utils.notify(chosen, "Hyprland Animation Loaded", { urgency = "low", icon = IMAGES_DIR .. "/ja.png" })
		Utils.delayed(1000, Utils.refresh)
	end)
end

---Interactive searchable keybind display (KeyBinds.sh).
function Utils.keybinds()
	local lines = {}

	if Utils.is_exec("hyprctl") then
		local raw = Utils.capture("hyprctl binds -j")
		local data = Utils.json.decode(raw)
		if data and type(data) == "table" then
			for _, b in ipairs(data) do
				local desc = b.description
				local submap = b.submap
				if desc and desc ~= "" and (submap == nil or submap == "") then
					local key = b.key or ""
					local m = tonumber(b.modmask) or 0
					local mods = {}
					local function bit(n)
						return math.floor(m / n) % 2 >= 1
					end
					if bit(64) then
						mods[#mods + 1] = "SUPER"
					end
					if bit(1) then
						mods[#mods + 1] = "SHIFT"
					end
					if bit(4) then
						mods[#mods + 1] = "CTRL"
					end
					if bit(8) then
						mods[#mods + 1] = "ALT"
					end
					local combo
					if #mods == 0 then
						combo = key
					else
						combo = table.concat(mods, " + ") .. " + " .. key
					end
					lines[#lines + 1] = combo .. "  ::  " .. desc
				end
			end
		end
	end
	table.sort(lines, function(a, b)
		return a:lower() < b:lower()
	end)

	if #lines == 0 then
		Utils.notify("KeyBinds", "No keybinds found", { urgency = "low", icon = IMAGES_DIR .. "/ja.png" })
		return
	end
	Utils.pick(lines, "Keybinds", function() end)
end

---Determine whether an editor command is terminal-based (TUI).
function Utils.is_tui_editor(cmd)
	local parts = {}
	for tok in tostring(cmd or ""):gmatch("%S+") do
		parts[#parts + 1] = tok
	end
	if #parts == 0 then
		return false
	end
	local base = parts[1]:match("([^/]+)$") or parts[1]
	if
		base == "vi"
		or base == "vim"
		or base == "nvim"
		or base == "nano"
		or base == "hx"
		or base == "helix"
		or base == "kak"
		or base == "micro"
		or base == "emacs-nox"
	then
		return true
	end
	if base == "emacs" or base == "emacsclient" then
		for i = 2, #parts do
			local a = parts[i]
			if a == "-nw" or a == "--no-window-system" or a == "-t" or a == "--tty" then
				return true
			end
		end
		return false
	end
	return false
end

---Open a file in the configured editor (GUI or terminal-based).
function Utils.open_in_editor(file, term, edit, visual)
	local selected = (visual and visual ~= "") and visual or (edit or "nano")
	if Utils.is_tui_editor(selected) then
		os.execute(term .. " -e " .. selected .. " " .. Utils.shell_quote(file) .. " >/dev/null 2>&1 &")
	else
		os.execute(selected .. " " .. Utils.shell_quote(file) .. " >/dev/null 2>&1 &")
	end
end

---Rofi / Noctalia quick-settings menu (QuickSettings.sh).
---Dropped: stale modules/laptops.lua entry.
function Utils.quick_settings()
	local term = os.getenv("TERM") or "kitty"
	local edit = os.getenv("EDITOR") or "nano"
	local visual = os.getenv("VISUAL") or ""
	if DEFAULTS then
		if DEFAULTS.term and DEFAULTS.term ~= "" then
			term = DEFAULTS.term
		end
		if DEFAULTS.edit and DEFAULTS.edit ~= "" then
			edit = DEFAULTS.edit
		end
		if DEFAULTS.visual and DEFAULTS.visual ~= "" then
			visual = DEFAULTS.visual
		end
	end
	local msg = " Choose what to do "
	local modules = HYPR_DIR .. "/modules"

	local configs = {
		{ "Edit Defaults", modules .. "/defaults.lua" },
		{ "Edit ENV Variables", modules .. "/env.lua" },
		{ "Edit Keybinds", modules .. "/keybinds.lua" },
		{ "Edit Startup Apps", modules .. "/startup.lua" },
		{ "Edit Window Rules", modules .. "/window_rules.lua" },
		{ "Edit Layer Rules", modules .. "/layer_rules.lua" },
		{ "Edit Settings", modules .. "/settings.lua" },
		{ "Edit Decorations", modules .. "/decorations.lua" },
		{ "Edit Animations", modules .. "/animations.lua" },
		{ "Edit Monitors", modules .. "/monitors.lua" },
		{ "Edit Workspaces", modules .. "/workspaces.lua" },
	}
	local tools = {
		{ "Configure Monitors (nwg-displays)", "nwg-displays" },
		{ "GTK Settings (nwg-look)", "nwg-look" },
		{ "QT Apps Settings (qt6ct)", "qt6ct" },
		{ "QT Apps Settings (qt5ct)", "qt5ct" },
	}

	local menu = { "--- CONFIG FILES ---" }
	for _, c in ipairs(configs) do
		menu[#menu + 1] = c[1]
	end
	menu[#menu + 1] = "--- UTILITIES ---"
	for _, c in ipairs(tools) do
		menu[#menu + 1] = c[1]
	end
	menu[#menu + 1] = "Choose Hyprland Animations"
	menu[#menu + 1] = "Search for Keybinds"

	Utils.pick(menu, msg, function(choice)
		if not choice then
			return
		end
		for _, c in ipairs(configs) do
			if c[1] == choice then
				Utils.open_in_editor(c[2], term, edit, visual)
				return
			end
		end
		for _, c in ipairs(tools) do
			if c[1] == choice then
				if not Utils.is_exec(c[2]) then
					Utils.notify("E-R-R-O-R", "Install " .. c[2] .. " first", { icon = IMAGES_DIR .. "/error.png" })
				else
					Utils.detach(c[2])
				end
				return
			end
		end
		if choice == "Choose Hyprland Animations" then
			Utils.animations()
		elseif choice == "Search for Keybinds" then
			Utils.keybinds()
		end
	end)
end

-- ============================================
--  SCREENSHOTS
-- ============================================

local function screenshot_pictures_dir()
	local pictures = Utils.trim(Utils.capture("xdg-user-dir PICTURES 2>/dev/null"))
	if pictures == "" then
		pictures = HOME .. "/Pictures"
	end
	return pictures .. "/Screenshots"
end

---Screenshot suite (ScreenShot.sh). mode: --now --in5 --in10 --win --area --active --swappy
function Utils.screenshot(mode)
	mode = mode or "--now"
	local time = os.date("%d-%b_%H-%M-%S")
	local dir = screenshot_pictures_dir()
	local file = "Screenshot_" .. time .. "_" .. tostring(math.random(0, 32767)) .. ".png"
	local check_file = dir .. "/" .. file

	local active = hl.get_active_window()
	local active_window_class = active and active.class or ""
	local active_window_path = dir .. "/Screenshot_" .. time .. "_" .. active_window_class .. ".png"

	os.execute("mkdir -p " .. Utils.shell_quote(dir))

	local function take_shot(pipeline)
		os.execute("cd " .. Utils.shell_quote(dir) .. " && " .. pipeline .. " >/dev/null 2>&1")
	end

	-- notify with Open / Delete / Get Text actions (non-blocking; the 5s
	-- response wait runs detached, the result is polled here).
	local function notify_actions(title, body, icon, target, action1_handler)
		local nonce = tostring(os.time()) .. "-" .. tostring(math.random(10000, 99999))
		local out = "/tmp/hypr-lua-shot-" .. nonce .. ".out"
		local cmd = 'timeout 5 notify-send -t 10000 -A action1=Open -A action2=Delete -A "action3=Get Text"'
			.. " -h string:x-canonical-private-synchronous:shot-notify -i "
			.. Utils.shell_quote(icon)
			.. " "
			.. Utils.shell_quote(title)
			.. " "
			.. Utils.shell_quote(body)
			.. " > "
			.. out
			.. " 2>&1"
		os.execute("sh -c " .. Utils.shell_quote(cmd .. " &") .. " &")
		local tries = 0
		local timer
		timer = hl.timer(function()
			tries = tries + 1
			local resp = Utils.trim(Utils.read_file(out) or "")
			if resp ~= "" or tries > 30 then
				timer:set_enabled(false)
				os.remove(out)
				if resp == "action1" then
					if action1_handler then
						action1_handler(target)
					else
						Utils.detach("xdg-open " .. Utils.shell_quote(target))
					end
				elseif resp == "action2" then
					os.remove(target)
				elseif resp == "action3" then
					Utils.screenshot_ocr(target)
				end
			end
		end, { timeout = 200, type = "repeat" })
	end

	local function notify_view(kind)
		if kind == "active" then
			if Utils.is_file(active_window_path) then
				Utils.sounds("screenshot")
				notify_actions(
					"Screenshot of:",
					" " .. active_window_class .. " Saved.",
					ICONS_DIR .. "/picture.png",
					active_window_path
				)
			else
				Utils.notify(
					"Screenshot of:",
					" " .. active_window_class .. " NOT Saved.",
					{ urgency = "low", icon = IMAGES_DIR .. "/note.png" }
				)
				Utils.sounds("error")
			end
		elseif kind == "swappy" then
			if Utils.is_file(check_file) then
				Utils.sounds("screenshot")
				notify_actions(
					"Screenshot:",
					" Captured by Swappy",
					ICONS_DIR .. "/picture.png",
					check_file,
					function(target)
						os.execute("swappy -f - < " .. Utils.shell_quote(target))
					end
				)
			end
		elseif Utils.is_file(check_file) then
			Utils.sounds("screenshot")
			notify_actions("Screenshot", " Saved", ICONS_DIR .. "/picture.png", check_file)
		else
			Utils.notify("Screenshot", " NOT Saved", { urgency = "low", icon = IMAGES_DIR .. "/note.png" })
			Utils.sounds("error")
		end
	end

	-- interactive area capture: wayfreeze + slurp + grim run detached so the
	-- compositor stays responsive; a timer fires once the capture finished.
	local function shot_area(on_done)
		local tmpfile = "/tmp/hypr-lua-shot-area-" .. tostring(os.time()) .. "-" .. tostring(math.random(10000, 99999))
		local donefile = tmpfile .. ".done"
		local shell = "wayfreeze --hide-cursor & frozen=$!; sleep 0.2; geometry=$(slurp); "
			.. 'if [ -n "$geometry" ]; then grim -g "$geometry" - > '
			.. tmpfile
			.. "; fi; "
			.. "kill $frozen 2>/dev/null; wait $frozen 2>/dev/null; "
			.. "if [ -s "
			.. tmpfile
			.. " ]; then wl-copy < "
			.. tmpfile
			.. "; mv "
			.. tmpfile
			.. " "
			.. Utils.shell_quote(check_file)
			.. "; fi; "
			.. "echo done > "
			.. donefile
		os.execute("sh -c " .. Utils.shell_quote(shell) .. " &")
		local tries = 0
		local timer
		timer = hl.timer(function()
			tries = tries + 1
			if Utils.is_file(donefile) or tries > 600 then
				timer:set_enabled(false)
				os.remove(donefile)
				os.remove(tmpfile)
				if on_done then
					on_done()
				end
			end
		end, { timeout = 100, type = "repeat" })
	end

	local function countdown(sec, on_done)
		local remaining = sec
		local timer
		timer = hl.timer(function()
			if remaining > 0 then
				Utils.notify(
					"Taking shot",
					"in: " .. tostring(remaining) .. " secs",
					{ urgency = "normal", icon = ICONS_DIR .. "/timer.png", expire = 1000, replace = "shot-notify" }
				)
				remaining = remaining - 1
			else
				timer:set_enabled(false)
				Utils.delayed(1000, on_done)
			end
		end, { timeout = 1000, type = "repeat" })
	end

	if mode == "--now" then
		take_shot("grim - | tee " .. Utils.shell_quote(file) .. " | wl-copy")
		notify_view("default")
	elseif mode == "--in5" then
		countdown(5, function()
			take_shot("grim - | tee " .. Utils.shell_quote(file) .. " | wl-copy")
			notify_view("default")
		end)
	elseif mode == "--in10" then
		countdown(10, function()
			take_shot("grim - | tee " .. Utils.shell_quote(file) .. " | wl-copy")
			notify_view("default")
		end)
	elseif mode == "--win" then
		local aw = hl.get_active_window()
		if aw then
			local geom = Utils.vec(aw.at, 1)
				.. ","
				.. Utils.vec(aw.at, 2)
				.. " "
				.. Utils.vec(aw.size, 1)
				.. "x"
				.. Utils.vec(aw.size, 2)
			take_shot("grim -g " .. Utils.shell_quote(geom) .. " - | tee " .. Utils.shell_quote(file) .. " | wl-copy")
			notify_view("default")
		end
	elseif mode == "--area" then
		shot_area(function()
			notify_view("default")
		end)
	elseif mode == "--active" then
		local aw = hl.get_active_window()
		if aw then
			local geom = Utils.vec(aw.at, 1)
				.. ","
				.. Utils.vec(aw.at, 2)
				.. " "
				.. Utils.vec(aw.size, 1)
				.. "x"
				.. Utils.vec(aw.size, 2)
			os.execute(
				"grim -g " .. Utils.shell_quote(geom) .. " " .. Utils.shell_quote(active_window_path) .. " 2>/dev/null"
			)
			notify_view("active")
		end
	elseif mode == "--swappy" or mode == "--swapp" or mode == "--swap" then
		shot_area(function()
			notify_view("swappy")
		end)
	end
end

---Screenshot history browser via rofi (ScreenShotHistory.sh).
function Utils.screenshot_history()
	local dir = screenshot_pictures_dir()
	local rofi_config = CONFIG_HOME .. "/rofi/config.rasi"
	local rofi_theme = CONFIG_HOME .. "/rofi/config-screenshot-history.rasi"

	local function notify(msg)
		Utils.notify(
			"Screenshot History",
			msg,
			{ urgency = "low", icon = ICONS_DIR .. "/picture.png", replace = "shot-history-notify" }
		)
	end

	if not Utils.is_exec("rofi") then
		notify("rofi not found")
		return
	end
	if not Utils.is_dir(dir) then
		notify("No screenshots yet (" .. dir .. ")")
		return
	end

	local output = Utils.capture(
		"find -L "
			.. Utils.shell_quote(dir)
			.. " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \\) -printf '%T@ %p\\n' 2>/dev/null | sort -rn | cut -d' ' -f2-"
	)
	local name_to_path = {}
	local rofi_input = {}
	for line in output:gmatch("[^\n]+") do
		local path = Utils.trim(line)
		if path ~= "" then
			local name = path:match("([^/]+)$") or path
			name_to_path[name] = path
			rofi_input[#rofi_input + 1] = name .. "\0icon\x1f" .. path .. "\n"
		end
	end
	if #rofi_input == 0 then
		notify("No screenshots yet (" .. dir .. ")")
		return
	end

	local icon_size = 20
	for _, m in ipairs(hl.get_monitors() or {}) do
		if m.focused then
			local scale = tonumber(m.scale) or 1
			local height = Utils.vec(m.size, 2)
			local size = (height * 3) / (scale * 150)
			if size < 15 then
				size = 15
			elseif size > 25 then
				size = 25
			end
			icon_size = math.floor(size)
			break
		end
	end
	local rofi_override = "element-icon{size:" .. icon_size .. "%;}"

	if Utils.process_running("rofi") then
		os.execute("pkill rofi 2>/dev/null")
	end

	Utils.pick(table.concat(rofi_input), "", function(choice)
		choice = Utils.trim(choice or "")
		local path = name_to_path[choice]
		if not path or not Utils.is_file(path) then
			if choice ~= "" then
				notify("Selected screenshot not found: " .. choice)
			end
			return
		end
		local base = path:match("([^/]+)$") or path
		Utils.pick({ "Open", "Delete", "Get Text" }, base, function(action)
			if action == "Open" then
				Utils.detach("xdg-open " .. Utils.shell_quote(path))
			elseif action == "Delete" then
				os.remove(path)
				notify("Deleted " .. base)
			elseif action == "Get Text" then
				Utils.screenshot_ocr(path)
			end
		end, {
			command = "rofi",
			args = "-dmenu -i -p " .. Utils.shell_quote(base) .. " -config " .. Utils.shell_quote(rofi_config),
		})
	end, {
		command = "rofi",
		args = "-dmenu -i -config " .. Utils.shell_quote(rofi_theme) .. " -theme-str " .. Utils.shell_quote(
			rofi_override
		),
		raw = true,
	})
end

---OCR a screenshot (or the clipboard) via tesseract (ScreenShotOcr.sh).
function Utils.screenshot_ocr(image)
	local icon = ICONS_DIR .. "/picture.png"
	local function notify(msg)
		Utils.notify("OCR", msg, { urgency = "low", icon = icon, replace = "ocr-notify" })
	end

	if not Utils.is_exec("tesseract") then
		notify("tesseract not found. Install with: sudo pacman -S tesseract tesseract-data-eng")
		return
	end

	local text
	if image and image ~= "" then
		text = Utils.capture("tesseract " .. Utils.shell_quote(image) .. " stdout 2>/dev/null")
	else
		local tmpimg = os.tmpname() .. ".png"
		os.execute("wl-paste -t image/png > " .. tmpimg .. " 2>/dev/null")
		if not (os.execute("test -s " .. tmpimg .. " 2>/dev/null") == true) then
			os.remove(tmpimg)
			Utils.sounds("error")
			notify("No image in clipboard")
			return
		end
		text = Utils.capture("tesseract " .. Utils.shell_quote(tmpimg) .. " stdout 2>/dev/null")
		os.remove(tmpimg)
	end

	text = Utils.trim(text)
	if text == "" then
		Utils.sounds("error")
		notify("No text detected")
		return
	end

	local list = { "Copy ALL text", "Open in editor" }
	for line in text:gmatch("[^\n]+") do
		if Utils.trim(line) ~= "" then
			list[#list + 1] = line
		end
	end

	Utils.pick(list, "OCR Text", function(selection)
		if not selection then
			return
		end
		if selection == "Open in editor" then
			local editor = os.getenv("VISUAL") or os.getenv("EDITOR") or "nvim"
			local edit_file = os.tmpname() .. ".txt"
			Utils.write_file(edit_file, text .. "\n")
			Utils.launch_terminal("kitty", editor .. " " .. edit_file)
			Utils.sounds("screenshot")
			notify("Opened " .. #text .. " chars in " .. editor)
		elseif selection == "Copy ALL text" then
			os.execute("printf '%s\\n' " .. Utils.shell_quote(text) .. " | wl-copy")
			Utils.sounds("screenshot")
			notify("Copied " .. #text .. " chars to clipboard")
		else
			os.execute("printf '%s\\n' " .. Utils.shell_quote(selection) .. " | wl-copy")
			Utils.sounds("screenshot")
			notify("Copied " .. #text .. " chars to clipboard")
		end
	end)
end

-- ============================================
--  DROPDOWN TERMINAL (Dropterminal.sh)
-- ============================================

local DROP_SPECIAL = "special:scratchpad"
local DROP_KITTY_CLASS = "kitty-dropterm"
local MIN_TOGGLE_INTERVAL_S = 0.25
local WIDTH_PERCENT = 65
local HEIGHT_PERCENT = 65
local Y_PERCENT = 10
local SLIDE_STEPS = 12
local SLIDE_DELAY_MS = math.max(math.floor(220 / SLIDE_STEPS), 8)

local dropterm_state = {
	addr = nil,
	monitor_name = nil,
	hidden = nil,
	busy = false,
	last_toggle = 0,
	startup = false,
}

local function find_window(addr)
	for _, w in ipairs(hl.get_windows()) do
		if w.address == addr then
			return w
		end
	end
	return nil
end

local function find_terminal_by_class()
	for _, w in ipairs(hl.get_windows()) do
		if w.class == DROP_KITTY_CLASS or w.initial_class == DROP_KITTY_CLASS then
			return w.address
		end
	end
	return nil
end

local function window_workspace_name(addr)
	local w = find_window(addr)
	return w and w.workspace and w.workspace.name or ""
end

local function window_is_on_special(addr)
	local name = window_workspace_name(addr)
	return name == "special:scratchpad" or name == "scratchpad"
end

local function window_is_hidden(addr)
	local w = find_window(addr)
	if not w then
		return false
	end
	local y = Utils.vec(w.at, 2)
	local height = Utils.vec(w.size, 2)
	local mon_y = 0
	if w.monitor then
		mon_y = Utils.vec(w.monitor.position, 2)
	end
	return (y + height) <= mon_y
end

local function get_window_monitor_top(addr)
	local w = find_window(addr)
	if w and w.monitor then
		return Utils.vec(w.monitor.position, 2)
	end
	return 0
end

local function calculate_dropdown_position()
	local mon = hl.get_active_monitor()
	if not mon then
		return nil
	end
	local mon_x = Utils.vec(mon.position, 1)
	local mon_y = Utils.vec(mon.position, 2)
	local mon_width = Utils.vec(mon.size, 1)
	local mon_height = Utils.vec(mon.size, 2)
	local mon_scale = tonumber(mon.scale) or 1
	if mon_scale == 0 then
		mon_scale = 1
	end
	local mon_name = mon.name

	local logical_width = math.floor(mon_width / mon_scale)
	local logical_height = math.floor(mon_height / mon_scale)
	local width = math.floor(logical_width * WIDTH_PERCENT / 100)
	local height = math.floor(logical_height * HEIGHT_PERCENT / 100)
	local y_offset = math.floor(logical_height * Y_PERCENT / 100)
	local x_offset = math.floor((logical_width - width) / 2)
	return mon_x + x_offset, mon_y + y_offset, width, height, mon_name
end

local function dispatch_move(addr, x, y)
	hl.dispatch(hl.dsp.window.move({ window = "address:" .. addr, x = x, y = y, exact = true }))
end

local function dispatch_resize(addr, w, h)
	hl.dispatch(hl.dsp.window.resize({ window = "address:" .. addr, x = w, y = h, exact = true }))
end

local function dispatch_float(addr, action)
	hl.dispatch(hl.dsp.window.float({ window = "address:" .. addr, action = action }))
end

local function dispatch_focus(addr)
	hl.dispatch(hl.dsp.focus({ window = "address:" .. addr }))
end

local function dispatch_move_workspace(addr, ws_expr)
	hl.dispatch(hl.dsp.window.move({ window = "address:" .. addr, workspace = ws_expr, follow = false }))
end

local function animate_slide(addr, start_y, end_y, x, steps, on_done)
	dropterm_state.busy = true
	local step = 0
	local timer
	local function stop()
		if timer then
			timer:set_enabled(false)
		end
		dropterm_state.busy = false
		if on_done then
			on_done()
		end
	end
	timer = hl.timer(function()
		step = step + 1
		local current_y = start_y + math.floor((end_y - start_y) * step / steps)
		dispatch_move(addr, x, current_y)
		if step >= steps then
			dispatch_move(addr, x, end_y)
			stop()
		end
	end, { timeout = SLIDE_DELAY_MS, type = "repeat" })
end

local function set_dropdown_layout(addr)
	local x, y, w, h = calculate_dropdown_position()
	if not x then
		return false
	end
	dispatch_float(addr, "on")
	dispatch_resize(addr, w, h)
	dispatch_move(addr, x, y)
	return true
end

local function hide_terminal_silent(addr)
	local w = find_window(addr)
	local start_x = w and Utils.vec(w.at, 1) or 0
	local height = w and Utils.vec(w.size, 2) or 702
	local hidden_y = get_window_monitor_top(addr) - height - 80
	dispatch_move(addr, start_x, hidden_y)
	dispatch_move_workspace(addr, DROP_SPECIAL)
	dropterm_state.hidden = "hidden"
end

local function show_terminal()
	local addr = dropterm_state.addr
	if not addr then
		return
	end
	local ws = hl.get_active_workspace()
	local current_ws = (ws and type(ws.id) == "number" and ws.id) or 1

	local x, y, w, h = calculate_dropdown_position()
	if not x then
		dispatch_move_workspace(addr, current_ws)
		set_dropdown_layout(addr)
		dispatch_focus(addr)
		dropterm_state.hidden = "shown"
		return
	end

	local hidden_y = get_window_monitor_top(addr) - h - 80
	if window_is_on_special(addr) then
		dispatch_move_workspace(addr, current_ws)
	end
	dispatch_float(addr, "on")
	dispatch_resize(addr, w, h)
	dispatch_move(addr, x, hidden_y)
	animate_slide(addr, hidden_y, y, x, SLIDE_STEPS, function()
		dispatch_focus(addr)
		dropterm_state.hidden = "shown"
	end)
end

local function hide_terminal()
	local addr = dropterm_state.addr
	if not addr then
		return
	end
	if window_is_hidden(addr) or window_is_on_special(addr) then
		dropterm_state.hidden = "hidden"
		return
	end
	local w = find_window(addr)
	local start_x = w and Utils.vec(w.at, 1) or 0
	local start_y = w and Utils.vec(w.at, 2) or 0
	local height = w and Utils.vec(w.size, 2) or 702
	local hidden_y = get_window_monitor_top(addr) - height - 80
	animate_slide(addr, start_y, hidden_y, start_x, SLIDE_STEPS, function()
		if not window_is_hidden(addr) then
			dispatch_move_workspace(addr, DROP_SPECIAL)
		end
		dropterm_state.hidden = "hidden"
	end)
end

local function spawn_terminal(terminal_cmd)
	local x, y, w, h, mon_name = calculate_dropdown_position()
	if not x then
		x, y, w, h, mon_name = 100, 100, 800, 600, "fallback-monitor"
	end
	dropterm_state.monitor_name = mon_name

	local launch_cmd = "[workspace special:scratchpad silent;float;size "
		.. w
		.. " "
		.. h
		.. ";move "
		.. x
		.. " "
		.. y
		.. "] "
		.. terminal_cmd
	hl.dispatch(hl.dsp.exec_cmd(launch_cmd))

	local tries = 0
	local timer
	timer = hl.timer(function()
		tries = tries + 1
		local found = find_terminal_by_class()
		if found or tries >= 20 then
			timer:set_enabled(false)
			if not found then
				return
			end
			dropterm_state.addr = found
			dispatch_float(found, "on")
			dispatch_resize(found, w, h)
			dispatch_move(found, x, y)
			if dropterm_state.startup then
				hide_terminal_silent(found)
			else
				hide_terminal()
			end
		end
	end, { timeout = 100, type = "repeat" })
end

---Dropdown terminal manager (Dropterminal.sh).
---Usage: Utils.dropterminal("toggle", "kitty") | ("startup"/"init", cmd) | ("kitty")
function Utils.dropterminal(opts, terminal_cmd)
	local mode = "toggle"
	if type(opts) == "string" then
		if opts == "toggle" or opts == "startup" or opts == "init" or opts == "-d" or opts == "--debug" then
			mode = opts
		else
			terminal_cmd = opts
		end
	elseif type(opts) == "table" then
		if opts.mode then
			mode = opts.mode
		end
		if opts.terminal then
			terminal_cmd = opts.terminal
		end
	end

	dropterm_state.startup = (mode == "startup" or mode == "init")

	if
		terminal_cmd
		and terminal_cmd:match("^kitty")
		and not terminal_cmd:find("--class")
		and not terminal_cmd:find("--name")
		and not terminal_cmd:find("--app-id")
	then
		terminal_cmd = terminal_cmd .. " --class " .. DROP_KITTY_CLASS .. " --app-id " .. DROP_KITTY_CLASS
	end
	if not terminal_cmd then
		return
	end

	local now = os.time()
	if not dropterm_state.startup and (now - dropterm_state.last_toggle) < MIN_TOGGLE_INTERVAL_S then
		return
	end
	dropterm_state.last_toggle = now

	if dropterm_state.busy then
		return
	end

	local addr = nil
	if dropterm_state.addr and find_window(dropterm_state.addr) then
		addr = dropterm_state.addr
	else
		addr = find_terminal_by_class()
		dropterm_state.addr = addr
	end

	if not addr then
		spawn_terminal(terminal_cmd)
		return
	end

	if dropterm_state.startup then
		hide_terminal_silent(addr)
		return
	end

	local hidden = dropterm_state.hidden
	if hidden ~= "hidden" and hidden ~= "shown" then
		if window_is_hidden(addr) or window_is_on_special(addr) then
			hidden = "hidden"
		else
			hidden = "shown"
		end
		dropterm_state.hidden = hidden
	end

	if hidden == "hidden" then
		show_terminal()
	else
		hide_terminal()
	end
end

return Utils
