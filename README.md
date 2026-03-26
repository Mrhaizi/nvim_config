# Neovim 配置（C/C++ / Rust / Go）

这份配置基于 `packer.nvim`，目标是把 Neovim 变成一套可直接用于 `C/C++`、`Rust`、`Go` 开发的环境。它已经包含：

- LSP 补全
- 诊断报错与警告显示
- 跳转定义 / 查引用 / 重命名 / Code Action
- Treesitter 语法高亮
- CMake 工作流
- 基础调试能力（`nvim-dap` + `codelldb`）

如果你最终只想要一个能稳定写 `C/C++`、`Rust`、`Go` 的配置，这份现在就是按这个目标整理的。

## 当前支持

### C/C++
- `clangd`
- `cmake-language-server`
- `compile_commands.json` 工作流
- CMake 生成 / 编译 / 运行

### Rust
- `rust_analyzer`
- `cargo` 工程根识别
- 保存时自动格式化
- `proc-macro` / build scripts 支持

### Go
- `gopls`
- 自动补全
- 保存时自动整理 import
- 保存时自动格式化

## 环境要求

### 必需
- `Neovim >= 0.11`
- `git`
- `ripgrep`
- `curl` 或 `wget`
- `tar` / `unzip`

版本说明：

- 推荐使用 `Neovim 0.11.3+`
- 如果你使用的是较早的 `0.11-dev` 构建，最新插件版本可能会出现兼容问题
- 尤其是 `nvim-lspconfig`、`nvim-cmp`、`gitsigns.nvim` 这类紧跟 Neovim API 的插件

### 各语言工具链

#### C/C++
- `clangd`
- `cmake`
- `gcc/g++` 或 `clang/clang++`
- 推荐安装：`ninja`

#### Rust
- `rustup`
- `cargo`
- `rustfmt`
- 推荐安装：`clippy`

可用命令：

```bash
rustup default stable
rustup component add rustfmt clippy
```

#### Go
- `go`
- 推荐使用较新的 Go 版本

### 可选
- `codelldb`
  用于 `C/C++` / `Rust` 调试

## 第一次安装

1. 把仓库放到 `~/.config/nvim`
2. 首次启动 `nvim`
3. 执行 `:PackerSync`
4. 执行 `:TSUpdate`
5. 执行 `:MasonInstall clangd cmake-language-server gopls rust-analyzer lua-language-server`
6. 如果你要调试，再执行 `:Mason`，搜索并安装 `codelldb`

说明：

- `LSP` 由 `mason.nvim + mason-lspconfig + nvim-lspconfig` 管理
- `Treesitter` 会安装 `c`、`cpp`、`cmake`、`rust`、`toml`、`go`、`gomod`、`gowork` 等语法解析器
- 如果 `:MasonInstall` 或 `:Mason` 失败，可以先执行 `:MasonUpdate`
- 当前配置额外提供了兼容命令 `:LspInstall clangd gopls rust_analyzer`，但推荐优先使用 `:MasonInstall`

## 目录结构

- `init.lua`：入口
- `lua/core/options.lua`：基础选项和 UI
- `lua/core/keymaps.lua`：全局快捷键
- `lua/plugins/plugins-setup.lua`：插件声明
- `lua/plugins/lsp.lua`：LSP、诊断、语言专属保存行为
- `lua/plugins/cmp.lua`：补全
- `lua/plugins/treesitter.lua`：语法高亮
- `lua/plugins/cmake.lua`：CMake 默认行为
- `lua/plugins/cmake_utils.lua`：一键构建/运行辅助逻辑
- `lua/plugins/debug.lua`：`nvim-dap` 与 `codelldb`

## 你会得到什么

### 1. 补全
- `nvim-cmp + cmp-nvim-lsp + LuaSnip`
- LSP 补全、路径补全、buffer 补全
- 补全确认后自动补括号

