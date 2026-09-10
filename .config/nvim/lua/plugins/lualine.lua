return {
  "nvim-lualine/lualine.nvim",
  opts = function()
    -- Build a transparent variant of rose-pine for lualine:
    -- keep Normal opaque (#191724) but make the statusline's center bg
    -- transparent so the rounded outer separators ( / ) show no black corners.
    ---@type table | "auto"
    local theme = "auto"
    local ok, rose = pcall(require, "lualine.themes.rose-pine")
    if ok and type(rose) == "table" then
      theme = vim.deepcopy(rose)
      for _, mode in pairs(theme) do
        if type(mode) == "table" and mode.c then
          mode.c.bg = "NONE"
        end
      end
    end

    return {
      options = {
        theme = theme,
        globalstatus = true,
        component_separators = "",
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
        lualine_b = { "filename", "branch" },
        lualine_c = {
          "%=", --[[ add your center components here in place of this comment ]]
        },
        lualine_x = {},
        lualine_y = { "filetype", "progress" },
        lualine_z = {
          { "location", separator = { right = "" }, left_padding = 2 },
        },
      },
      inactive_sections = {
        lualine_a = { "filename" },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { "location" },
      },
      tabline = {},
      extensions = {},
    }
  end,
}
