local dap_ok, dap = pcall(require, "dap")
if not dap_ok then
  return
end

local function resolve_codelldb()
  local registry_ok, registry = pcall(require, "mason-registry")
  if registry_ok then
    local package_ok, package = pcall(registry.get_package, "codelldb")
    if package_ok and package:is_installed() then
      local path = package:get_install_path() .. "/extension/adapter/codelldb"
      if vim.fn.executable(path) == 1 then
        return path
      end
    end
  end

  local system_path = vim.fn.exepath("codelldb")
  if system_path ~= "" then
    return system_path
  end

  return nil
end

local codelldb_path = resolve_codelldb()

if codelldb_path then
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = codelldb_path,
      args = { "--port", "${port}" },
    },
  }
end

local function read_program()
  return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
end

local function read_args()
  local input = vim.fn.input("Args: ")
  return vim.split(vim.trim(input), "%s+", { trimempty = true })
end

local function launch_configuration()
  return {
    name = "Launch executable",
    type = "codelldb",
    request = "launch",
    program = read_program,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    runInTerminal = false,
    args = read_args,
  }
end

dap.configurations.c = { launch_configuration() }
dap.configurations.cpp = { launch_configuration() }
dap.configurations.rust = { launch_configuration() }

