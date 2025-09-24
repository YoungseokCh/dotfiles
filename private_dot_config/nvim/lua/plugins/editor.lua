-- Editor enhancement plugins
return {

	-- Telescope fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
			vim.keymap.set("n", "<leader>p", builtin.find_files, { desc = "Telescope find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
			vim.keymap.set(
				"n",
				"<leader>fu",
				':lua require("telescope.builtin").lsp_references()<CR>',
				{ noremap = true, silent = true }
			)
		end,
	},

	{
		"folke/snacks.nvim",
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			dashboard = {
				sections = {
					{ section = "keys", gap = 1, padding = 1 },
					{ section = "startup" },
				},
			},
			explorer = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			picker = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
			scroll = { enabled = true },
		},
	},
}
