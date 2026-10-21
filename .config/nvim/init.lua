-- Minimal Neovim config. Installed now so switching the main editor later is one command:
--   dot-editor nvim
-- Plugins are managed by lazy.nvim, which bootstraps itself on first start.
vim.g.mapleader = " "

local o = vim.opt
o.number = true
o.relativenumber = true
o.termguicolors = true
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.signcolumn = "yes"
o.scrolloff = 8
o.clipboard = "unnamedplus"
o.undofile = true
o.splitright = true
o.splitbelow = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "folke/tokyonight.nvim", priority = 1000,
    config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight")
    end },
  { "nvim-telescope/telescope.nvim", branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Search text" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
    } },
  { "lewis6991/gitsigns.nvim", opts = {} },
}, { checker = { enabled = false } })

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
