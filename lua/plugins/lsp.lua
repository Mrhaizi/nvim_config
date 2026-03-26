local mason_ok, mason = pcall(require, "mason")
local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
local cmp_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")

if not (mason_ok and mason_lspconfig_ok and cmp_lsp_ok) then
  return
end

local has_vim_lsp_config = type(vim.lsp) == "table" and vim.lsp.config ~= nil and vim.lsp.enable ~= nil
local legacy_configs = nil
local util = nil

if not has_vim_lsp_config then
  local legacy_configs_ok
  legacy_configs_ok, legacy_configs = pcall(require, "lspconfig.configs")
  if not legacy_configs_ok then
    return
  end

  util = require("lspconfig.util")
end

local capabilities = cmp_nvim_lsp.default_capabilities()
local formatting_group = vim.api.nvim_create_augroup("UserLspFormat", { clear = true })

mason.setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

mason_lspconfig.setup({
  ensure_installed = {
    "clangd",
    "cmake",
    "gopls",
    "lua_ls",
    "rust_analyzer",
  },
  automatic_enable = false,
})

for severity, icon in pairs({
  Error = "E",
  Warn = "W",
  Hint = "H",
  Info = "I",
}) do
  local hl = "DiagnosticSign" .. severity
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

vim.diagnostic.config({
  virtual_text = {
    spacing = 2,
    prefix = "*",
    source = "if_many",
  },
  signs = true,
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  float = {
    border = "rounded",
    source = "if_many",
  },
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
})

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = "rounded",
})

vim.keymap.set("n", "gl", vim.diagnostic.open_float, { silent = true, desc = "Show line diagnostics" })
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { silent = true, desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { silent = true, desc = "Next diagnostic" })

local function buf_map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = desc,
  })
end

local function get_offset_encoding(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.offset_encoding then
      return client.offset_encoding
    end
  end

  return "utf-16"
end

local function format_buffer(bufnr)
  vim.lsp.buf.format({
    bufnr = bufnr,
    async = false,
    timeout_ms = 3000,
  })
end

local function organize_go_imports(bufnr)
  local params = vim.lsp.util.make_range_params()
  params.context = { only = { "source.organizeImports" } }

  local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
  if not result then
    return
  end

  local encoding = get_offset_encoding(bufnr)
  for _, response in pairs(result) do
    for _, action in pairs(response.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, encoding)
      end

      if action.command then
        vim.lsp.buf.execute_command(action.command)
      end
    end
  end
end

local function set_format_on_save(bufnr, callback)
  vim.api.nvim_clear_autocmds({
    group = formatting_group,
    buffer = bufnr,
  })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = formatting_group,
    buffer = bufnr,
    callback = callback,
  })
end

