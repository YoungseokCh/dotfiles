return {
	"mason-org/mason.nvim",
	"mason-org/mason-lspconfig.nvim",
	"neovim/nvim-lspconfig",
	"hrsh7th/nvim-cmp", -- Completion engine
	"hrsh7th/cmp-nvim-lsp", -- LSP completion source for nvim-cmp
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
	"rafamadriz/friendly-snippets",
	"mfussenegger/nvim-lint",
	"rshkarin/mason-nvim-lint",
	"alker0/chezmoi.vim",

	{
		"ray-x/go.nvim",
		dependencies = { -- optional packages
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			-- lsp_keymaps = false,
			-- other options
		},
		config = function(lp, opts)
			require("go").setup(opts)
			local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.go",
				callback = function()
					require("go.format").goimports()
				end,
				group = format_sync_grp,
			})
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
	},
}
