-- NOTE: Added for multi cursor support

-- lua/plugins/multicursor.lua
return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  event = "VeryLazy",
  config = function()
    local mc = require "multicursor-nvim"
    mc.setup()
    local set = vim.keymap.set
    local nx = { "n", "x" }

    -- Treesitter node types to treat as "scope" (verify with :InspectTree in an Odin file)
    local scopes = {
      proc = { procedure_declaration = true, procedure_literal = true },
      block = { block = true },
    }

    local function match_word_in_scope(kind)
      local word = vim.fn.expand "<cword>"
      if word == "" then
        return
      end

      local node = vim.treesitter.get_node()
      while node and not scopes[kind][node:type()] do
        node = node:parent()
      end
      if not node then
        vim.notify("No enclosing " .. kind .. " found", vim.log.levels.WARN)
        return
      end
      local sr, sc, er, ec = node:range() -- 0-indexed, end exclusive

      local cur = vim.api.nvim_win_get_cursor(0) -- { row (1-idx), col (0-idx) }
      local lines = vim.api.nvim_buf_get_lines(0, sr, er + 1, false)
      local pat = "%f[%w_]" .. vim.pesc(word) .. "%f[^%w_]"

      mc.action(function(ctx)
        local main = ctx:mainCursor()
        local main_start -- start of the match the main cursor is sitting in

        for i, line in ipairs(lines) do
          local lnum = sr + i -- 1-indexed
          local init = 1
          while true do
            local s, e = line:find(pat, init)
            if not s then
              break
            end
            init = e + 1
            local in_range = not ((lnum == sr + 1 and s - 1 < sc) or (lnum == er + 1 and e > ec))
            local is_main = lnum == cur[1] and cur[2] >= s - 1 and cur[2] < e
            if is_main then
              main_start = { lnum, s }
            elseif in_range then
              main:clone():setPos { lnum, s }
            end
          end
        end

        -- Jump the main cursor to the beginning of its own match
        if main_start then
          main:setPos(main_start)
        end
      end)
    end

    -- NOTE: Many keybindings below
    set(nx, "<Leader>mP", function()
      match_word_in_scope "proc"
    end, { desc = "Cursors on word in procedure" })
    set(nx, "<Leader>mB", function()
      match_word_in_scope "block"
    end, { desc = "Cursors on word in block" })

    -- Ctrl shortcuts (VS Code style)
    -- set(nx, "<C-n>", function()
    --   mc.matchAddCursor(1)
    -- end, { desc = "Add cursor at next match" })
    -- set(nx, "<C-S-n>", function()
    --   mc.matchAddCursor(-1)
    -- end, { desc = "Add cursor at prev match" })
    -- set(nx, "<C-s>", function()
    --   mc.matchSkipCursor(1)
    -- end, { desc = "Skip next match" })
    -- set(nx, "<C-Up>", function()
    --   mc.lineAddCursor(-1)
    -- end, { desc = "Add cursor line above" })
    -- set(nx, "<C-Down>", function()
    --   mc.lineAddCursor(1)
    -- end, { desc = "Add cursor line below" })
    -- set(nx, "<C-q>", mc.toggleCursor, { desc = "Toggle cursor" })
    set("n", "<C-LeftMouse>", mc.handleMouse, { desc = "Toggle cursor at mouse" })

    -- <Leader>m group: word/selection matches
    set(nx, "<Leader>mn", function()
      mc.matchAddCursor(1)
    end, { desc = "Add cursor at next match" })
    set(nx, "<Leader>mp", function()
      mc.matchAddCursor(-1)
    end, { desc = "Add cursor at prev match" })
    set(nx, "<Leader>ms", function()
      mc.matchSkipCursor(1)
    end, { desc = "Skip next match" })
    set(nx, "<Leader>mA", mc.matchAllAddCursors, { desc = "Cursors on all matches" })

    -- <Leader>m group: search-based (/ or ?)
    set(nx, "<Leader>m/", mc.searchAllAddCursors, { desc = "Cursors on all search matches" })
    set(nx, "<Leader>mf", function()
      mc.searchAddCursor(1)
    end, { desc = "Add cursor at next search match" })
    set(nx, "<Leader>mF", function()
      mc.searchAddCursor(-1)
    end, { desc = "Add cursor at prev search match" })

    -- <Leader>m group: lines, toggle, restore
    set(nx, "<Leader>mj", function()
      mc.lineAddCursor(1)
    end, { desc = "Add cursor line below" })
    set(nx, "<Leader>mk", function()
      mc.lineAddCursor(-1)
    end, { desc = "Add cursor line above" })
    set(nx, "<Leader>mt", mc.toggleCursor, { desc = "Toggle cursor here" })
    set("x", "<Leader>mv", mc.visualToCursors, { desc = "Selection to cursors" })
    set("n", "<Leader>mr", mc.restoreCursors, { desc = "Restore cursors" })

    -- Visual mode helpers
    set("x", "I", mc.insertVisual, { desc = "Insert at start of each line" })
    set("x", "A", mc.appendVisual, { desc = "Append at end of each line" })
    set("x", "S", mc.splitCursors, { desc = "Split selection by regex" })
    set("x", "M", mc.matchCursors, { desc = "Match regex within selection" })

    -- Keys that only exist while multiple cursors are active
    mc.addKeymapLayer(function(layerSet)
      layerSet(nx, "<Left>", mc.prevCursor)
      layerSet(nx, "<Right>", mc.nextCursor)
      layerSet(nx, "<Leader>x", mc.deleteCursor)
      layerSet(nx, "<Leader>mx", mc.deleteCursor)
      layerSet("n", "q", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)
  end,
}
