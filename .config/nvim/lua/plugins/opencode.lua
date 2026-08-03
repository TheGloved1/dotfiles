return {
  "nickjvandyke/opencode.nvim",
  version = "*", -- Latest stable release
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any; goto definition on the type for details
    }

    local map = vim.keymap.set
    local opencode = require("opencode")

    -- Recommended/example keymaps
    map({ "n", "x" }, "<leader>oa", function()
      opencode.ask("@this: ")
    end, { desc = "Ask OpenCode…" })
    map({ "n", "x" }, "<leader>os", function()
      opencode.select()
    end, { desc = "Select OpenCode…" })
    map({ "n", "x" }, "<leader>or", function()
      return opencode.operator("@this ")
    end, { desc = "Append range to OpenCode", expr = true })
    map({ "n" }, "<leader>ol", function()
      return opencode.operator("@this ") .. "_"
    end, { desc = "Append line to OpenCode", expr = true })
    map({ "n" }, "<leader>ou", function()
      opencode.command("session.half.page.up")
    end, { desc = "Scroll OpenCode up" })
    map({ "n" }, "<leader>od", function()
      opencode.command("session.half.page.down")
    end, { desc = "Scroll OpenCode down" })

    -- Additional OpenCode commands
    map({ "n" }, "<leader>oc", function()
      opencode.command("agent.cycle")
    end, { desc = "Cycle agent" })
    map({ "n" }, "<leader>opc", function()
      opencode.command("prompt.clear")
    end, { desc = "Clear prompt" })
    map({ "n" }, "<leader>ops", function()
      opencode.command("prompt.submit")
    end, { desc = "Submit prompt" })
    map({ "n" }, "<leader>osq", function()
      opencode.command("session.compact")
    end, { desc = "Compact session" })
    map({ "n" }, "<leader>o<<", function()
      opencode.command("session.first")
    end, { desc = "First message" })
    map({ "n" }, "<leader>o>>", function()
      opencode.command("session.last")
    end, { desc = "Last message" })
    map({ "n" }, "<leader>oi", function()
      opencode.command("session.interrupt")
    end, { desc = "Interrupt session" })
    map({ "n" }, "<leader>on", function()
      opencode.command("session.new")
    end, { desc = "New session" })
    map({ "n" }, "<leader>o<C-u>", function()
      opencode.command("session.page.up")
    end, { desc = "Page up" })
    map({ "n" }, "<leader>o<C-d>", function()
      opencode.command("session.page.down")
    end, { desc = "Page down" })
    map({ "n" }, "<leader>oe", function()
      opencode.command("session.select")
    end, { desc = "Select session" })
    map({ "n" }, "<leader>osh", function()
      opencode.command("session.share")
    end, { desc = "Share session" })
    map({ "n" }, "<leader>oz", function()
      opencode.command("session.undo")
    end, { desc = "Undo last action" })
    map({ "n" }, "<leader>oZ", function()
      opencode.command("session.redo")
    end, { desc = "Redo last action" })
  end,
}
