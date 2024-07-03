-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

--wezterm.on('gui-startup', function()
--	local tab, pane, window = mux.spawn_window({})
--	window:gui_window():maximize()
--end)

local config = wezterm.config_builder()

config.inactive_pane_hsb = {
	saturation = 0.8,
	brightness = 0.7
}
config.color_scheme = 'Dracula (Official)'

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 12

config.use_dead_keys = false
config.scrollback_lines = 5000
config.adjust_window_size_when_changing_font_size = false
config.hide_tab_bar_if_only_one_tab = true

config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = true

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 8

config.window_frame = {
	font = wezterm.font { family = 'Noto Sans', weight = 'Regular' },
}

config.disable_default_key_bindings = true

config.keys = {
	{ mods = 'SUPER',     key = 'k',          action = act.Multiple { act.ClearScrollback 'ScrollbackAndViewport', act.SendKey { key = 'L', mods = 'CTRL' } } },
	{ mods = "OPT",       key = "LeftArrow",  action = act.SendKey({ mods = "ALT", key = "b" }) },
	{ mods = "OPT",       key = "RightArrow", action = act.SendKey({ mods = "ALT", key = "f" }) },
	{ mods = "CMD",       key = "LeftArrow",  action = act.SendKey({ mods = "CTRL", key = "a" }) },
	{ mods = "CMD",       key = "RightArrow", action = act.SendKey({ mods = "CTRL", key = "e" }) },
	{ mods = "CMD",       key = "Backspace",  action = act.SendKey({ mods = "CTRL", key = "u" }) },
	{ mods = "CMD|OPT",   key = "LeftArrow",  action = act.ActivateTabRelative(-1) },
	{ mods = "CMD|OPT",   key = "RightArrow", action = act.ActivateTabRelative(1) },
	{ mods = "CMD|SHIFT", key = "LeftArrow",  action = act.ActivateTabRelative(-1) },
	{ mods = "CMD|SHIFT", key = "RightArrow", action = act.ActivateTabRelative(1) },

	{ mods = 'OPT',       key = 'j',          action = act.ActivatePaneDirection 'Down', },
	{ mods = 'OPT',       key = 'k',          action = act.ActivatePaneDirection 'Up', },
	{ mods = 'OPT',       key = 'Enter',      action = act.ActivateCopyMode },
	{ mods = 'SUPER',     key = 'n',          action = act.SpawnWindow },
	{ mods = 'OPT',       key = 'f',          action = act.SplitVertical { domain = 'CurrentPaneDomain' }, },
	{ mods = 'OPT',       key = 'd',          action = act.SplitHorizontal { domain = 'CurrentPaneDomain' }, },
	{ mods = 'OPT',       key = 'h',          action = act.ActivatePaneDirection 'Left', },
	{ mods = 'OPT',       key = 'l',          action = act.ActivatePaneDirection 'Right', },
	{ mods = 'CMD',       key = 'w',          action = act.CloseCurrentTab { confirm = false } },
	{ mods = 'CMD',       key = 'x',          action = act.CloseCurrentPane { confirm = false } },
  { mods = 'CMD',       key = 't',          action = act.SpawnTab 'CurrentPaneDomain' },
}

-- and finally, return the configuration to wezterm
return config
