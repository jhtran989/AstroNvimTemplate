local M = {}

local call_types = {
  call_expression = true, -- odin, js/ts, go, c, rust, ...
  call = true, -- python, ruby
  method_invocation = true,
  invocation_expression = true,
  function_call = true,
}

function M.select()
  local node = vim.treesitter.get_node()
  while node and not call_types[node:type()] do
    node = node:parent()
  end
  if not node then
    return
  end

  local open, close
  for child in node:iter_children() do
    local t = child:type()
    if t == "(" and not open then
      open = child
    end
    if t == ")" then
      close = child
    end
  end
  if not (open and close) then
    return
  end

  local sr, sc = open:end_()
  local er, ec = close:start()
  if sr == er and sc >= ec then
    return
  end -- empty "()"

  -- vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  -- if not vim.fn.mode():match "[vV]" then vim.cmd "normal! v" end
  -- vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })

  -- leave visual mode so the anchor resets (no-op otherwise)
  if vim.fn.mode():match "^[vV\22]" then
    vim.cmd "normal! \27"
  end

  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd "normal! v"
  vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
end

return M
