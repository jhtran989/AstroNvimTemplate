-- lua/plugins/sibling-swap.lua

-- Operators the custom swap will cross
local ops = {
  [":="] = true,
  ["="] = true,
  ["+="] = true,
  ["-="] = true,
  ["*="] = true,
  ["/="] = true,
  ["+"] = true,
  ["-"] = true,
  ["*"] = true,
  ["/"] = true,
  ["%"] = true,
  ["=="] = true,
  ["!="] = true,
  ["<"] = true,
  [">"] = true,
  ["<="] = true,
  [">="] = true,
  ["&&"] = true,
  ["||"] = true,
  [","] = true,
}

-- Operators that change when their operands trade places.
-- Symmetric ones (==, !=, +, *, &&, ||, ...) are left alone.
local flips = {
  ["<"] = ">",
  [">"] = "<",
  ["<="] = ">=",
  [">="] = "<=",
}

-- Climb from the cursor until a node has an operator next to it, then swap that
-- whole node with the operand on the other side. `.` and `[]` aren't operators
-- here, so `frame.x` and `a[i]` always move as one unit.
-- dir: 1 = next, -1 = previous. flip: also flip the operator via `flips`.
local function swap_across_operator(dir, flip)
  local node = vim.treesitter.get_node()
  while node do
    local parent = node:parent()
    if not parent then
      break
    end

    local idx
    for i = 0, parent:child_count() - 1 do
      if parent:child(i):id() == node:id() then
        idx = i
        break
      end
    end

    local sep = idx and parent:child(idx + dir)
    local sep_text = sep and not sep:named() and vim.treesitter.get_node_text(sep, 0)
    if sep_text and ops[sep_text] then
      local other = parent:child(idx + 2 * dir)
      if other and other:named() then
        local a, b = node, other
        if dir == -1 then
          a, b = other, node
        end -- a comes first in the buffer

        local ar, sr, br = { a:range() }, { sep:range() }, { b:range() }
        local at = vim.split(vim.treesitter.get_node_text(a, 0), "\n", { plain = true })
        local bt = vim.split(vim.treesitter.get_node_text(b, 0), "\n", { plain = true })

        -- the cursor's operand lands where the other node started
        local target = (node:id() == a:id()) and br or ar
        local ns = vim.api.nvim_create_namespace "swap_across_operator"
        local mark = vim.api.nvim_buf_set_extmark(0, ns, target[1], target[2], { right_gravity = false })

        -- edit back to front so earlier ranges stay valid
        vim.api.nvim_buf_set_text(0, br[1], br[2], br[3], br[4], at)
        if flip and flips[sep_text] then
          vim.api.nvim_buf_set_text(0, sr[1], sr[2], sr[3], sr[4], { flips[sep_text] })
        end
        vim.api.nvim_buf_set_text(0, ar[1], ar[2], ar[3], ar[4], bt)

        local pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, mark, {})
        vim.api.nvim_buf_del_extmark(0, ns, mark)
        if pos[1] then
          vim.api.nvim_win_set_cursor(0, { pos[1] + 1, pos[2] })
        end
        return
      end
    end
    node = parent
  end
  vim.notify("No operand to swap across an operator", vim.log.levels.WARN)
end

return {
  "Wansmer/sibling-swap.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  event = "BufRead",
  opts = {
    use_default_keymaps = false,
    allowed_separators = {
      ",",
      ";",
      "and",
      "or",
      "&&",
      "||",
      "&",
      "|",
      "==",
      "!=",
      "===",
      "!==",
      "+",
      "-",
      "*",
      "/",
      "%",
      "<",
      ">",
      "<=",
      ">=",
      "=",
    },
    highlight_node_at_cursor = true,
    ignore_injected_langs = false,
  },
  keys = {
    -- Original plugin swaps
    {
      "<Leader>sn",
      function()
        require("sibling-swap").swap_with_right()
      end,
      desc = "Swap with next sibling",
    },
    {
      "<Leader>sp",
      function()
        require("sibling-swap").swap_with_left()
      end,
      desc = "Swap with previous sibling",
    },
    {
      "<Leader>sN",
      function()
        require("sibling-swap").swap_with_right_with_opp()
      end,
      desc = "Swap next + flip operator",
    },
    {
      "<Leader>sP",
      function()
        require("sibling-swap").swap_with_left_with_opp()
      end,
      desc = "Swap previous + flip operator",
    },

    -- Access-aware swaps (treat a.b and a[i] as one operand)
    {
      "<Leader>se",
      function()
        swap_across_operator(1, false)
      end,
      desc = "Swap whole operand with next (a.b / a[i])",
    },
    {
      "<Leader>sE",
      function()
        swap_across_operator(-1, false)
      end,
      desc = "Swap whole operand with previous (a.b / a[i])",
    },
    {
      "<Leader>sf",
      function()
        swap_across_operator(1, true)
      end,
      desc = "Swap whole operand with next + flip operator",
    },
    {
      "<Leader>sF",
      function()
        swap_across_operator(-1, true)
      end,
      desc = "Swap whole operand with previous + flip operator",
    },
  },
}
