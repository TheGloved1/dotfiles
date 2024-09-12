-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  'AstroNvim/astrocommunity',
  -- Pack
  { import = 'astrocommunity.pack.lua' },
  { import = 'astrocommunity.pack.tailwindcss' },
  { import = 'astrocommunity.pack.typescript-all-in-one' },
  -- LSP
  { import = 'astrocommunity.lsp.lsp-lens-nvim' },
  -- Diagnostics
  { import = 'astrocommunity.diagnostics.trouble-nvim' },
  { import = 'astrocommunity.diagnostics.lsp_lines-nvim' },
  -- Completion
  { import = 'astrocommunity.completion.copilot-lua' },
  { import = 'astrocommunity.completion.copilot-lua-cmp' },
  { import = 'astrocommunity.completion.coq_nvim' },
  -- Keybinding
  { import = 'astrocommunity.keybinding.mini-clue' },
  -- Colorscheme
  { import = 'astrocommunity.colorscheme.tokyonight-nvim' },
  { import = 'astrocommunity.colorscheme.monokai-pro-nvim' },
  { import = 'astrocommunity.colorscheme.onedarkpro-nvim' },
  { import = 'astrocommunity.colorscheme.vscode-nvim' },
  { import = 'astrocommunity.colorscheme.github-nvim-theme' },
  -- Recipes
  { import = 'astrocommunity.recipes.heirline-vscode-winbar' },
  { import = 'astrocommunity.recipes.telescope-nvchad-theme' },
  { import = 'astrocommunity.recipes.neovide' },
  { import = 'astrocommunity.recipes.vscode-icons' },
  -- Editing
  { import = 'astrocommunity.editing-support.undotree' },
  { import = 'astrocommunity.editing-support.vim-visual-multi' },
  { import = 'astrocommunity.editing-support.auto-save-nvim' },
  -- File Explorer
  { import = 'astrocommunity.file-explorer.telescope-file-browser-nvim' },
  -- Utility
  { import = 'astrocommunity.utility.noice-nvim' },
  { import = 'astrocommunity.utility.nvim-toggler' },
  -- Motion
  { import = 'astrocommunity.motion.hop-nvim' },
  { import = 'astrocommunity.motion.harpoon' },
  { import = 'astrocommunity.motion.vim-matchup' },
  { import = 'astrocommunity.motion.mini-ai' },
  { import = 'astrocommunity.motion.nvim-surround' },
  -- Media
  { import = 'astrocommunity.media.presence-nvim' },
  -- Fuzzy Finder
  { import = 'astrocommunity.fuzzy-finder.telescope-zoxide' },
  -- Markdown
  { import = 'astrocommunity.markdown-and-latex.glow-nvim' },

  -- Other
  { import = 'astrocommunity.register.nvim-neoclip-lua' },
  { import = 'astrocommunity.git.mini-git' },
  -- { import = "astrocommunity." },
  -- import/override with your plugins folder
}
