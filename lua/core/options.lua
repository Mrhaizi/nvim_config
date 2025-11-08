local opt = vim.opt

-- 行号
opt.number = true

-- 缩进
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- 防止自动换行
opt.wrap = false

-- 光标行高亮
opt.cursorline = true

-- 启用鼠标
opt.mouse:append("a")

-- 启用系统剪切板
opt.clipboard:append("unnamedplus")

-- 新窗口默认在右下
opt.splitright = true
opt.splitbelow = true

-- 外观
opt.termguicolors = true
opt.signcolumn = "yes"

-- ============ 🔹 Tokyonight 主题配置 ============
require("tokyonight").setup({
  style = "moon",             -- 使用 moon 风格
  transparent = true,         -- 启用透明背景
  styles = {
    sidebars = "transparent", -- 边栏透明
    floats = "transparent",   -- 浮动窗口透明
  },
})
vim.cmd[[colorscheme tokyonight]]

-- 防止主题重置背景的自动命令（可选）
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.cmd [[
      hi Normal guibg=none ctermbg=none
      hi NormalNC guibg=none ctermbg=none
      hi NormalFloat guibg=none ctermbg=none
      hi SignColumn guibg=none ctermbg=none
      hi EndOfBuffer guibg=none ctermbg=none
    ]]
  end,
})

