require("config.lazy")
require("config.autocomplete")
require("config.command")
require("config.keymap")
require("config.ui")

-- Vim native settings
vim.o.autoindent = true
vim.o.number = true
-- vim.o.smartindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- begin nvim-tree
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

require("nvim-tree").setup({
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 30,
	},
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = true,
	},
})
-- end nvim-tree

require("mason").setup()
require("mason-lspconfig").setup()
require("mason-nvim-lint").setup({
	-- A list of linters to automatically install if they're not already installed. Example: { "eslint_d", "revive" }
	-- This setting has no relation with the `automatic_installation` setting.
	-- Names of linters should be taken from the mason's registry.
	---@type string[]
	ensure_installed = {},

	-- Whether linters that are set up (via nvim-lint) should be automatically installed if they're not already installed.
	-- It tries to find the specified linters in the mason's registry to proceed with installation.
	-- This setting has no relation with the `ensure_installed` setting.
	---@type boolean
	automatic_installation = false,

	-- Disables warning notifications about misconfigurations such as invalid linter entries and incorrect plugin load order.
	quiet_mode = false,
})

-- TreeSitter

require("nvim-treesitter.configs").setup({
	-- A list of parser names, or "all" (the listed parsers MUST always be installed)
	ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },

	indent = { enable = true },

	-- Install parsers synchronously (only applied to `ensure_installed`)
	sync_install = false,

	-- Automatically install missing parsers when entering buffer
	-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
	auto_install = true,

	-- List of parsers to ignore installing (or "all")
	ignore_install = { "javascript", "htmldjango" },

	---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
	-- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

	highlight = {
		enable = true,

		-- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
		-- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
		-- the name of the parser)
		-- list of language that will be disabled
		-- disable = { "c", "rust" },
		-- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
		disable = function(lang, buf)
			local max_filesize = 100 * 1024 -- 100 KB
			local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
			if lang == "html" then
				return true
			end
			if ok and stats and stats.size > max_filesize then
				return true
			end
		end,

		-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
		-- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
		-- Using this option may slow down your editor, and you may see some duplicate highlights.
		-- Instead of true it can also be a list of languages
		additional_vim_regex_highlighting = false,
	},
})

require("zenburn").setup()
