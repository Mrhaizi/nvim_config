require'nvim-treesitter.configs'.setup {
  ensure_installed = { "vim", "bash", "c", "cpp", "javascript", "json", "lua", "python", "typescript", "tsx", "css", "rust", "markdown", "markdown_inline", "go", "gomod", "gowork" }, 
  highlight = { 
    enable = true, 
  },
  indent = { 
    enable = true, 
  }
}

