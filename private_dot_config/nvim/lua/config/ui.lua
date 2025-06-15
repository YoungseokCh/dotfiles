diagnostics_icons = require("config.icons").diagnostics

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostics_icons.Error,
			[vim.diagnostic.severity.WARN] = diagnostics_icons.Warn,
			[vim.diagnostic.severity.HINT] = diagnostics_icons.Hint,
			[vim.diagnostic.severity.INFO] = diagnostics_icons.Info,
		},
	},
})

require("zenburn").setup()
