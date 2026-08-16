-- Vertical variant of amitpadhan
-- Inspired by amitpadhan525
-- https://github.com/amitpadhan525

hl.config({
	animations = {
		enabled = true,
	},
})

--- 0.34, 1.56, 0.64, 1
--- 0.16, 1, 0.3, 1
--- 0.68, -0.6, 0.32, 1.6
--- 0.45, 0, 0.55, 1
hl.curve("smooth", { type = "bezier", points = { { 0.45, 0 }, { 0.32, 1 } } })
hl.curve("overshoot", { type = "bezier", points = { { 0.5, 0.9 }, { 0.1, 1.1 } } })
hl.curve("rubber", { type = "spring", mass = 0.51, stiffness = 70, dampening = 10 })

hl.animation({ leaf = "windows", enabled = true, speed = 2, spring = "rubber" })
-- hl.animation({ leaf = "windowsIn", enabled = true, speed = 2, spring = "rubber" })
-- hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, spring = "rubber" })
-- hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, spring = "rubber" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, spring = "rubber" })
-- hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "smooth" })
-- hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "smooth" })
hl.animation({ leaf = "border", enabled = true, speed = 5, spring = "rubber" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, spring = "rubber" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, spring = "rubber" })
-- hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 5, bezier = "default" })
-- hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, spring = "rubber", style = "slidevert 20%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, spring = "rubber", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2, spring = "rubber", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, spring = "rubber", style = "slidevert" })
