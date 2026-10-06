-- NOTE: Added below for function call selection keybindings (select entire and just
-- args)
--if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true, -- enable/disable treesitter based highlighting
      indent = true, -- enable/disable treesitter based indentation
      auto_install = true, -- enable/disable automatic installation of detected languages
      ensure_installed = {
        "lua",
        "vim",
        -- add more arguments for adding more treesitter parsers
      },
      textobjects = {
        select = {
          select_textobject = {
            ["aF"] = { query = "@call.outer", desc = "around function call" },
            --["iF"] = { query = "@call.inner", desc = "inside function call (args)" },
            --["iF"] = { query = "@call.args", desc = "inside call (all args)" },
          },
        },
      },
    },
    mappings = {
      x = { iF = { function() require("user.call_args").select() end, desc = "inside call (all args)" } },
      o = { iF = { function() require("user.call_args").select() end, desc = "inside call (all args)" } },
    },
  },
}