### 2. 报错和警告
- 左侧 sign column 显示诊断标记
- 行内虚拟文本显示错误摘要
- 浮窗查看详细报错
- `]d` / `[d` 在诊断之间跳转

### 3. 常用代码操作
- 跳定义
- 查引用
- 重命名符号
- Code Action
- 格式化当前文件

## 主要快捷键

### 全局
- `<Space>`：Leader
- `jk`：插入模式返回普通模式
- `<leader>sv`：垂直分屏
- `<leader>sh`：水平分屏
- `<leader>e`：切换文件树
- `<leader>ff`：查文件
- `<leader>fg`：全文搜索
- `<leader>fb`：Buffer 列表
- `<leader>fh`：帮助搜索
- `<leader>l` / `<leader>h`：切换下一个 / 上一个 Buffer
- `<leader>s`：保存
- `<leader>te`：打开终端
- `<leader>lm`：打开 Mason
- `<leader>li`：查看当前 LSP 状态

### LSP
这些键只有在对应语言的 LSP attach 到当前 buffer 后才可用。

- `gd`：跳到定义
- `gD`：跳到声明
- `gi`：跳到实现
- `gr`：查引用
- `K`：查看悬浮文档
- `gs`：签名帮助
- `gl`：查看当前行诊断
- `[d` / `]d`：上一个 / 下一个诊断
- `<leader>la`：Code Action
- `<leader>lr`：重命名
- `<leader>lf`：格式化当前 buffer

### 补全
- `<C-Space>`：手动触发补全
- `<Tab>` / `<S-Tab>`：上下选择补全项
- `<CR>`：确认补全
- `<C-e>`：取消补全
- `<C-b>` / `<C-f>`：滚动补全文档

### CMake
- `<leader>g`：`CMakeGenerate`
- `<leader>b`：`CMakeBuild`
- `<leader>rn`：运行默认目标
- `<leader>rr`：一键生成 + 编译 + 运行
- `<leader>c`：`CMakeClean`

### 退出相关
- `<leader>q`：关闭当前 buffer
- `<leader>Q`：强制关闭当前 buffer
- `<leader>qq`：清理 CMake 窗口并退出全部
- `<leader>wq`：保存并退出全部
- `<leader>q!`：强制退出全部

## 如何判断是否已经生效

打开不同语言文件后，可以这样检查：

### 通用检查
- `:LspInfo`
  看当前 buffer 是否已经挂上对应 server
- `:Mason`
  看 `clangd` / `cmake` / `gopls` / `rust_analyzer` 是否已安装
- `:checkhealth mason`
  看系统依赖是否齐全

### 补全是否生效
输入代码时会弹出补全菜单，菜单来源会显示：

- `[LSP]`
- `[Snippet]`
- `[Path]`
- `[Buffer]`

### 报错是否生效
故意写一段错误代码，应该能看到：

- 左边有诊断标记
- 行尾或行内有错误提示
- `gl` 能打开详细错误浮窗

## C/C++ 使用方式

### 推荐项目结构
最好使用 CMake 工程，因为这套配置会自动围绕 `compile_commands.json` 工作。

### 日常流程
1. 打开项目根目录
2. 执行 `<leader>g` 生成构建目录
3. 执行 `<leader>b` 编译
4. 写代码时直接用 `gd`、`gr`、`K`、`<leader>la`
5. 执行 `<leader>rn` 或 `<leader>rr` 运行

### 关于 clangd
- `clangd` 会优先读取 `compile_commands.json`
- 当前配置会在 CMake 生成后自动把 `compile_commands.json` 链接到项目根
- 如果你不是 CMake 工程，至少准备：
  - `compile_commands.json`
  - 或 `compile_flags.txt`

### clangd 可调项
如果你使用自定义编译器路径，可以在配置中设置：

```lua
vim.g.clangd_query_drivers = {
  "/usr/bin/g++",
  "/usr/bin/gcc",
  "/usr/bin/clang++",
  "/usr/bin/clang",
}
```

