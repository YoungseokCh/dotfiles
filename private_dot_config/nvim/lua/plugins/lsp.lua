-- LSP, completion, and formatting plugins
return {
	-- Mason LSP installer
	{
		"mason-org/mason.nvim",
		opts = { ensure_installed = { "gitui" } },
		keys = {
			{
				"<leader>gG",
				function()
					Snacks.terminal({ "gitui" })
				end,
				desc = "GitUi (cwd)",
			},
			{
				"<leader>gg",
				function()
					Snacks.terminal({ "gitui" }, { cwd = LazyVim.root.get() })
				end,
				desc = "GitUi (Root Dir)",
			},
		},
		init = function()
			-- delete lazygit keymap for file history
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimKeymaps",
				once = true,
				callback = function()
					pcall(vim.keymap.del, "n", "<leader>gf")
					pcall(vim.keymap.del, "n", "<leader>gl")
				end,
			})
		end,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
	},

	-- Completion engine and sources
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
	},

	-- Linting and formatting
	"mfussenegger/nvim-lint",
	{
		"rshkarin/mason-nvim-lint",
		config = function()
			require("mason-nvim-lint").setup({
				ensure_installed = {},
				automatic_installation = false,
				quiet_mode = false,
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = false,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				rust = { "rustfmt", lsp_format = "fallback" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				html = { "prettierd", "prettier", stop_after_first = true },
				markdown = { "prettierd", "prettier", stop_after_first = true },
			},
			notify_no_formatters = true,
		},
	},
}
