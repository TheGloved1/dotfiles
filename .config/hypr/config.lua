-- Shared path constants (HYPR_BASE_DIR is set by hyprland.lua).
HYPR_DIR = HYPR_BASE_DIR
CONFIGS_DIR = HYPR_DIR .. "/configs"
SCRIPTS_DIR = HYPR_DIR .. "/scripts"
WALLUST_FILE = HYPR_DIR .. "/wallust/wallust-hyprland.lua"
WALLUST = require("wallust.wallust-hyprland")

local function has_kvantum_qml_module()
	local cmd = "find /usr/lib /usr/lib64 /usr/share -type d -path '*/qml/*/kvantum' -print -quit 2>/dev/null"
	local pipe = io.popen(cmd, "r")
	if not pipe then
		return false
	end
	local output = pipe:read("*a") or ""
	pipe:close()
	return output:match("%S") ~= nil
end

local function apply_qt_style_fallbacks()
	if not hl or not hl.env then
		return
	end

	if has_kvantum_qml_module() then
		return
	end

	local style_override = (os.getenv("QT_STYLE_OVERRIDE") or ""):lower()
	if style_override == "kvantum" or style_override == "kvantum-dark" then
		hl.env("QT_STYLE_OVERRIDE", "Fusion")
	end

	local quick_controls = (os.getenv("QT_QUICK_CONTROLS_STYLE") or ""):lower()
	if quick_controls == "kvantum" then
		hl.env("QT_QUICK_CONTROLS_STYLE", "Basic")
	end
end

---Load lua files
---@param path string path to file
---@return boolean
local function load_optional(path)
	local ok, err = pcall(dofile, path)
	if ok then
		return true
	end
	if err and tostring(err):find("No such file or directory", 1, true) == nil then
		print("[WARN] Unable to load " .. path .. ": " .. tostring(err))
	end
	return false
end

---Scan for lua files
---@param dir string Dir to search in
---@return table files
local function scan_lua_files(dir)
	local files = {}
	local pipe = io.popen('ls -1 "' .. dir .. '" 2>/dev/null', "r")
	if not pipe then
		return files
	end
	for line in pipe:lines() do
		if line:match("%.lua$") then
			files[#files + 1] = line
		end
	end
	pipe:close()
	table.sort(files)
	return files
end

---Load lua config files
---@param file string
for i, file in ipairs(scan_lua_files(CONFIGS_DIR)) do
	load_optional(CONFIGS_DIR .. "/" .. file)
end

apply_qt_style_fallbacks()
