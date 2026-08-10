-- Mango — replicate mangowm's default animation feel.
--
-- Curves & timings from ~/git/mango (src/config/parse_config.h set_value_default)
-- and the DreamMaoMao/mango-config demo (config.conf):
--   open   slide + fade, 400ms, curve 0.46,1.0,0.29,1.1  (slight overshoot)
--   close  slide + fade, 800ms, curve 0.08,0.92,0,1      (slow ease-out)
--   move   glide,        500ms, curve 0.46,1.0,0.29,1
--   tag    slide,        350ms, curve 0.46,1.0,0.29,1
--   focus  opacity/border,400ms,curve 0.46,1.0,0.29,1
--   fadein / fadeout from 80%: 0.46,1.0,0.29,1 / 0.58,0.98,0.58,0.98
--
-- hyprland speed = duration in ds (1ds = 100ms): 500->5, 400->4, 350->3.5, 800->8

hl.config({
  animations = {
    enabled = true,
    workspace_wraparound = true,
  },
})

hl.curve("mango", { type = "bezier", points = { { 0.46, 1.0 }, { 0.29, 1.0 } } })
hl.curve("mango_open", { type = "bezier", points = { { 0.46, 1.0 }, { 0.29, 1.1 } } })
hl.curve("mango_close", { type = "bezier", points = { { 0.08, 0.92 }, { 0, 1 } } })
hl.curve("mango_fadeout", { type = "bezier", points = { { 0.58, 0.98 }, { 0.58, 0.98 } } })
hl.curve("linear", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

-- windows: slide in/out from the right, glide on move (500ms), slow slide out (800ms)
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "mango", style = "slide right" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "mango_open", style = "slide right" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 8, bezier = "mango_close", style = "slide right" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "mango", style = "slide" })

-- fade in/out on open/close, focus opacity transition (mango dims unfocused to 0.85)
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "mango" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "mango" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 8, bezier = "mango_fadeout" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "mango" })

-- tag switch: vertical direction-aware slide (350ms)
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "mango", style = "slidevert" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3.5, bezier = "mango", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "mango", style = "slidevert" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "mango", style = "slidevert" })

-- layer surfaces (bars, notifications): slide
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "mango", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "mango", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 8, bezier = "mango_close", style = "slide" })

-- border color on focus (400ms), angle for rainbow borders
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "mango" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })

-- root default for any unset leaves
hl.animation({ leaf = "global", enabled = true, speed = 5, bezier = "mango" })
