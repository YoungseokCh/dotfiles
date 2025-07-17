-- Editor options
vim.o.autoindent = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = false
vim.o.smartindent = false
vim.o.wrap = true
vim.o.cursorline = true
vim.o.laststatus = 3

-- Search options
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true

-- UI options
vim.o.termguicolors = false
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

-- keys
vim.keymap.set("n", "<C-_>", function()
	vim.cmd.norm("gcc")
end)

vim.keymap.set("v", "<C-_>", function()
	vim.cmd.norm("gcgv")
end)

vim.keymap.set("v", "<Tab>", function()
	vim.cmd.norm(">gv")
end)

vim.keymap.set("v", "<S-Tab>", function()
	vim.cmd.norm("<gv")
end)

-- Diagnostic icons
local signs = {
	Error = " ",
	Warning = " ",
	Hint = " ",
	Information = " ",
}

for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
