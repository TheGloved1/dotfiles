---@param rule table Layer rule table for hl.layer_rule()
local function apply_layer_rule(rule)
  if hl.layer_rule then
    hl.layer_rule(rule)
  end
end

return {
  apply_layer_rule = apply_layer_rule,
}
