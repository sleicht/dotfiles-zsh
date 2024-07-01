-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Dracula (Official)'

config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 12

config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = true
config.window_decorations = "RESIZE"

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.75
config.macos_window_background_blur = 8

config.keys = {
  { mods = 'SUPER', key = 'K', action = act.Multiple { act.ClearScrollback 'ScrollbackAndViewport', act.SendKey { key = 'L', mods = 'CTRL' }, }, },
  { mods = "OPT", key = "LeftArrow", action = act.SendKey({ mods = "ALT", key = "b" }) },
  { mods = "OPT", key = "RightArrow", action = act.SendKey({ mods = "ALT", key = "f" }) },
  { mods = "CMD", key = "LeftArrow", action = act.SendKey({ mods = "CTRL", key = "a" }) },
  { mods = "CMD", key = "RightArrow", action = act.SendKey({ mods = "CTRL", key = "e" }) },
  { mods = "CMD", key = "Backspace", action = act.SendKey({ mods = "CTRL", key = "u" }) },
  { mods = "CMD|OPT", key = "LeftArrow", action = act.ActivateTabRelative(-1) },
  { mods = "CMD|OPT", key = "RightArrow", action = act.ActivateTabRelative(1) },
  { mods = "CMD|SHIFT", key = "LeftArrow", action = act.ActivateTabRelative(-1) },
  { mods = "CMD|SHIFT", key = "RightArrow", action = act.ActivateTabRelative(1) },
}

-- and finally, return the configuration to wezterm
return config
