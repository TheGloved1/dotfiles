---@param rule table Window rule table for hl.window_rule()
local function apply_window_rule(rule)
	if hl.window_rule then
		hl.window_rule(rule)
	end
end

return {
	apply_window_rule = apply_window_rule,
}
