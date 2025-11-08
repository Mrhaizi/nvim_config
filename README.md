# Neovim 配置（C/C++/CMake 友好）

本仓库是我的 Neovim 配置，基于 packer.nvim 管理插件，聚焦于 C/C++ 与 CMake 开发，内置 LSP、自动补全、Treesitter、Telescope、Git 集成、调试等常用能力，并提供常用快捷键与工作流示例。

## 环境要求
- Neovim ≥ 0.8（推荐最新版）
- Git（用于自动安装 packer.nvim 和插件）
- ripgrep（Telescope `live_grep` 需用）
- C/C++ 开发：`clangd`、`cmake`、`g++/clang++`（建议通过系统包管理器安装）
- 可选：`codelldb`（用于 nvim-dap 调试，见下文“调试”）

## 快速开始
1. 将本配置放到 `~/.config/nvim`。
2. 首次启动 Neovim：会自动安装 `packer.nvim` 并同步插件（如未自动同步，可执行 `:PackerSync`）。
3. 安装 LSP/工具：执行 `:Mason`，安装 `lua-language-server`、`clangd`、`cmake-language-server` 等。
4. 安装 Treesitter 语法：执行 `:TSUpdate`。
5. 享用内置快捷键与工作流（见下文）。

## 目录结构
- `init.lua`：入口配置，引导核心与插件模块
- `lua/core/options.lua`：基础选项与主题（Tokyonight）
- `lua/core/keymaps.lua`：全局与常用插件快捷键
- `lua/plugins/plugins-setup.lua`：插件管理与声明（packer.nvim）
- `lua/plugins/*.lua`：各插件的独立配置（LSP/补全/树/搜索/状态栏/等）
- `plugin/packer_compiled.lua`：packer 自动生成文件（无需手动修改）

## 主要功能与插件
- 主题与 UI
  - Tokyonight 主题、透明背景、Lualine 状态栏、Bufferline 标签
- 文件与代码导航
  - NvimTree 文件树、Telescope 文件/内容/帮助检索
- 语法与语义
  - Treesitter 语法高亮与缩进
  - LSP：`lua_ls`、`clangd`、`cmake`、`gopls`（Go）等（Mason 管理）
- 自动补全
  - nvim-cmp + cmp-nvim-lsp + LuaSnip + Friendly Snippets + path/buffer 源
  - nvim-autopairs 与补全联动补括号
- Git 集成
  - gitsigns 显示增改删标记
- CMake 工程
  - vim-cmake 提供生成/编译/运行/清理命令，默认构建目录 `build/`
- 其他
  - vim-tmux-navigator 跨 pane 导航、注释（Comment.nvim / vim-commentary）、文本替换增强（vim-abolish）

## 常用快捷键（部分）
- 领导键：`<Space>`
- 模式与窗口
  - 插入 → 正常：`jk`
  - 垂直分屏：`<leader>sv`；水平分屏：`<leader>sh`
- 文件树与 Buffer
  - 切换 NvimTree：`<leader>e`
  - 下/上一个 Buffer：`<leader>l` / `<leader>h`
- 搜索（Telescope）
  - 查找文件：`<leader>ff`
  - 全文检索（需 ripgrep）：`<leader>fg`
  - 列出 Buffer：`<leader>fb`
  - 帮助标签：`<leader>fh`
- CMake（vim-cmake）
  - 生成：`<leader>g` → `:CMakeGenerate`
  - 编译：`<leader>b` → `:CMakeBuild`
  - 运行（自动选择默认目标）：`<leader>rn`
  - 一键生成+编译+运行：`<leader>rr`（若未生成，会自动用外部 cmake 先生成）
  - 清理：`<leader>c` → `:CMakeClean`
- 其他
  - 取消高亮：`<leader>dh`
  - 保存：`<leader>s`
  - 打开终端：`<leader>te`

提示：更多具体映射可见 `lua/core/keymaps.lua`。

