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
keymap.set("n", "<leader>rn", ":CMakeRun", { noremap = true, silent = true })
keymap.set("n", "<leader>c", ":CMakeClean<CR>", { noremap = true, silent = true })
-- 保存
keymap.set("n", "<leader>s",  ":w<CR>")


