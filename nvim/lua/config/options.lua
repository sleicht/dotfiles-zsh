-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.editorconfig = false

-- Use treesitter for folding
--- config/options.lua
local vim = vim
local opt = vim.opt

opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"

vim.lsp.set_log_level("info")

-- change the font
opt.guifont = "JetBrains Mono:h16"
-- change line spacing
opt.linespace = 2

-- Neovide specific options
if vim.g.neovide then
  vim.g.neovide_transparency = 0.9
  vim.g.neovide_hide_mouse_when_typing = false
  vim.g.neovide_input_macos_option_key_is_meta = "only_left"
  vim.g.neovide_window_blurred = true
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0
  vim.g.neovide_show_border = true
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_cursor_trail_size = 0.3
  vim.g.neovide_cursor_animation_length = 0.03
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_cursor_vfx_particle_density = 34.0
  vim.g.neovide_cursor_vfx_particle_lifetime = 1.2
  vim.g.neovide_cursor_vfx_opacity = 300.0
  vim.keymap.set({ "n", "v", "s", "x", "o", "i", "l", "c", "t" }, "<D-v>", function()
    vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
  end, { noremap = true, silent = true })
end
