return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = true,
    event = "VeryLazy",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-telescope/telescope.nvim" },
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    opts = {

      debug = false,
      show_help = true,
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
}
