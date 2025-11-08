local M = {}


-- 获取可执行目标列表（使用 vim-cmake 的补全函数）
local function get_exec_targets()
  local ok, targets = pcall(vim.fn["cmake#GetExecTargets"], "", "", 0)
  if not ok or not targets or targets == "" then
    return {}
  end
  local list = {}
  for name in string.gmatch(targets, "[^\n]+") do
    table.insert(list, name)
  end
  return list
end

-- 选择默认运行目标：优先使用 vim.g.cmake_default_run_target，其次唯一目标，否则取第一个
local function pick_default_target()
  local targets = get_exec_targets()
  local preferred = vim.g.cmake_default_run_target
  if preferred and preferred ~= "" then
    for _, t in ipairs(targets) do
      if t == preferred then
        return t
      end
    end
    vim.notify(string.format("CMake 默认运行目标 '%s' 不存在，将自动选择。", preferred), vim.log.levels.WARN)
  end
  if #targets == 1 then
    return targets[1]
  elseif #targets > 1 then
    vim.notify(string.format("检测到多个可执行目标，使用 '%s'。可设置 vim.g.cmake_default_run_target 指定默认目标。", targets[1]), vim.log.levels.INFO)
    return targets[1]
  else
    return nil
  end
end

-- 运行默认可执行目标
function M.run_default()
  local target = pick_default_target()
  if not target then
    vim.notify("未找到可执行目标，请先 :CMakeGenerate 且构建成功。", vim.log.levels.ERROR)
    return
  end
  -- 直接调用插件 API，避免命令行交互
  local ok, err = pcall(vim.fn["cmake#Run"], target)
  if not ok then
    vim.notify("运行失败: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- 一键：Generate + Build + Run（在构建成功事件上触发运行，一次性）
function M.build_and_run()
  -- 构建完成后自动运行
  local group = vim.api.nvim_create_augroup("CMakeBuildAndRun", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CMakeBuildSucceeded",
    callback = function()
      vim.defer_fn(function()
        M.run_default()
        pcall(vim.api.nvim_del_augroup_by_name, "CMakeBuildAndRun")
      end, 80)
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CMakeBuildFailed",
    callback = function()
      vim.notify("CMake 构建失败，未执行运行。", vim.log.levels.ERROR)
      pcall(vim.api.nvim_del_augroup_by_name, "CMakeBuildAndRun")
    end,
  })

  -- 如果尚未生成，则先用外部 cmake 进行一次生成，再触发 :CMakeBuild
  local function ensure_generated_and_build()
    local ok1, build_dir = pcall(vim.api.nvim_eval, "cmake#buildsys#Get().GetPathToCurrentConfig()")
    local ok2, source_dir = pcall(vim.api.nvim_eval, "cmake#buildsys#Get().GetSourceDir()")
    local need_fallback = (not ok1 or not ok2 or not build_dir or build_dir == "" or not source_dir or source_dir == "")
    if need_fallback then
      -- 回退方案：从“当前缓冲区所在目录优先，其次 CWD”向上寻找 CMakeLists.txt 作为工程根
      local buf = vim.api.nvim_buf_get_name(0)
      local cwd = (buf and buf ~= "" and vim.fn.fnamemodify(buf, ":p:h")) or vim.fn.getcwd()
      local found
      if vim.fs and vim.fs.find then
        local found_tbl = vim.fs.find("CMakeLists.txt", { upward = true, path = cwd, stop = vim.loop.os_homedir() })
        if #found_tbl > 0 then found = found_tbl[1] end
      end
      if not found then
        local patt = vim.fn.fnameescape(cwd) .. ";" .. vim.fn.expand("$HOME")
        local p = vim.fn.findfile("CMakeLists.txt", patt)
        if p ~= nil and p ~= "" then found = p end
      end
      if not found or found == "" then
        vim.notify("未找到 CMakeLists.txt，请在项目根或其子目录中执行。", vim.log.levels.ERROR)
        return
      end
      source_dir = vim.fn.fnamemodify(found, ":h")
      local config = vim.g.cmake_default_config or "Debug"
      local loc = vim.g.cmake_build_dir_location or "build"
      build_dir = table.concat({ source_dir, loc, config }, "/")
      vim.notify("已根据 CMakeLists.txt 推断工程根: " .. source_dir, vim.log.levels.INFO)
    end

    -- 始终进行一次外部 cmake 配置（幂等），避免缓存缺失导致的构建失败
    -- 确保插件后续以正确的工程根工作（影响 FindProjectRoot）
    pcall(vim.cmd, ("tcd %s"):format(vim.fn.fnameescape(source_dir)))

    local version
    local okv, ver = pcall(vim.api.nvim_eval, "cmake#buildsys#Get().GetCMakeVersion()")
    if okv and type(ver) == "table" and ver.major and ver.minor then
      version = ver
    end
    local args = {}
    local cmake = (vim.g.cmake_command and tostring(vim.g.cmake_command)) or "cmake"
    table.insert(args, cmake)
    if version and (version.major * 100 + version.minor) < 313 then
      table.insert(args, "-H" .. source_dir)
      table.insert(args, "-B" .. build_dir)
    else
      table.insert(args, "-S")
      table.insert(args, source_dir)
      table.insert(args, "-B")
      table.insert(args, build_dir)
    end
    local extra = vim.g.cmake_generate_options
    if type(extra) == "table" then
      for _, v in ipairs(extra) do table.insert(args, tostring(v)) end
    elseif type(extra) == "string" and extra ~= "" then
      for token in string.gmatch(extra, "[^%s]+") do table.insert(args, token) end
    end

    -- 在配置前写入 CMake File-API 查询，以便后续能获取可执行目标等信息
    pcall(vim.cmd, "call cmake#fileapi#Get().UpdateQueries(" .. vim.fn.string(build_dir) .. ")")
    vim.notify("配置中: " .. table.concat(args, " "), vim.log.levels.INFO)
    vim.fn.jobstart(args, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_exit = function(_, code)
        if code == 0 then
          if vim.g.cmake_link_compile_commands == 1 then
            local target = build_dir .. "/compile_commands.json"
            local link = source_dir .. "/compile_commands.json"
            if vim.fn.filereadable(target) == 1 then
              pcall(vim.loop.fs_unlink, link)
              vim.fn.jobstart({ cmake, "-E", "create_symlink", target, link })
            end
          end
          vim.schedule(function()
            pcall(vim.cmd, "CMakeBuild")
          end)
          vim.schedule(function()
            print("compile_commands.json 已生成，重启 clangd...")
            vim.cmd("LspRestart")
          end)
        else
          vim.schedule(function()
            vim.notify("外部 cmake 配置失败（请查看输出）。", vim.log.levels.ERROR)
          end)
        end
      end,
    })
  end

  ensure_generated_and_build()
end

return M
