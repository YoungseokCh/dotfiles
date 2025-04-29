require ("config.lazy")

local Plug = vim.fn['plug#']
vim.call('plug#begin', './.config/nvim/plugged')
Plug('preservim/nerdtree')
vim.call('plug#end')

-- setup must be called before loading
vim.cmd.colorscheme "catppuccin-macchiato"
