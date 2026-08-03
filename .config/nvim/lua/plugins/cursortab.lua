return {
  "cursortab/cursortab.nvim",
  lazy = false,
  build = "cd server && go build",
  opts = {
    provider = {
      type = "windsurf",
    },
    behavior = {
      text_change_debounce = 10,
      idle_completion_delay = -1,
      max_visible_lines = 8,
    },
  },
}