local function user_on_attach(client, bufnr)
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

  buf_map(bufnr, "n", "gd", vim.lsp.buf.definition, "Go to definition")
  buf_map(bufnr, "n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  buf_map(bufnr, "n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  buf_map(bufnr, "n", "gr", vim.lsp.buf.references, "List references")
  buf_map(bufnr, "n", "K", vim.lsp.buf.hover, "Hover documentation")
  buf_map(bufnr, "n", "gs", vim.lsp.buf.signature_help, "Signature help")
  buf_map(bufnr, "n", "<leader>la", vim.lsp.buf.code_action, "Code action")
  buf_map(bufnr, "n", "<leader>lf", function()
    format_buffer(bufnr)
  end, "Format buffer")
  buf_map(bufnr, "n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")

  if client.name == "gopls" then
    set_format_on_save(bufnr, function()
      organize_go_imports(bufnr)
      format_buffer(bufnr)
    end)
  elseif client.name == "rust_analyzer" then
    set_format_on_save(bufnr, function()
      format_buffer(bufnr)
    end)
  end
end

local function parse_package_spec(specifier)
  local package_ok, package = pcall(require, "mason-core.package")
  if not package_ok then
    return specifier
  end

  local server_name, version = package.Parse(specifier)
  local mappings_ok, mappings = pcall(require, "mason-lspconfig.mappings")
  if not mappings_ok then
    return specifier
  end

  local mason_map = mappings.get_mason_map()
  local package_name = mason_map.lspconfig_to_package[server_name] or server_name

  if version then
    return ("%s@%s"):format(package_name, version)
  end

  return package_name
end

local function lsp_server_completion(arg_lead)
  local registry_ok, registry = pcall(require, "mason-registry")
  local mappings_ok, mappings = pcall(require, "mason-lspconfig.mappings")
  if not (registry_ok and mappings_ok) then
    return {}
  end

  registry.refresh()
  local mason_map = mappings.get_mason_map()
  local candidates = vim.tbl_keys(mason_map.lspconfig_to_package)
  table.sort(candidates)

  return vim.tbl_filter(function(name)
    return vim.startswith(name, arg_lead)
  end, candidates)
end

local function installed_lsp_server_completion(arg_lead)
  local registry_ok, registry = pcall(require, "mason-registry")
  local mappings_ok, mappings = pcall(require, "mason-lspconfig.mappings")
  if not (registry_ok and mappings_ok) then
    return {}
  end

  local mason_map = mappings.get_mason_map()
  local servers = {}
  for _, package_name in ipairs(registry.get_installed_package_names()) do
    local server_name = mason_map.package_to_lspconfig[package_name]
    if server_name then
      table.insert(servers, server_name)
    end
  end

  table.sort(servers)
  return vim.tbl_filter(function(name)
    return vim.startswith(name, arg_lead)
  end, servers)
end

local function setup_lsp_install_compat_commands()
  local mason_command_ok, mason_command = pcall(require, "mason.api.command")
  if not mason_command_ok then
    return
  end

  pcall(vim.api.nvim_del_user_command, "LspInstall")
  vim.api.nvim_create_user_command("LspInstall", function(opts)
    if #opts.fargs == 0 then
      vim.cmd("Mason")
      return
    end

    local package_specs = vim.tbl_map(parse_package_spec, opts.fargs)
    mason_command.MasonInstall(package_specs)
  end, {
    desc = "Install one or more LSP servers.",
    nargs = "*",
    complete = lsp_server_completion,
  })

  pcall(vim.api.nvim_del_user_command, "LspUninstall")
  vim.api.nvim_create_user_command("LspUninstall", function(opts)
    if #opts.fargs == 0 then
      vim.notify("Usage: :LspUninstall clangd gopls rust_analyzer", vim.log.levels.INFO)
      return
    end

    local package_names = vim.tbl_map(parse_package_spec, opts.fargs)
    mason_command.MasonUninstall(package_names)
  end, {
    desc = "Uninstall one or more LSP servers.",
    nargs = "*",
    complete = installed_lsp_server_completion,
  })
end

setup_lsp_install_compat_commands()

local clangd_cmd = {
  "clangd",
  "--background-index",
  "--clang-tidy",
  "--completion-style=detailed",
  "--header-insertion=never",
}

if type(vim.g.clangd_query_drivers) == "table" and #vim.g.clangd_query_drivers > 0 then
  table.insert(clangd_cmd, "--query-driver=" .. table.concat(vim.g.clangd_query_drivers, ","))
elseif type(vim.g.clangd_query_drivers) == "string" and vim.g.clangd_query_drivers ~= "" then
  table.insert(clangd_cmd, "--query-driver=" .. vim.g.clangd_query_drivers)
end

local clangd_init_options = {
  clangdFileStatus = true,
}

if type(vim.g.clangd_fallback_flags) == "table" and #vim.g.clangd_fallback_flags > 0 then
  clangd_init_options.fallbackFlags = vim.g.clangd_fallback_flags
end

if has_vim_lsp_config then
  local function merge_capabilities(server_name, extra_capabilities)
    local server_defaults = vim.deepcopy(vim.lsp.config[server_name] or {})

    return vim.tbl_deep_extend(
      "force",
      {},
      server_defaults.capabilities or {},
      capabilities,
      extra_capabilities or {}
    )
  end

  local function merge_on_attach(server_name, extra_on_attach)
    local server_defaults = vim.deepcopy(vim.lsp.config[server_name] or {})
    local default_on_attach = server_defaults.on_attach
    local custom_on_attach = extra_on_attach or user_on_attach

    return function(client, bufnr)
      if type(default_on_attach) == "function" then
        default_on_attach(client, bufnr)
      end

      if type(custom_on_attach) == "function" then
        custom_on_attach(client, bufnr)
      end
    end
  end

  local function configure_server(server_name, config)
    local final_config = vim.deepcopy(config or {})
    final_config.capabilities = merge_capabilities(server_name, final_config.capabilities)
    final_config.on_attach = merge_on_attach(server_name, final_config.on_attach)

    vim.lsp.config(server_name, final_config)
    vim.lsp.enable(server_name)
  end

  configure_server("lua_ls", {
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = vim.split(package.path, ";"),
        },
        diagnostics = {
          globals = { "vim" },
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
  })

  configure_server("clangd", {
    cmd = clangd_cmd,
    init_options = clangd_init_options,
    root_markers = {
      ".clangd",
      ".clang-tidy",
      ".clang-format",
      "compile_commands.json",
      "compile_flags.txt",
      "CMakeLists.txt",
      "configure.ac",
      ".git",
    },
  })

  configure_server("cmake", {
    init_options = {
      buildDirectory = "build",
    },
    root_markers = {
      "CMakePresets.json",
      "CMakeLists.txt",
      "CTestConfig.cmake",
      ".git",
      "build",
      "cmake",
    },
  })

  configure_server("gopls", {
    settings = {
      gopls = {
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        gofumpt = true,
        analyses = {
          shadow = true,
          unusedparams = true,
          unreachable = true,
        },
      },
    },
  })

  configure_server("rust_analyzer", {
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = true,
        cargo = {
          allFeatures = true,
          buildScripts = {
            enable = true,
          },
        },
        check = {
          command = "check",
        },
        procMacro = {
          enable = true,
        },
      },
    },
  })
