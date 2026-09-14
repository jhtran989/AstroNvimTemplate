-- lua/plugins/nvim-dap.lua
return {
  "mfussenegger/nvim-dap",
  config = function()
    local dap = require "dap"

    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        -- Mason installs the Windows binary as codelldb.cmd/.exe under mason/bin
        -- TODO: Make sure to update if on Linux (like without .cmd extension)
        command = vim.fn.stdpath "data" .. "/mason/bin/codelldb.cmd",
        args = { "--port", "${port}" },
      },
    }

    dap.configurations.odin = {
      {
        name = "Launch Odin binary",
        type = "codelldb",
        request = "launch",
        program = function()
          -- TODO: Make sure to update path separator on Linux
          return vim.fn.input("Path to exe: ", vim.fn.getcwd() .. "\\", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
        initCommands = {
          "command script import " .. vim.fn.expand "C:/odin-lldb/odin.py",
        },
      },
    }
  end,
}
