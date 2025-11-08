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
  ensure_installed = {
    "lua_ls",
    "clangd",
    "cmake",
    "gopls",
  },
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- 设置 LSP 键映射
local on_attach = function(client, bufnr)
  local opts = { noremap=true, silent=true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gk', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
end

-- Lua 语言服务器配置
require("lspconfig").lua_ls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = vim.split(package.path, ';')
      },
      diagnostics = {
        globals = { 'vim' }
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

-- C++ (clangd) 语言服务器配置
require("lspconfig").clangd.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "clangd", "--query-driver=/usr/bin/clangd" },  -- 替换为你的编译器路径
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = require('lspconfig').util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
  settings = {
    clangd = {
      fallbackFlags = { "-std=c++20" }
    }
  }
}

-- CMake 语言服务器配置
require("lspconfig").cmake.setup {
  capabilities = capabilities,
  on_attach = on_attach,
}

-- Go (gopls) 语言服务器配置
require("lspconfig").gopls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = require('lspconfig').util.root_pattern("go.work", "go.mod", ".git"),
  settings = {
    gopls = {
      usePlaceholders = true,
      completeUnimported = true,
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
      gofumpt = true,
    }
  }
}

-- Go: 保存前自动 organize imports + 格式化
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
    for _, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, "utf-16")
        elseif r.command then
          vim.lsp.buf.execute_command(r.command)
        end
      end
    end
    vim.lsp.buf.format({ async = false })
  end,
})
