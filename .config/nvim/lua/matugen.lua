 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a2322',
    base01 = '#2b3b38',
    base02 = '#263633',
    base03 = '#5e6e6c',
    base04 = '#afb6b5',
    base05 = '#f2f3f3',
    base06 = '#f2f3f3',
    base07 = '#f2f3f3',
    base08 = '#fd4663',
    base09 = '#707ec2',
    base0A = '#6ba8c7',
    base0B = '#75d7c6',
    base0C = '#a6aed9',
    base0D = '#a1ded3',
    base0E = '#a3c9dc',
    base0F = '#741d2b',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f2f3f3',          bg = '#1a2322' })
  hi('TelescopeBorder',         { fg = '#5e6e6c',             bg = '#1a2322' })
  hi('TelescopePromptNormal',   { fg = '#f2f3f3',          bg = '#1a2322' })
  hi('TelescopePromptBorder',   { fg = '#5e6e6c',             bg = '#1a2322' })
  hi('TelescopePromptPrefix',   { fg = '#75d7c6',             bg = '#1a2322' })
  hi('TelescopePromptCounter',  { fg = '#afb6b5',  bg = '#1a2322' })
  hi('TelescopePromptTitle',    { fg = '#1a2322',             bg = '#75d7c6' })
  hi('TelescopePreviewTitle',   { fg = '#1a2322',             bg = '#6ba8c7' })
  hi('TelescopeResultsTitle',   { fg = '#1a2322',             bg = '#707ec2' })
  hi('TelescopeSelection',      { fg = '#f2f3f3',          bg = '#263633' })
  hi('TelescopeSelectionCaret', { fg = '#75d7c6',             bg = '#263633' })
  hi('TelescopeMatching',       { fg = '#75d7c6',             bold = true })
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
