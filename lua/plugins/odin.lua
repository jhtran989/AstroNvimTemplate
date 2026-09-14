-- lua/plugins/odin.lua
return {
  {
    "AstroNvim/astrolsp",
    opts = {
      servers = { "ols" },
      config = {
        ols = {
          mason = false,
          cmd = { "C:/ols/ols.exe" },
          settings = {
            odin_command = "C:/Odin/odin.exe",
          },
        },
      },
    },
  },
}
