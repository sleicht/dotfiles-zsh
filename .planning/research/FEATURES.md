# Feature Landscape

**Domain:** chezmoi dotfiles migration (subsequent milestone)
**Researched:** 2026-02-08

## Table Stakes

Features users expect for dotfiles migration to chezmoi. Missing these = incomplete migration.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Static config file migration | Basic chezmoi functionality | Low | Terminal emulators (kitty, ghostty, wezterm), window managers (aerospace), CLI tools (bat, lsd, btop, oh-my-posh) |
| Directory structure preservation | Maintains tool expectations | Low | Tools expect configs in specific locations (~/.config/xyz, ~/.xyzrc) |
| Machine-specific templating | Cross-platform/multi-machine setup | Medium | OS differences (Darwin vs Linux), machine type (client vs personal), paths |
| Dev tool configs migration | Complete development environment | Low | lazygit, atuin, psqlrc, sqliterc, aider, finicky - mostly static |
| Basic dotfiles migration | Standard Unix dotfiles | Low | .hushlogin, .inputrc, .editorconfig, .nanorc - simple copies |
| GPG agent config | Security/encryption workflow | Low | Simple config with machine-specific pinentry path |
| Dotbot retirement | Clean up old system | Low | Remove install script, steps/, zgenom/dotbot submodules |
| Drop deprecated configs | Housekeeping | Low | Remove nushell (not using), zgenom (using sheldon instead) |

## Differentiators

Features that improve the migration beyond basic functionality.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Claude Code directory with selective encryption | Share commands/skills across machines, protect sensitive settings | Medium | Age-encrypt settings.json (may contain tokens), sync CLAUDE.md, commands/, agents/, skills/ |
| Per-machine ignore patterns | Keep local overrides separate | Low | Use .chezmoiignore with templates to exclude machine-specific state files |
| zsh-abbr abbreviations templating | Machine-specific abbreviations | Low | Work vs personal abbreviations, OS-specific commands |
| Karabiner config templating | Different keyboard mappings per machine | Medium | Complex JSON, may differ between keyboards/machines |
| Terminal emulator theme templating | Consistent themes across tools | Medium | Font/color coordination across kitty/ghostty/wezterm |
| Aerospace workspace config templating | Monitor setup varies by machine | Low | Laptop vs desktop workspace layouts |
| Run-once install scripts | Automate missing tool installation | Medium | Check and install terminal emulators, window managers if missing |
| Private directory modifiers | Protect sensitive configs automatically | Low | Use private_ for .gnupg/, .ssh/ related configs |
| Finicky browser rules templating | Different work/personal browser routing | Low | Chrome vs other browsers, work domains route to specific profiles |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Migrating nushell configs | Not actively using nushell | Drop entirely - clutters dotfiles |
| Migrating zgenom | Replaced by sheldon | Drop entirely - already migrated to sheldon |
| Keeping Dotbot alongside chezmoi | Dual systems create confusion | Full cutover - retire Dotbot completely |
| Templating every config file | Over-engineering static configs | Template only when machine differences exist |
| Committing .chezmoi.toml to repo | Machine-specific, may contain local paths | Keep in ~/.config/chezmoi/, gitignore it |
| Syncing Claude Code local state | Session-specific data shouldn't roam | Only sync CLAUDE.md, commands/, agents/, skills/ - ignore settings.local.json |
| Managing Homebrew Brewfiles in two places | Already handled via mise/chezmoi data | Brewfiles stay in current location, not duplicated |
| Exact directory modifiers on configs that tools modify | Tools like karabiner write state back | Let tools manage their own state files |

## Feature Dependencies

```
Static config migration (table stakes)
  ↓
Machine-specific templating (table stakes)
  ↓
Per-machine ignore patterns (differentiator)

Dotbot retirement (table stakes)
  ↓
Drop deprecated configs (table stakes)

Claude Code migration (differentiator)
  ↓
Selective encryption setup (differentiator)
  ↓
Age key management (already exists from Phase 3)
```

