 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#131315',
    base01 = '#1f1f21',
    base02 = '#2a2a2c',
    base03 = '#909098',
    base04 = '#c6c6ce',
    base05 = '#e5e2e4',
    base06 = '#e5e2e4',
    base07 = '#e5e2e4',
    base08 = '#ffb4ab',
    base09 = '#ebc6e0',
    base0A = '#c5c5d3',
    base0B = '#cacfee',
    base0C = '#e0bcd6',
    base0D = '#bfc5e4',
    base0E = '#c5c5d3',
    base0F = '#93000a',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#e5e2e4',          bg = '#131315' })
  hi('TelescopeBorder',         { fg = '#909098',             bg = '#131315' })
  hi('TelescopePromptNormal',   { fg = '#e5e2e4',          bg = '#131315' })
  hi('TelescopePromptBorder',   { fg = '#909098',             bg = '#131315' })
  hi('TelescopePromptPrefix',   { fg = '#cacfee',             bg = '#131315' })
  hi('TelescopePromptCounter',  { fg = '#c6c6ce',  bg = '#131315' })
  hi('TelescopePromptTitle',    { fg = '#131315',             bg = '#cacfee' })
  hi('TelescopePreviewTitle',   { fg = '#131315',             bg = '#c5c5d3' })
  hi('TelescopeResultsTitle',   { fg = '#131315',             bg = '#ebc6e0' })
  hi('TelescopeSelection',      { fg = '#e5e2e4',          bg = '#2a2a2c' })
  hi('TelescopeSelectionCaret', { fg = '#cacfee',             bg = '#2a2a2c' })
  hi('TelescopeMatching',       { fg = '#cacfee',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
