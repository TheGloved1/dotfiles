-- Shared path constants (HYPR_BASE_DIR is set by hyprland.lua).
HYPR_DIR = HYPR_BASE_DIR
CONFIGS_DIR = HYPR_DIR .. "/configs"
SCRIPTS_DIR = HYPR_DIR .. "/scripts"
COLORS = require("wallust.wallust-hyprland")

local kvantum_checked = false
local kvantum_found = false

local function has_kvantum_qml_module()
	if kvantum_checked then
		return kvantum_found
	end
	kvantum_checked = true

	-- Only scan real Qt QML roots instead of the whole /usr tree.
	local cmd = "for d in /usr/lib/qt6/qml /usr/lib/qt5/qml /usr/lib/qt/qml "
		.. "/usr/lib64/qt6/qml /usr/lib64/qt5/qml /usr/lib64/qt/qml "
		.. "/usr/share/qt6/qml /usr/share/qt5/qml "
		.. "/usr/local/lib/qt6/qml /usr/local/lib/qt5/qml; do "
		.. '[ -d "$d" ] || continue; find "$d" -type d -path \'*/kvantum\' -print -quit 2>/dev/null && break; done'
	local pipe = io.popen(cmd, "r")
	if not pipe then
		return false
	end
	local output = pipe:read("*a") or ""
	pipe:close()
	kvantum_found = output:match("%S") ~= nil
	return kvantum_found
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
