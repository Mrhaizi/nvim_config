local dap = require('dap')

dap.adapters.codelldb = {
  type = 'server',
  port = "${port}",
  executable = {
    command = '~/Downloads/codelldb-x86_64-linux.vsix_FILES/extension/adapter/codelldb', -- 替换为实际路径
    args = { "--port", "${port}" },
  }
}

dap.configurations.cpp = {
  {
    name = "Launch file",
    type = "codelldb",  -- 使用 codelldb 作为适配器类型
    request = "launch",
    program = function()
      -- return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        return '~/Desktop/my_code/App-client/build/Debug/App-client'
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    runInTerminal = false,
    args = {},  -- 如果有需要传递给程序的参数，可以在这里填写
  },
}