else
  local function legacy_setup_server(server_name, config)
    if not legacy_configs[server_name] then
      local ok, config_def = pcall(require, "lspconfig.configs." .. server_name)
      if not ok then
        vim.notify("Failed to load lspconfig config for " .. server_name, vim.log.levels.ERROR)
        return
      end
      legacy_configs[server_name] = config_def
    end

    legacy_configs[server_name].setup(config)
  end

  legacy_setup_server("lua_ls", {
    capabilities = capabilities,
    on_attach = user_on_attach,
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = vim.split(package.path, ";"),
        },
        diagnostics = {
          globals = { "vim" },
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
  })

  legacy_setup_server("clangd", {
    capabilities = capabilities,
    on_attach = user_on_attach,
    cmd = clangd_cmd,
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_dir = util.root_pattern("compile_commands.json", "compile_flags.txt", "CMakeLists.txt", ".git"),
    init_options = clangd_init_options,
  })

  legacy_setup_server("cmake", {
    capabilities = capabilities,
    on_attach = user_on_attach,
    root_dir = util.root_pattern("CMakePresets.json", "CMakeLists.txt", ".git"),
    init_options = {
      buildDirectory = "build",
    },
  })

  legacy_setup_server("gopls", {
    capabilities = capabilities,
    on_attach = user_on_attach,
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = util.root_pattern("go.work", "go.mod", ".git"),
    settings = {
      gopls = {
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        gofumpt = true,
        analyses = {
          shadow = true,
          unusedparams = true,
          unreachable = true,
        },
      },
    },
  })

  legacy_setup_server("rust_analyzer", {
    capabilities = capabilities,
    on_attach = user_on_attach,
    root_dir = util.root_pattern("Cargo.toml", "rust-project.json", ".git"),
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = true,
        cargo = {
          allFeatures = true,
          buildScripts = {
            enable = true,
          },
        },
        check = {
          command = "check",
        },
        procMacro = {
          enable = true,
        },
      },
    },
  })
end
