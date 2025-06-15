-- Neovim native settings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Editor options
vim.o.autoindent = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = false
vim.o.cursorline = true

-- Search options
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true

-- UI options
vim.o.termguicolors = true
vim.o.signcolumn = "yes"
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Completion options
vim.opt.completeopt = "menu,menuone,noselect"

-- Backup and undo
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.undofile = true

-- Clipboard
vim.o.clipboard = "unnamedplus"

-- Icons configuration
local icons = {
	diagnostics = {
		Error = " ",
		Warn = " ",
		Hint = " ",
		Info = " ",
	},
	git = {
		added = " ",
		modified = " ",
		removed = " ",
	},
	kinds = {
		Array = " ",
		Boolean = " ",
		Class = " ",
		Color = " ",
		Constant = " ",
		Constructor = " ",
		Copilot = " ",
		Enum = " ",
		EnumMember = " ",
		Event = " ",
		Field = " ",
		File = " ",
		Folder = "󰉋 ",
		Function = " ",
		Interface = " ",
		Key = " ",
		Keyword = " ",
		Method = " ",
		Module = " ",
		Namespace = " ",
		Null = " ",
		Number = " ",
		Object = " ",
		Operator = " ",
		Package = " ",
		Property = " ",
		Reference = " ",
		Snippet = " ",
		String = " ",
		Struct = " ",
		Text = " ",
		TypeParameter = " ",
		Unit = " ",
		Value = " ",
		Variable = " ",
	},
}

-- Configure diagnostics with icons
vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
			[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
			[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
			[vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
		},
	},
})

-- Filetype detection for Go HTML templates
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "*.html",
	callback = function()
		local lines = vim.api.nvim_buf_get_lines(0, 0, 500, false)
		for _, line in ipairs(lines) do
			if line:match("{{") then
				vim.bo.filetype = "gohtmltmpl"
				break
			end
		end
	end,
	group = vim.api.nvim_create_augroup("GoHtmlTmplDetect", { clear = true }),
})

-- Export icons for use in other modules
_G.nvim_icons = icons
