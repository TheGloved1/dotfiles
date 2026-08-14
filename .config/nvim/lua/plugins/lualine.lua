return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    opts.options.section_separators = { left = "", right = "" }
    opts.options.component_separators = { left = "", right = "" }
    opts.sections.lualine_a[1] = { "mode", separator = { left = "" } }
    local z = opts.sections.lualine_z[#opts.sections.lualine_z]
    opts.sections.lualine_z[#opts.sections.lualine_z] = { z, separator = { right = "" } }
    return opts
  end,
}