-- NOTE: Used for wrapping diagnostic messages in visible editor
-- Check added keymapping <lm> in lua/plugins/astrocore.lua for messages that still do not fit

-- lua/plugins/tiny-inline-diagnostic.lua
return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  config = function()
    require("tiny-inline-diagnostic").setup()
    vim.diagnostic.config { virtual_text = false } -- avoid showing both
  end,
}