## MVP Recommendation

Prioritize for immediate migration:

1. **Static configs** - Terminal emulators, window manager, CLI tools, dev tools, basic dotfiles (table stakes)
2. **GPG agent** - Simple, needed for security workflow (table stakes)
3. **Machine-specific templating** - OS detection for paths (table stakes - needed for cross-platform)
4. **Dotbot retirement** - Clean up old system once configs migrated (table stakes)
5. **Drop deprecated** - Remove nushell/zgenom configs (table stakes)

Defer to "nice-to-have":

- **Claude Code selective encryption**: Medium complexity, requires age key setup consideration. Start with unencrypted sync, add encryption later if needed.
- **Theme coordination**: Nice-to-have, can start with static themes and coordinate later if desired.
- **Run-once scripts**: Tools should already be installed via Brewfile, scripts add complexity.
- **Karabiner templating**: Complex JSON, likely static per machine anyway.

## Complexity Analysis

### Low Complexity (straightforward copy/template)
- Terminal emulator configs (kitty, ghostty, wezterm)
- Aerospace config
- CLI tool configs (bat, lsd, btop, oh-my-posh)
- Dev tools (lazygit, atuin, psqlrc, sqliterc, aider)
- Basic dotfiles (.hushlogin, .inputrc, .editorconfig, .nanorc)
- Finicky config
- zsh-abbr abbreviations
- GPG agent config
- Dotbot/zgenom/nushell removal

### Medium Complexity (requires templating/encryption decisions)
- Claude Code directory (encryption decision, what to sync vs ignore)
- Karabiner config (complex JSON structure)
- OS-specific path templating (pinentry, tool paths)

### Dependencies on Existing Setup
- **Age encryption**: Already set up in Phase 3 for SSH keys
- **Machine type detection**: Already configured via .chezmoidata.yaml (client vs personal)
- **OS detection**: Built-in chezmoi variable (.chezmoi.os)
- **Bitwarden templating**: Already working for git config
- **Homebrew package management**: Already handled via mise and run scripts

## Migration Strategy

### Phase 1: Core Configs (Low-Hanging Fruit)
1. Add static configs to chezmoi (no templating needed):
   - Terminal emulators: `chezmoi add ~/.config/kitty/kitty.conf ~/.config/ghostty/config ~/.wezterm.lua`
   - Window manager: `chezmoi add ~/.config/aerospace/aerospace.toml`
   - CLI tools: `chezmoi add ~/.config/{bat,lsd,btop}/config* ~/.config/oh-my-posh.omp.json`
   - Dev tools: `chezmoi add ~/.config/lazygit/config.yml ~/.config/atuin ~/.psqlrc ~/.sqliterc ~/.aider.conf.yml ~/.finicky.js`
   - Basic: `chezmoi add ~/.hushlogin ~/.inputrc ~/.editorconfig ~/.nanorc`
   - zsh-abbr: `chezmoi add ~/.config/zsh-abbr/user-abbreviations`

### Phase 2: Templating for Machine Differences
2. Add templating where needed:
   - GPG agent: Template pinentry path (Darwin: /run/current-system/sw/bin/pinentry-mac, Linux: varies)
   - Finicky: Template default browser (work vs personal)
   - Aerospace: Template workspace layout (laptop vs desktop)
   - zsh-abbr: Template work-specific vs personal abbreviations

### Phase 3: Claude Code Directory
3. Handle Claude Code configs:
   - Add CLAUDE.md, commands/, agents/, skills/ to chezmoi
   - Decision: Encrypt settings.json or use .chezmoiignore?
   - Add settings.local.json to .chezmoiignore (local overrides)

### Phase 4: Cleanup
4. Remove deprecated systems:
   - Delete .config/nushell/
   - Delete zgenom submodule
   - Delete Dotbot install script and steps/
   - Delete Dotbot submodule
   - Update README to reflect chezmoi-only setup

## Machine-Specific Considerations

