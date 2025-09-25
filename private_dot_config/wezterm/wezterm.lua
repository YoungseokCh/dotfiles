local default_opacity = 0.9
local wezterm = require("wezterm")
local keymaps = {}

table.insert(keymaps, {
	key = "Z",
	mods = "SHIFT|CTRL",
	action = wezterm.action.EmitEvent("decrease-opacity"),
})

table.insert(keymaps, {
	key = "X",
	mods = "SHIFT|CTRL",
	action = wezterm.action.EmitEvent("increase-opacity"),
})

wezterm.on("increase-opacity", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	local opacity = overrides.window_background_opacity
	if opacity == nil then
		opacity = default_opacity
	end

	opacity = opacity + 0.1
	if opacity > 1.0 then
		opacity = 1.0
	end
	overrides.window_background_opacity = opacity

	window:set_config_overrides(overrides)
end)

wezterm.on("decrease-opacity", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	local opacity = overrides.window_background_opacity

	if opacity == nil then
		opacity = default_opacity
	end

	opacity = opacity - 0.1
	if opacity < 0.3 then
		opacity = 0.3
	end
	overrides.window_background_opacity = opacity

	window:set_config_overrides(overrides)
end)

table.insert(keymaps, {
	key = "`",
	mods = "CTRL",
	action = wezterm.action.PromptInputLine({
		description = "Enter new name for tab",
		action = wezterm.action_callback(function(window, _, line)
			if line then
				window:active_tab():set_title(line)
			end
		end),
	}),
})

return {
	color_scheme = "Zenburn",
	keys = keymaps,
	window_padding = {
		bottom = 0,
	},
	hide_tab_bar_if_only_one_tab = true,
}
