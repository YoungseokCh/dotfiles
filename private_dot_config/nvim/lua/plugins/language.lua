return {
	"mason-org/mason.nvim",
	"mason-org/mason-lspconfig.nvim",
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				jinja_lsp = {
					filetypes = { "jinja", "html" },
				},
			},
		},
	},
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
}
