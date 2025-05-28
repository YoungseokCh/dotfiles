for type, icon in pairs(require("config.icons").diagnostics) do
	local hl = "DiagnosticSign" .. type

	vim.api.nvim_set_sign(hl, {
		text = icon,
		texthl = hl,
		numhl = hl,
	})
end
