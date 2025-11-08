vim.g.cmake_build_dir_location = 'build'
vim.g.cmake_link_compile_commands = 1
-- 生成阶段开启 compile_commands.json
vim.g.cmake_generate_options = { "-D", "CMAKE_EXPORT_COMPILE_COMMANDS=ON" }
vim.g.cmake_console_size = 15
vim.g.cmake_console_position = 'botright'
vim.g.cmake_jump_on_error = 1
vim.g.cmake_restore_state = 1

-- 设置 CMake 命令的别名（可选）
vim.g.cmake_command_aliases = {
    G = 'CMakeGenerate',  -- 生成构建文件
    B = 'CMakeBuild',     -- 编译项目
    R = 'CMakeRun',       -- 运行项目
    C = 'CMakeClean'      -- 清理构建目录
}
