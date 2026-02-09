---
status: investigating
trigger: "Investigate why changing the bat theme to Dracula in ~/.config/bat/config doesn't change bat's output theme."
created: 2026-02-09T00:00:00Z
updated: 2026-02-09T00:00:01Z
---

## Current Focus

hypothesis: BAT_THEME environment variable in zsh.d/variables.zsh overrides config file
test: confirmed location of BAT_THEME export
expecting: root cause confirmed
next_action: document resolution

## Symptoms

expected: bat should use Dracula theme when set in ~/.config/bat/config
actual: changing theme in config file doesn't affect bat output
errors: none reported
reproduction: edit ~/.config/bat/config to set theme=Dracula, run bat on a file
started: after Phase 8 migration from Dotbot symlink to chezmoi-managed real file

## Eliminated

## Evidence

- timestamp: 2026-02-09T00:00:00Z
  checked: ~/.config/bat/config
  found: theme is set to --theme="Dracula" (line 7)
  implication: config file is correct

- timestamp: 2026-02-09T00:00:01Z
  checked: bat --config-file
  found: bat is loading /Users/stephanlv_fanaka/.config/bat/config
  implication: bat is reading the correct config file

- timestamp: 2026-02-09T00:00:02Z
  checked: environment variables (env | grep -i bat)
  found: BAT_THEME=gruvbox-dark
  implication: environment variable overrides config file setting

- timestamp: 2026-02-09T00:00:03Z
  checked: bat --list-themes
  found: Dracula theme exists
  implication: theme is available, not a missing theme issue

- timestamp: 2026-02-09T00:00:04Z
  checked: searched for BAT_THEME in codebase
  found: zsh.d/variables.zsh line 95 exports BAT_THEME="$SOBOLE_SYNTAX_THEME"
  implication: shell environment variable overrides config file

- timestamp: 2026-02-09T00:00:05Z
  checked: zsh.d/variables.zsh line 10
  found: SOBOLE_SYNTAX_THEME="gruvbox-dark"
  implication: BAT_THEME is set to gruvbox-dark every time shell loads

## Resolution

root_cause: The BAT_THEME environment variable is set in zsh.d/variables.zsh (line 95) to "$SOBOLE_SYNTAX_THEME" which equals "gruvbox-dark" (line 10). Environment variables take precedence over config file settings in bat, so the --theme="Dracula" setting in ~/.config/bat/config is ignored.
fix: Change SOBOLE_SYNTAX_THEME from "gruvbox-dark" to "Dracula" in zsh.d/variables.zsh line 10, OR remove the BAT_THEME export entirely (line 95) to let the config file control the theme.
verification: After changing, restart shell or source variables.zsh, then run bat on a file to verify Dracula theme is applied.
files_changed: []
