local M = {}

-- May not be used (check mapping for <lm> in lua/plugins/astrocore.lua)
function M.inspect_to_buffer(value)
  local lines = vim.split(vim.inspect(value), "\n")
  vim.cmd "new"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

return M
