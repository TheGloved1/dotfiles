return {
  "vyfor/cord.nvim",
  opts = {
    buttons = {
      {
        label = function(opts)
          return opts.repo_url and "View Repository" or "Website"
        end,
        url = function(opts)
          return opts.repo_url or "https://gloved.dev"
        end,
      },
    },
    idle = {
      smart_idle = false,
      timeout = 300000,
      ignore_focus = true,
      details = "Idle",
      tooltip = "💤",
    },
    display = {
      theme = "catppuccin",
      flavor = "accent",
    },
  },
  config = function(_, opts)
    require("cord").setup(opts)

    local idle_timeout = 120000
    local is_idle = false
    local timer

    local function enter_idle()
      if is_idle then
        return
      end
      is_idle = true
      vim.cmd("Cord idle show")
    end

    local function leave_idle()
      if not is_idle then
        return
      end
      is_idle = false
      vim.cmd("Cord idle hide")
    end

    local function reset_timer()
      leave_idle()
      if timer then
        pcall(timer.close, timer)
      end
      timer = vim.defer_fn(enter_idle, idle_timeout)
    end

    local group = vim.api.nvim_create_augroup("cord_custom_idle", { clear = true })
    vim.api.nvim_create_autocmd(
      { "CursorMoved", "CursorMovedI", "InsertCharPre", "FocusGained", "BufWritePost" },
      { group = group, callback = reset_timer }
    )

    reset_timer()
  end,
}
