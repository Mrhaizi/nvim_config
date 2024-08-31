require("mason").setup({
  ui = {
      icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗"
      }
  }
})

require("mason-lspconfig").setup({
  -- 确保安装，根据需要填写
  ensure_installed = {
    "lua_ls",
    "clangd",
  },
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()
require("lspconfig").lua_ls.setup {
  capabilities = capabilities,
}
-- C++ (clangd) 语言服务器配置
require("lspconfig").clangd.setup {
  capabilities = capabilities,
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = require('lspconfig').util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
  settings = {
    clangd = {
      fallbackFlags = { "-std=c++17" }
    }
  }
}
