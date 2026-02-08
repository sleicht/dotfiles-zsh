# Stack Analysis: v1.1 Complete Migration

**Research Date:** 2026-02-08
**Context:** Migrating remaining Dotbot-managed configs to chezmoi, retiring Dotbot
**Target:** Complete chezmoi ownership of all dotfiles

## Existing Stack (No Changes Needed)

- **chezmoi** — Already managing core dotfiles, templates, age encryption, Bitwarden
- **mise** — Runtime version management (7 runtimes)
- **Homebrew** — CLI tool packages via .chezmoidata.yaml
- **Sheldon** — ZSH plugin management
- **Bitwarden** — Secret provider for chezmoi templates
- **age** — SSH key encryption

## chezmoi Features Needed for New Migrations

### 1. exact_ Directories (Claude Code)

Required for managing the .claude/ directory (~50+ files). Ensures chezmoi manages the full directory tree, removing files not in source.

**CAUTION:** Dangerous with nested configs. Use .chezmoiignore for cache/temp files.

### 2. .chezmoiignore (Multiple Configs)

Pattern-based ignore for selective sync. Required for:
- .claude/cache/, .claude/settings.local.json
- Dynamically generated configs
- Terminal emulator cache files (kitty, ghostty, wezterm)

Note: .chezmoiignore is always interpreted as a template (can use conditionals).

### 3. Machine-Specific Templates (.tmpl)

Already validated in v1.0.0. Extend for:
- karabiner (per-keyboard differences)
- aerospace (macOS only)
- Terminal emulator font paths (platform differences)

Uses .chezmoidata.yaml (static, in repo) and chezmoi.toml (machine-specific, NOT in repo).

### 4. private_ Attribute (GPG Agent, Sensitive Configs)

Sets 0o600/0o700 permissions. Required for:
- gpg-agent.conf
- Any configs with embedded secrets

### 5. .chezmoiremove (Dotbot Cleanup)

Pattern-based file removal across all machines. Required for:
- Removing nushell configs
- Removing zgenom remnants
- Cleaning up Dotbot infrastructure artifacts from target

### 6. remove_ Prefix (Targeted Cleanup)

Individual file removal for specific Dotbot artifacts in target directories.

## Features NOT Needed

| Feature | Why Not |
|---------|---------|
| symlink_ | Breaks encryption, templates, cross-platform. Use templates instead |
| create_ | Templates handle all variability |
| modify_ | Not applicable to static config migrations |
| run_once_ | run_onchange_ already in use, clearer intent |

## No New Tools Required

All migrations use existing chezmoi features. No new dependencies, packages, or tool installations needed for v1.1.

## Migration Workflow Per Config

1. Audit current state (symlink? permissions? secrets?)
2. `chezmoi add --follow` (converts symlinks to files)
3. `chezmoi diff` (verify content matches)
4. `chezmoi apply -n -v` (dry-run, mandatory)
5. `chezmoi apply` (apply for real)
6. Verify tool works with chezmoi-managed config

---
*Research confidence: HIGH — all patterns proven in v1.0.0 or documented in official chezmoi docs*
