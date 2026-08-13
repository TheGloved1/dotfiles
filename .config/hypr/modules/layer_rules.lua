local function apply_layer_rule(rule)
	if hl.layer_rule then
		hl.layer_rule(rule)
	end
end

apply_layer_rule({
	name = "layerrule-001",
	match = {
		namespace = "rofi",
	},
	blur = true,
	ignore_alpha = 0,
	animation = "slide",
})

apply_layer_rule({
	name = "layerrule-002",
	match = {
		namespace = "notifications",
	},
	blur = true,
	ignore_alpha = 0,
	animation = "slide",
})

apply_layer_rule({
	name = "layerrule-003",
	match = {
		namespace = "quickshell:overview",
	},
	blur = true,
	ignore_alpha = 0.5,
})

apply_layer_rule({
	name = "layerrule-004",
	match = {
		namespace = "wallpaper",
	},
	blur = true,
	ignore_alpha = 0,
})

apply_layer_rule({
	name = "layerrule-005",
	match = {
		namespace = "com.aurora.keybinds_help",
	},
	blur = true,
	ignore_alpha = 0,
})

apply_layer_rule({
	name = "layerrule-006",
	match = {
		namespace = "logout_dialog",
	},
	blur = true,
	ignore_alpha = 0,
})

apply_layer_rule({
	name = "noctalia",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
	},
	no_anim = true,
	ignore_alpha = 1.0,
	blur = true,
	blur_popups = true,
})
