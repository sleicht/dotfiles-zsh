# Dotfiles Stack Migration

## What This Is

Migration of ZSH dotfiles from the current Nix/Dotbot/Zgenom/asdf stack to a simplified chezmoi/mise/Homebrew/Sheldon stack. The goal is to reduce complexity while maintaining cross-platform support for macOS and Linux, with machine-specific templating capabilities.

## Core Value

**Cross-platform dotfiles that "just work"** — one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Remove Nix completely (nix-config/, nix-darwin, home-manager)
- [ ] Migrate all Dotbot symlinks to chezmoi
- [ ] Add chezmoi templating for OS-specific configurations (macOS vs Linux)
- [ ] Add chezmoi templating for machine-specific configurations (work vs personal)
- [ ] Replace asdf with mise for runtime version management
- [ ] Move runtime tools (node, python, go, rust) to mise
- [ ] Keep CLI tools in Homebrew (pragmatic — works well on both platforms)
- [ ] Migrate Sheldon configuration to be managed by chezmoi
- [ ] Ensure shell startup time is not degraded
- [ ] Document the new setup for future maintenance

### Out of Scope

- Moving all Homebrew packages to mise — most CLI tools work fine in Homebrew
- Windows support — not a current need
- Nix-style reproducibility — accepting Homebrew version drift as trade-off
- Changing terminal emulator setup — keep current Ghostty/WezTerm/Kitty configs

## Context

**Current state (from codebase analysis):**
- 4 installation layers: Dotbot symlinks, Zgenom plugins, Homebrew packages, Nix configuration
- Nix exists on `feature/nix` branch with nix-darwin and Home Manager
- ~159 packages in Brewfile across global and machine-specific files
- Sheldon already replacing Zgenom for plugin management
- mise already installed but not primary tool manager

**Existing patterns to preserve:**
- Modular shell configuration in `zsh.d/*.zsh` files
- Machine-specific Brewfiles (`Brewfile_Client`, `Brewfile_Fanaka`)
- Private zsh files loaded from `~/.zsh.d.private/`
- Tool-specific configs in `.config/` directory

**Target machines:**
- macOS (Apple Silicon) — primary development
- Linux (Ubuntu/Debian) — servers and containers

## Constraints

- **Cross-platform**: Must work on macOS (Homebrew) and Linux (apt/Homebrew)
- **Backwards compatible**: Existing shell functionality must not break during migration
- **Incremental**: Migration should be reversible at each phase
- **No secrets in git**: Use chezmoi encryption or 1Password integration for sensitive configs

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| chezmoi over Dotbot | Templating for OS/machine differences, built-in secret handling | — Pending |
| mise over asdf | Faster, more backends (aqua, cargo, npm), better ergonomics | — Pending |
| Keep Homebrew for CLI tools | Works on both platforms, well-maintained, familiar | — Pending |
| Keep Sheldon for ZSH plugins | Already in use, fast, simple | — Pending |

---
*Last updated: 2026-01-25 after initialization*
