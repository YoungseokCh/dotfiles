return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		config = function()
			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "zenburn",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					disabled_filetypes = {
						statusline = {},
						winbar = {},
					},
					ignore_focus = {},
					always_divide_middle = true,
					always_show_tabline = true,
					globalstatus = false,
					refresh = {
						statusline = 100,
						tabline = 100,
						winbar = 100,
					},
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { "filename" },
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
				tabline = {},
				winbar = {},
				inactive_winbar = {},
				extensions = {},
			})
		end,
	},
	--     { "nvim-tree/nvim-tree.lua" },
	-- 	{
	-- 		"akinsho/bufferline.nvim",
	-- 		version = "*",
	-- 		event = "VeryLazy",
	-- 		dependencies = "nvim-tree/nvim-web-devicons",
	-- 		config = function()
	-- 			local bufferline = require("bufferline")
	-- 			bufferline.setup({
	-- 				options = {
	-- 					style_preset = bufferline.style_preset.minimal,
	-- 					offsets = {
	-- 						{
	-- 							filetype = "NvimTree",
	-- 							text = function()
	-- 								-- Dirname of the current working directory
	-- 								return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	-- 							end,
	-- 							highlight = "Directory",
	-- 							separator = true,
	-- 						},
	-- 					},
	-- 				},
	-- 			})
	-- 		end,
	-- 	},

	-- lazy.nvim
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			-- add any options here
		},
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			-- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
		},
	},
	{ "nvim-tree/nvim-web-devicons" },
}