## 主题与外观
- 主题：Tokyonight（Moon 风格，透明背景，边栏/浮窗透明）
- 高亮透明适配：切换配色后自动去除背景色，兼容透明终端
- Lualine 使用 Tokyonight 主题；Bufferline 与 NvimTree 联动偏移

相关配置：`lua/core/options.lua`、`lua/plugins/lualine.lua`、`lua/plugins/bufferline.lua`、`lua/plugins/nvim-tree.lua`。

## LSP 与补全
- Mason 自动管理与安装 LSP：`lua_ls`、`clangd`、`cmake`、`gopls`
- 绑定常用 LSP 快捷键：`gd`/`gD`/`gr`/`gk` 等
- nvim-cmp 映射：`<CR>` 确认、`<Tab>`/`<S-Tab>` 选择、`<C-b>/<C-f>` 文档滚动、`<C-e>` 取消
- Autopairs 与补全联动，自动补全括号

相关配置：`lua/plugins/lsp.lua`、`lua/plugins/cmp.lua`、`lua/plugins/autopairs.lua`。

## C/C++/CMake 工作流
- 构建目录：默认在项目根下的 `build/`（见 `lua/plugins/cmake.lua`）
- 已启用生成 `compile_commands.json`（配置项 `CMAKE_EXPORT_COMPILE_COMMANDS=ON`），并自动在项目根创建软链（`vim.g.cmake_link_compile_commands = 1`）
- 典型流程：
  1) `:CMakeGenerate`（或 `<leader>g`）
  2) `:CMakeBuild`（或 `<leader>b`）
  3) 运行（`<leader>rn` 自动选择目标，或 `<leader>rr` 一键 G+B+R；若首次使用，`<leader>rr` 会自动执行一次外部 cmake 生成）

默认运行目标：
- 可设置 `vim.g.cmake_default_run_target = "你的可执行目标名"` 固定运行目标；
- 如未设置且只存在一个可执行目标，自动使用该目标；
- 如存在多个目标且未设置默认，自动使用第一个并给出提示。

工程根识别：
- 已将 `vim.g.cmake_root_markers` 设置为 `{ '.git', 'CMakeLists.txt' }`，无 Git 仓库时也能识别根目录；
- 一键构建在找不到插件提供的路径时，会从当前目录向上查找 `CMakeLists.txt` 作为回退。

## 调试（nvim-dap）
本配置内置 `nvim-dap` 与 codelldb 适配器示例（见 `lua/plugins/debug.lua`）。请根据你的本地路径调整：
- 适配器路径：`executable.command` 指向 `codelldb` 二进制
- 启动程序：`configurations.cpp[1].program` 指向你的可执行文件

建议做法：
- 使用 Mason 安装 `codelldb`（`Mason` 中搜索 codelldb），并将 `debug.lua` 中的路径改为 Mason 安装位置
- 或者自行下载 `codelldb` 并修改为实际路径

## 可调项与注意
- `clangd` 启动参数里已包含 `--query-driver=/usr/bin/clangd`，若编译器路径不同请修改（`lua/plugins/lsp.lua`）
- `:CMakeRun` 的键位当前不带 `<CR>`，按下后需回车执行（你也可以在 `lua/core/keymaps.lua` 中改为 `:CMakeRun<CR>`）
- 主题默认 Tokyonight，可根据喜好启用 `onedark`（已安装但未启用）

## 常见命令
- 插件：`:PackerSync`、`:PackerClean`
- LSP/工具：`:Mason`
- Treesitter：`:TSUpdate`
- CMake：`:CMakeGenerate`、`:CMakeBuild`、`:CMakeRun`、`:CMakeClean`
## Go 支持
- 语法高亮：已启用 Treesitter Go 解析器（go/gomod/gowork）
- 语言服务：`gopls`（已纳入 Mason 安装清单）
- 自动导入与格式化：保存时自动 organize imports + `gofumpt` 格式化
- 使用提示：
  - 打开 Go 文件后，执行 `:Mason` 安装 `gopls`（若未安装）
  - 正常写码，补全走 nvim-cmp + gopls；保存时自动整理导入、格式化
