 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1b1a23',
    base01 = '#2e2b3b',
    base02 = '#292636',
    base03 = '#686474',
    base04 = '#b0afb6',
    base05 = '#f2f2f3',
    base06 = '#f2f2f3',
    base07 = '#f2f2f3',
    base08 = '#fd4663',
    base09 = '#cbafc6',
    base0A = '#c3adcd',
    base0B = '#b0a9d1',
    base0C = '#d0afca',
    base0D = '#b3acd3',
    base0E = '#c5afd0',
    base0F = '#741d2b',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f2f3',          bg = '#1b1a23' })
  hi('TelescopeBorder',         { fg = '#686474',             bg = '#1b1a23' })
  hi('TelescopePromptNormal',   { fg = '#f2f2f3',          bg = '#1b1a23' })
  hi('TelescopePromptBorder',   { fg = '#686474',             bg = '#1b1a23' })
  hi('TelescopePromptPrefix',   { fg = '#b0a9d1',             bg = '#1b1a23' })
  hi('TelescopePromptCounter',  { fg = '#b0afb6',  bg = '#1b1a23' })
  hi('TelescopePromptTitle',    { fg = '#1b1a23',             bg = '#b0a9d1' })
  hi('TelescopePreviewTitle',   { fg = '#1b1a23',             bg = '#c3adcd' })
  hi('TelescopeResultsTitle',   { fg = '#1b1a23',             bg = '#cbafc6' })
  hi('TelescopeSelection',      { fg = '#f2f2f3',          bg = '#292636' })
  hi('TelescopeSelectionCaret', { fg = '#b0a9d1',             bg = '#292636' })
  hi('TelescopeMatching',       { fg = '#b0a9d1',             bold = true })
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
