-- Workspace rules: assign specific layouts to workspaces.
-- Default layout is "scrolling" (set in settings.lua).
-- These rules ensure workspaces 4-6 explicitly use scrolling.

hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", layout = "scrolling" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", layout = "scrolling" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", layout = "scrolling" })
