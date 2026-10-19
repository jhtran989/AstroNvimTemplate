-- lua/plugins/blink.lua
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        ["<C-i>"] = { "show", "show_documentation", "hide_documentation" },
        -- remove or leave <C-space> default entry if you want to drop it entirely
        -- Override default signature help from Neovim
        ["<C-s>"] = { "show_signature", "hide_signature", "fallback" },

        -- NOTE: Documentation
        --
        -- dedicated toggle, independent of Tab
        ["<C-d>"] = { "show_documentation", "hide_documentation", "fallback" },
        -- scroll the preview
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        -- reliable navigation that never conflicts with snippets
        -- ["<C-n>"] = { "select_next", "fallback" },
        -- ["<C-p>"] = { "select_prev", "fallback" },
      },
      signature = {
        enabled = true,
        -- trigger = {
        --   show_on_accept = true,
        --   show_on_accept_on_trigger_character = true,
        --   show_on_insert = true,
        --   show_on_insert_on_trigger_character = true,
        --   show_on_keyword = true,
        -- },
      },
      completion = {
        documentation = {
          auto_show = false,
        },
      },
    },
  },
}
