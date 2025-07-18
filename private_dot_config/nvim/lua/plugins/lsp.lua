-- LSP, completion, and formatting plugins
return {
	-- {
	--  "nmac427/guess-indent.nvim",
	--     config = function()
	--         require('guess-indent').setup()
	--     end
	-- },
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
		},
		config = function()
			local cmp_status, cmp = pcall(require, "cmp")
			if not cmp_status then
				return
			end

			local luasnip_status, luasnip = pcall(require, "luasnip")
			if not luasnip_status then
				return
			end

			require("luasnip/loaders/from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-k>"] = cmp.mapping.select_prev_item(),
					["<C-j>"] = cmp.mapping.select_next_item(),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						elseif
							vim.fn.col(".") - 1 == 0
							or vim.fn.getline("."):sub(vim.fn.col(".") - 1, vim.fn.col(".") - 1):match("%s")
						then
							fallback()
						else
							cmp.complete()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},

	-- Snippet engine
	"rafamadriz/friendly-snippets",

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
