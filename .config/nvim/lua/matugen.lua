 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a1c23',
    base01 = '#2b2f3b',
    base02 = '#262a36',
    base03 = '#636772',
    base04 = '#afb1b6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#a382b0',
    base0A = '#8c81b1',
    base0B = '#8b9ac1',
    base0C = '#c6afd0',
    base0D = '#acb7d3',
    base0E = '#b6afd0',
    base0F = '#741d2b',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#1a1c23' })
  hi('TelescopeBorder',         { fg = '#636772',             bg = '#1a1c23' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#1a1c23' })
  hi('TelescopePromptBorder',   { fg = '#636772',             bg = '#1a1c23' })
  hi('TelescopePromptPrefix',   { fg = '#8b9ac1',             bg = '#1a1c23' })
  hi('TelescopePromptCounter',  { fg = '#afb1b6',  bg = '#1a1c23' })
  hi('TelescopePromptTitle',    { fg = '#1a1c23',             bg = '#8b9ac1' })
  hi('TelescopePreviewTitle',   { fg = '#1a1c23',             bg = '#8c81b1' })
  hi('TelescopeResultsTitle',   { fg = '#1a1c23',             bg = '#a382b0' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#262a36' })
  hi('TelescopeSelectionCaret', { fg = '#8b9ac1',             bg = '#262a36' })
  hi('TelescopeMatching',       { fg = '#8b9ac1',             bold = true })
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