如果你想给没有 `compile_commands.json` 的工程补默认参数，也可以设置：

```lua
vim.g.clangd_fallback_flags = { "-std=c++20" }
```

## Rust 使用方式

### 推荐项目结构
在包含 `Cargo.toml` 的目录下打开工程。

### 日常流程
1. `cargo new your_project`
2. `nvim src/main.rs`
3. 正常写代码，补全和诊断会由 `rust_analyzer` 提供
4. 保存时自动格式化
5. 用 `cargo build` / `cargo test` / `cargo run` 做构建和运行

### Rust 这套配置做了什么
- 开启 `cargo allFeatures`
- 开启 build scripts
- 开启 proc-macro
- 保存时保留 rust-analyzer 的诊断检查

### 你仍然需要系统工具链
`rust_analyzer` 只负责语言服务，不替代 `cargo` / `rustfmt` / `clippy`。

## Go 使用方式

### 推荐项目结构
在包含 `go.mod` 或 `go.work` 的目录下打开工程。

### 日常流程
1. `go mod init your/module`
2. 打开 `.go` 文件
3. 正常写代码，补全来自 `gopls`
4. 保存时会自动：
   - organize imports
   - format

### Go 这套配置做了什么
- `completeUnimported = true`
- `staticcheck = true`
- `gofumpt = true`
- `unusedparams` / `shadow` / `unreachable` 分析开启

### Go 缩进
Go 文件类型会自动切换为真实 tab，而不是空格。

## 调试

### 已配置
- `nvim-dap`
- `codelldb` 适配 `C` / `C++` / `Rust`

### 现在的行为
- 如果 Mason 安装了 `codelldb`，会自动优先使用 Mason 的路径
- 如果系统 `PATH` 里有 `codelldb`，也会直接使用
- 启动调试时会提示你输入可执行文件路径和参数

### 使用前提
你需要先把程序编译出来，然后再启动调试。

## 常见命令

- `:PackerSync`
- `:PackerCompile`
- `:Mason`
- `:MasonUpdate`
- `:MasonInstall clangd cmake-language-server gopls rust-analyzer lua-language-server`
- `:LspInstall clangd cmake gopls rust_analyzer lua_ls`
- `:LspInfo`
- `:TSUpdate`
- `:CMakeGenerate`
- `:CMakeBuild`
- `:CMakeRun`
- `:CMakeClean`

## 常见问题

### 1. 打开文件没有补全
- 先执行 `:LspInfo`
- 确认对应 server 已 attach
- 再执行 `:Mason` 看服务是否已安装

### 2. 有语法高亮但没有报错
- Treesitter 只管高亮
- 真正的“报错提示”来自 LSP
- 所以要检查 `:LspInfo`

### 3. C/C++ 跳转不准确
- 大概率是项目没有可用的 `compile_commands.json`
- 先跑一次 `:CMakeGenerate`

### 4. Rust 能补全但保存不格式化
- 检查 `rustfmt` 是否安装
- 可执行：

```bash
rustup component add rustfmt
```

### 5. Go 保存时报错
- 检查 `go` 和 `gopls` 是否正常
- 执行 `:LspInfo`
- 执行 `:checkhealth mason`

### 6. 更新插件后突然又报兼容错误
- 先确认你的 Neovim 版本
- 如果还是 `0.11.0-dev` 一类较早的开发版，优先升级到 `0.11.3+`
- 最新插件通常优先适配较新的稳定接口

## 相关配置文件

- `lua/plugins/lsp.lua`
  语言服务器、诊断显示、Go/Rust 保存行为
- `lua/plugins/cmp.lua`
  自动补全
- `lua/plugins/treesitter.lua`
  语法高亮
- `lua/plugins/debug.lua`
  C/C++ / Rust 调试
- `lua/plugins/cmake.lua`
  CMake 默认设置
- `lua/plugins/cmake_utils.lua`
  一键生成/编译/运行逻辑
