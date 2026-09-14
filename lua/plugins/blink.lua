-- lua/plugins/blink.lua
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<C-i>"] = { "show", "show_documentation", "hide_documentation" },
        -- remove or leave <C-space> default entry if you want to drop it entirely
      },
    },
  },
}
