-- Dynamic cursor plugin configuration
if hl.plugin.dynamic_cursors then
	hl.config({
		plugin = {
			dynamic_cursors = {
				enabled = true,
				mode = "tilt",
				threshold = 2,
				rotate = {
					length = 24,
					offset = 0.0,
				},
				tilt = {
					limit = 5000,
					activation = "negative_quadratic",
					window = 100,
					full = 120,
				},
				stretch = {
					limit = 3000,
					activation = "quadratic",
					window = 100,
				},
				shake = {
					enabled = false,
					threshold = 6.0,
					base = 4.0,
					speed = 4.0,
					influence = 0.0,
					limit = 0.0,
					timeout = 2000,
					effects = false,
					ipc = false,
				},
				hyprcursor = {
					nearest = 1,
					enabled = true,
					resolution = -1,
					fallback = "clientside",
				},
			},
		},
	})
end

if hl.plugin.hyprglass then
	local hg = hl.plugin.hyprglass
	local function tint(c, alpha)
		return tonumber(c:match("%x%x%x%x%x%x"), 16) * 256 + math.floor(alpha * 255 + 0.5)
	end

	hg.config({
		enabled = false,
		default_theme = "dark",
		default_preset = "glass",
		layers = { enabled = true },
	})

	-- Layer surfaces: each call whitelists the namespace and configures it
	hg.layer("noctalia")

	-- Presets
	hg.preset("clear", {
		glass_opacity = 0.8,
		blur_strength = 1.5,
		dark = { brightness = 0.7 },
		light = { brightness = 1.2 },
	})

	hg.preset("contrasted", {
		inherits = "high_contrast",
		contrast = 1.2,
		adaptive_dim = 1.5,
		dark = { tint_color = 0x02142aa9 },
	})

	hg.preset("glass", {
		blur_strength = 2.0,
		blur_iterations = 3,
		chromatic_aberration = 0.6,
		fresnel_strength = 0.8,
		edge_thickness = 0.04,
		int_color = tint(Noctalia.colors.primary, 0.12),
		lens_distortion = 0.9,
		brightness = 1.0,
		contrast = 1.7,
		saturation = 1,
		vibrancy = 0.8,
		vibrancy_darkness = 1,
		adaptive_boost = 0.5,
	})

	hg.preset("apple", {
		blur_strength = 2.2,
		blur_iterations = 3,
		refraction_strength = 0.55,
		chromatic_aberration = 0.3,
		fresnel_strength = 0.5,
		specular_strength = 0.75,
		edge_thickness = 0.05,
		lens_distortion = 0.3,
		brightness = 0.82,
		contrast = 0.90,
		saturation = 0.80,
		vibrancy = 0.15,
		adaptive_dim = 0.4,
	})
end
