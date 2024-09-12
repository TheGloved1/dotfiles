-- No example configuration was found for this plugin.
--
-- For detailed information on configuring this plugin, please refer to its
-- official documentation:
--
--   https://github.com/edluffy/specs.nvim
--
-- If you wish to use this plugin, you can optionally modify and then uncomment
-- the configuration below.

return {
  'edluffy/specs.nvim',
  lazy = true,
  opts = function()
    local specs = require 'specs'
    specs.setup {
      show_jumps = true,
      min_jump = 5,
      popup = {
        delay_ms = 800, -- delay before popup displays
        inc_ms = 800, -- time increments used for fade/resize effects
        blend = 0, -- starting blend, between 0-100 (fully transparent), see :h winblend
        width = 20,
        winhl = 'PMenu',
        fader = specs.sinus_fader,
        resizer = specs.slide_resizer,
      },
      ignore_filetypes = {},
      ignore_buftypes = {
        nofile = true,
      },
    }
  end,
}