### What Needs Templating?

| Config | Template? | Why |
|--------|-----------|-----|
| kitty.conf | Maybe | Font paths, theme might differ |
| ghostty config | Maybe | Font paths, theme might differ |
| wezterm.lua | Maybe | Font paths, theme might differ |
| aerospace.toml | Yes | Monitor/workspace setup differs laptop vs desktop |
| bat config | No | Static theme/style |
| lsd config | No | Static icons/layout |
| btop.conf | Maybe | Color theme coordination |
| oh-my-posh.omp.json | Maybe | Theme differs work vs personal |
| lazygit.yml | No | Git workflow consistent |
| atuin config.toml | No | History settings consistent |
| psqlrc | No | PostgreSQL formatting consistent |
| sqliterc | No | SQLite formatting consistent |
| aider.conf.yml | Maybe | Model selection work vs personal |
| finicky.js | Yes | Browser routing differs work vs personal |
| .hushlogin | No | Static |
| .inputrc | No | Static readline config |
| .editorconfig | No | Static editor defaults |
| .nanorc | No | Static nano config |
| gpg-agent.conf | Yes | Pinentry path differs by OS |
| karabiner.json | Maybe | Keyboard mappings per machine/keyboard |
| zsh-abbr | Yes | Work abbreviations vs personal |
| Claude Code | Partial | CLAUDE.md/commands sync, settings.json might need encryption |

### Template Variables Needed

Already available from existing setup:
- `.chezmoi.os` - "darwin" or "linux"
- `.machine_type` - "client" or "personal" (from .chezmoidata.yaml)
- `.chezmoi.hostname` - For very specific machine differences

May need to add:
- `.monitor_setup` - "laptop" or "desktop" (for aerospace)
- `.terminal_theme` - Coordinated theme name

## Sources

### Chezmoi Documentation
- [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)
- [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Manage different types of file - chezmoi](https://www.chezmoi.io/user-guide/manage-different-types-of-file/)
- [Use scripts to perform actions - chezmoi](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [.chezmoiignore - chezmoi](https://www.chezmoi.io/reference/special-files/chezmoiignore/)
- [Target types - chezmoi](https://www.chezmoi.io/reference/target-types/)

### Migration Best Practices
- [Migrating a pre-existing dotfiles repository · twpayne/chezmoi · Discussion #2330](https://github.com/twpayne/chezmoi/discussions/2330)
- [How To Manage Dotfiles With Chezmoi](https://jerrynsh.com/how-to-manage-dotfiles-with-chezmoi/)
- [Managing dotfiles with Chezmoi | Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/)
- [Taking Control of My Dotfiles with chezmoi](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/)

### Claude Code Configuration
- [Sync Claude Code commands and hooks across machines](https://www.arun.blog/sync-claude-code-with-chezmoi-and-age/)
- [claude-code-mastery/docs/guides/dotfiles-sync.md](https://github.com/NovaAI-innovation/claude-code-mastery/blob/main/docs/guides/dotfiles-sync.md)
- [.claude - Your Claude Code Directory](https://dotclaude.com/)

### Terminal Emulators
- [The Modern Terminals Showdown: Alacritty, Kitty, and Ghostty](https://blog.codeminer42.com/modern-terminals-alacritty-kitty-and-ghostty/)
- [Choosing a Terminal on macOS (2025): iTerm2 vs Ghostty vs WezTerm vs kitty vs Alacritty](https://medium.com/@dynamicy/choosing-a-terminal-on-macos-2025-iterm2-vs-ghostty-vs-wezterm-vs-kitty-vs-alacritty-d6a5e42fd8b3)

### Window Manager
- [GitHub - nikitabobko/AeroSpace: AeroSpace is an i3-like tiling window manager for macOS](https://github.com/nikitabobko/AeroSpace)
- [How To Setup And Use The Aerospace Tiling Window Manager On macOS](https://www.josean.com/posts/how-to-setup-aerospace-tiling-window-manager)
