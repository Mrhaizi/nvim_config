-- 配置 vim-cmake
vim.g.cmake_build_dir_location = 'build'  -- 设置构建目录，默认为项目根目录下的 'build'


vim.g.cmake_generate_options = { '-DCMAKE_EXPORT_COMPILE_COMMANDS=ON', '-DCMAKE_BUILD_TYPE=Release'}  -- 自动生成 compile_commands.json

-- 自动设置构建类型为 Release，也可以使用 Debug
vim.g.cmake_build_type = 'Release'

-- 设置 CMake 命令的别名（可选）
vim.g.cmake_command_aliases = {
    G = 'CMakeGenerate',  -- 生成构建文件
    B = 'CMakeBuild',     -- 编译项目
    R = 'CMakeRun',       -- 运行项目
    C = 'CMakeClean'      -- 清理构建目录
}

