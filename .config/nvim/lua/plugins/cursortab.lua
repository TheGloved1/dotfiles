return {
  "cursortab/cursortab.nvim",
  lazy = false,
  build = "cd server && go build",
  opts = {
    provider = {
      -- Mercury API (hosted)
      type = "mercuryapi",
      api_key_env = "MERCURY_AI_TOKEN",
    },
    keymaps = {
      accept = "<Tab>", -- Keymap to accept completion, or false to disable
      partial_accept = "<S-Tab>", -- Keymap to partially accept, or false to disable
      trigger = false, -- Keymap to manually trigger completion, or false to disable
    },
    ui = {
      completions = {
        addition_style = "dimmed", -- "dimmed" or "highlight"
        fg_opacity = 0.6, -- opacity for completion overlays (0=invisible, 1=fully visible)
      },
      jump = {
        symbol = "", -- Symbol shown for jump points
        text = " TAB ", -- Text displayed after jump symbol
        show_distance = true, -- Show line distance for off-screen jumps
      },
    },
    behavior = {
      text_change_debounce = 10,
      idle_completion_delay = -1,
      max_visible_lines = 8,
      ignore_gitignored = false,
      cursor_prediction = {
        enabled = true, -- Show jump indicators after completions
        auto_advance = true, -- When no changes, show cursor jump to last line
        proximity_threshold = 2, -- Min lines apart to show cursor jump (0 to disable)
      },
    },
    blink = {
      enabled = true, -- Enable blink source
      ghost_text = true, -- Show native ghost text alongside blink menu
    },
  },
}
