vim.g.mapleader = " "
local keymap = vim.keymap

-- 插入模式
keymap.set("i", "jk", "<ESC>")
-- 视觉模式
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")
-- 正常模式
keymap.set("n", "<leader>sv", "<C-w>v") -- 水平新增窗口 
keymap.set("n", "<leader>sh", "<C-w>s") -- 垂直新增窗口

--插件
keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")
-- 切换Buffer
keymap.set("n", "<leader>l", ":bnext<CR>")
keymap.set("n", "<leader>h", ":bprevious<CR>")
-- CMake
keymap.set("n", "<leader>g", ":CMakeGenerate<CR>", { noremap = true, silent = true })
keymap.set("n", "<leader>b", ":CMakeBuild<CR>", { noremap = true, silent = true })
-- 运行默认可执行目标（自动选择或使用 vim.g.cmake_default_run_target）
keymap.set("n", "<leader>rn", function()
  require("plugins.cmake_utils").run_default()
end, { noremap = true, silent = true, desc = "CMake Run (auto)" })
-- 一键生成+编译+运行
keymap.set("n", "<leader>rr", function()
  require("plugins.cmake_utils").build_and_run()
end, { noremap = true, silent = true, desc = "CMake Generate+Build+Run" })
keymap.set("n", "<leader>c", ":CMakeClean<CR>", { noremap = true, silent = true })

-- 取消高亮

keymap.set("n", "<leader>dh", ":nohl<CR>")

-- 保存
keymap.set("n", "<leader>s",  ":w<CR>")
--开启终端
keymap.set("n", "<leader>te", ":terminal<CR>")

vim.keymap.set('n', '<leader>q', ':bd<CR>', { desc = '关闭当前 buffer' })
vim.keymap.set('n', '<leader>Q', ':bd!<CR>', { desc = '强制关闭当前 buffer' })

