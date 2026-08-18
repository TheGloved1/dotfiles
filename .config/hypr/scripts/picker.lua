-- Interactive picker (Noctalia dmenu by default). Async; the
-- selection is delivered to `cb` (nil when the picker was cancelled).
-- Uses hl.dsp.exec_cmd for proper Wayland environment.

local M = {}

---@param items table|string list of choices, or raw input when opts.raw
---@param prompt string
---@param cb function|nil receives selected string or nil on cancel
---@param opts table|nil {command, args, raw, prompt_arg}
function M.pick(items, prompt, cb, opts)
	opts = opts or {}
	local command = opts.command or "noctalia dmenu"
	local script = "/home/gloves/.config/hypr/scripts/picker.sh"

	local nonce = tostring(os.time()) .. "-" .. tostring(math.random(10000, 99999))
	local input = "/tmp/hypr-lua-pick-" .. nonce .. ".in"
	local output = "/tmp/hypr-lua-pick-" .. nonce .. ".out"

	local content = opts.raw and tostring(items)
		or (type(items) == "table" and (table.concat(items, "\n") .. "\n") or tostring(items))

	if not Utils.write_file(input, content) then
		if cb then
			cb(nil)
		end
		return
	end

	-- Build script args
	local script_args = { command }
	if opts.prompt_arg ~= false and prompt ~= "" then
		script_args[#script_args + 1] = prompt
	end

	-- Use hl.dsp.exec_cmd to run the picker with proper Wayland env
	-- The script reads from stdin and writes selection to stdout
	local cmd = string.format(
		"sh -c 'printf %%s %s | %s %s < %s > %s'",
		Utils.shell_quote(content),
		script,
		table.concat(script_args, " "),
		Utils.shell_quote(input),
		Utils.shell_quote(output)
	)

	hl.dispatch(hl.dsp.exec_cmd(cmd))

	-- Poll for completion
	local tries = 0
	local timer
	local function finish()
		if timer then
			timer:set_enabled(false)
		end
		os.remove(input)
		os.remove(output)
	end

	timer = hl.timer(function()
		tries = tries + 1
		if tries > 600 then -- 60 second timeout
			finish()
			if cb then
				cb(nil)
			end
			return
		end
		local sel = Utils.trim(Utils.read_file(output) or "")
		if sel ~= "" then
			finish()
			if cb then
				cb(sel)
			end
			return
		end
	end, { timeout = 100, type = "repeat" })
end

Utils.pick = M.pick
return M
