-- NOTE: Needed for word wrapping
--if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

local function is_decl(n)
  if n:type() ~= "assignment_statement" then
    return false
  end
  for child in n:iter_children() do
    if child:type() == ":=" then
      return true
    end
  end
  return false
end

local function locals_in_proc()
  local buf = vim.api.nvim_get_current_buf()
  local node = vim.treesitter.get_node()
  while node and not node:type():find "procedure" do
    node = node:parent()
  end
  if not node then
    return vim.notify "Not inside a proc"
  end

  local items = {}
  local function walk(n)
    if is_decl(n) then
      local row, col = n:start()
      local text = vim.trim(vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or "")
      table.insert(items, {
        text = text,
        file = vim.api.nvim_buf_get_name(buf),
        pos = { row + 1, col },
      })
    end
    for child in n:iter_children() do
      walk(child)
    end
  end
  walk(node)

  local Snacks = require "snacks"
  Snacks.picker { title = "Proc locals", items = items, format = "text", preview = "file" }
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- NOTE: Custom commands
    commands = {
      Messages = {
        function()
          vim.cmd "new"
          vim.cmd "put =execute('messages')"
          vim.bo.buftype = "nofile"
          vim.bo.bufhidden = "wipe"
        end,
        desc = "Open :messages in a scratch buffer",
      },
    },
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- set global limits for large files for disabling features like treesitter
      autopairs = true, -- enable autopairs at start
      cmp = true, -- enable completion at start
      diagnostics = { virtual_text = true, virtual_lines = false }, -- diagnostic settings on startup
      highlighturl = true, -- highlight URLs at start
      notifications = true, -- enable notifications at start
    },
    -- Diagnostics configuration (for vim.diagnostics.config({...})) when diagnostics are on
    diagnostics = {
      virtual_text = false,
      underline = true,

      -- Wrap diagnostic messages
      --float = { max_width = 80, border = "rounded" },

      -- Show expanded message for every item
      virtual_lines = true,
    },
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
    -- vim options can be configured here
    options = {
      opt = { -- vim.opt.<key>
        -- NOTE: Changed from true for relative
        relativenumber = false, -- sets vim.opt.relativenumber
        number = true, -- sets vim.opt.number
        spell = false, -- sets vim.opt.spell
        signcolumn = "yes", -- sets vim.opt.signcolumn to yes
        --wrap = false, -- sets vim.opt.wrap

        -- soft wrap
        wrap = true, -- wrap long lines on screen
        linebreak = true, -- break at word boundaries, not mid-word
        breakindent = true, -- wrapped lines keep their indentation
        showbreak = "↪ ", -- optional marker on wrapped lines

        -- ruler line at column 80
        colorcolumn = "80",

        -- hard wrap width
        textwidth = 80,
      },
      g = { -- vim.g.<key>
        -- configure global vim variables (vim.g)
        -- NOTE: `mapleader` and `maplocalleader` must be set in the AstroNvim opts or before `lazy.setup`
        -- This can be found in the `lua/lazy_setup.lua` file
      },
    },
    autocmds = {
      comment_autowrap = {
        {
          event = "FileType",
          desc = "Auto-wrap comments only, not code",
          callback = function()
            if vim.tbl_contains({ "markdown", "text", "gitcommit" }, vim.bo.filetype) then
              return
            end
            vim.opt_local.formatoptions:remove "t"
            vim.opt_local.formatoptions:append "c"
            vim.opt_local.formatoptions:append "q"
            vim.opt_local.formatoptions:append "j"
          end,
        },
      },
    },
    -- Mappings can be configured through AstroCore as well.
    -- NOTE: keycodes follow the casing in the vimdocs. For example, `<Leader>` must be capitalized
    mappings = {
      -- first key is the mode
      n = {
        -- second key is the lefthand side of the map

        -- NOTE: Group labels
        ["<Leader>s"] = { desc = "󰓡 Swap" },
        ["<Leader>m"] = { desc = "󰬸 Multi-cursor" },

        -- navigate buffer tabs
        ["]b"] = {
          function()
            require("astrocore.buffer").nav(vim.v.count1)
          end,
          desc = "Next buffer",
        },
        ["[b"] = {
          function()
            require("astrocore.buffer").nav(-vim.v.count1)
          end,
          desc = "Previous buffer",
        },

        -- mappings seen under group name "Buffer"
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(function(bufnr)
              require("astrocore.buffer").close(bufnr)
            end)
          end,
          desc = "Close buffer from tabline",
        },

        -- tables with just a `desc` key will be registered with which-key if it's installed
        -- this is useful for naming menus
        -- ["<Leader>b"] = { desc = "Buffers" },

        -- setting a mapping to false will disable it
        -- ["<C-S>"] = false,

        -- NOTE: Added below for showing buffer source in sidebar
        ["<Leader>bv"] = { "<cmd>Neotree buffers toggle left<cr>", desc = "Buffers sidebar" },

        -- NOTE: Added for block visual mode (vim) without affecting existing
        -- key bindings
        -- Mostly for making modifications on multiple lines at once
        ["<Leader>v"] = { "<C-v>", desc = "Block visual mode" },

        -- NOTE: Added for searching for local variables in procs (odin)
        ["<leader>lv"] = { locals_in_proc, desc = "Locals in proc" },

        -- NOTE: Added toggle for relative line numbers
        ["<Leader>uR"] = {
          function()
            vim.opt.relativenumber = not vim.opt.relativenumber:get()
          end,
          desc = "Toggle relative line numbers",
        },

        -- NOTE: Added for file scoped TODOs instead of all files in opened folder
        ["<Leader>fF"] = {
          function()
            if not package.loaded["todo-comments"] then
              require("lazy").load { plugins = { "todo-comments.nvim" } }
            end
            require("snacks").picker.todo_comments {
              dirs = { vim.fn.expand "%:p" },
            }
          end,
          desc = "Find TODOs (current file)",
        },

        -- NOTE: Added for really long diagnostic messages
        ["<Leader>lm"] = {
          function()
            local diags = vim.diagnostic.get(0, { lnum = vim.fn.line "." - 1 })
            if #diags == 0 then
              return vim.notify "No diagnostics on this line"
            end
            local lines = {}
            for _, d in ipairs(diags) do
              local src = d.source and (" [" .. d.source .. "]") or ""
              table.insert(lines, "── " .. vim.diagnostic.severity[d.severity] .. src .. " ──")
              vim.list_extend(lines, vim.split(d.message, "\n"))
              table.insert(lines, "")
            end
            vim.cmd "botright 15new"
            vim.bo.buftype, vim.bo.bufhidden, vim.bo.swapfile = "nofile", "wipe", false
            vim.wo.wrap, vim.wo.linebreak = true, true
            vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true })
          end,
          desc = "Show full diagnostic in buffer",
        },

        ["<Leader>fB"] = {
          function()
            Snacks.picker.lines {
              layout = { preset = "default", preview = true },
            }
          end,
          desc = "Find word in current buffer (with preview)",
        },
      },
      v = {
        -- NOTE: Does NOT work due to bug? Use plugin instead (mini-move)
        -- NOTE: Added for visual mode block move
        --["<A-j>"] = { ":m '>+1<CR>gv=gv", desc = "Move selection down" },
        --["<A-k>"] = { ":m '<-2<CR>gv=gv", desc = "Move selection up" },
      },
      x = {
        -- NOTE: Group labels
        ["<Leader>m"] = { desc = "󰬸 Multi-cursor" },

        -- Add easier escape in visual and select mode
        ["q"] = { "<Esc>", desc = "Exit visual mode" },
      },
    },
  },
}
