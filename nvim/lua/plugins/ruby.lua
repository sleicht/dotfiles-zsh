return {
  -- Mason, Mason-LSPConfig, and LSPConfig setup
  {
    "williamboman/mason.nvim",
    run = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "solargraph" }, -- additional language servers as needed
      })

      local lspconfig = require("lspconfig")

      -- Example configuration for Solargraph with asdf
      lspconfig.solargraph.setup({
        cmd = { "asdf", "exec", "solargraph", "stdio" },
        filetypes = { "ruby" },
        root_dir = lspconfig.util.root_pattern("Gemfile", ".git"),
      })
    end,
  },
}
