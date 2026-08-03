local function apply_layer_rule(rule)
  if hl.layer_rule then
    hl.layer_rule(rule)
  end
end

return {
  apply_layer_rule = apply_layer_rule,
}
