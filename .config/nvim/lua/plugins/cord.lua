return {
  "vyfor/cord.nvim",
  opts = {
    buttons = {
      {
        label = function(opts)
          return opts.repo_url and "View Repository" or "Website"
        end,
        url = function(opts)
          return opts.repo_url or "https://github.com/TheGloved1"
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
      -- theme = "catppuccin",
      -- flavor = "accent",
    },
    text = {
      workspace = function(opts)
        -- Use cwd / project root basename instead of file's parent folder
        -- e.g. `In nvim` when cwd is ~/.config/nvim even if file is in plugins/
        local cwd = vim.fn.getcwd()
        local project = vim.fn.fnamemodify(cwd, ":t")
        -- fallback: use detected workspace or cwd full path if basename empty (e.g. cwd == "/")
        if project == "" or project == "." then
          project = opts.workspace or cwd
        end
        -- if cwd is "/" or ".", prefer workspace_dir basename
        if (project == "" or project == "/") and opts.workspace_dir then
          project = vim.fn.fnamemodify(opts.workspace_dir, ":t")
        end
        return "In " .. project
      end,
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
