# Dotfiles Stack

## What This Is

A complete ZSH dotfiles management system powered by chezmoi, providing cross-platform templating (macOS/Linux), machine-specific configuration (client/personal), automated Homebrew package management, mise runtime version management (7 runtimes), and Bitwarden-backed secret templating with age encryption and gitleaks leak prevention.

## Core Value

**Cross-platform dotfiles that "just work"** -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.

## Requirements

### Validated (v1.0.0 -- shipped 2026-02-08)

- [x] Remove Nix completely (nix-config/, nix-darwin, home-manager)
- [x] Migrate all Dotbot symlinks to chezmoi
- [x] Add chezmoi templating for OS-specific configurations (macOS vs Linux)
- [x] Add chezmoi templating for machine-specific configurations (work vs personal)
- [x] Replace asdf with mise for runtime version management
- [x] Move runtime tools (node, python, go, rust, java, ruby, terraform) to mise
- [x] Keep CLI tools in Homebrew (pragmatic -- works well on both platforms)
- [x] Migrate Sheldon configuration to be managed by chezmoi
- [x] Ensure shell startup time is not degraded (0.87s maintained)
- [x] Bitwarden integration for secret templating
- [x] Age encryption for SSH keys with per-machine key pairs
- [x] Global gitleaks scanning via git hooks (warn on commit, block on push)
- [x] Automated permission verification for sensitive files

### Active

None -- planning next milestone.

### Candidates (v2)

- [ ] Set up mise task runner for common development tasks (MISE-03, deferred from v1)
- [ ] Profile shell startup with zprof and establish baseline (PERF-01)
- [ ] Implement lazy loading for non-critical tool initialisation (PERF-02)
- [ ] Add eval caching for expensive startup commands (PERF-03)
- [ ] Achieve < 300ms total shell startup time (PERF-04)

### Out of Scope

- Moving all Homebrew packages to mise -- most CLI tools work fine in Homebrew
- Windows support -- not a current need
- Nix-style reproducibility -- accepting Homebrew version drift as trade-off
- Changing terminal emulator setup -- keep current Ghostty/WezTerm/Kitty configs

## Context

**Current state (post v1.0.0):**
- chezmoi manages all core dotfiles with cross-platform templates
- 171+ Homebrew packages consolidated in .chezmoidata.yaml with automated installation
- mise manages 7 runtime versions (node, python, go, rust, java, ruby, terraform)
- Bitwarden provides secrets to chezmoi templates (git config email/name)
- 4 SSH keys encrypted with age in chezmoi source
- Global gitleaks hooks deployed to all git repos
- Permission verification runs on every chezmoi apply

**Architecture:**
- chezmoi source: ~/.local/share/chezmoi (templates, data, run scripts)
- Package data: .chezmoidata.yaml (single source of truth for all packages)
- Config template: .chezmoi.yaml.tmpl (machine identity, encryption, Bitwarden)
- Shell config: modular zsh.d/*.zsh files managed by chezmoi
- Plugin management: Sheldon (.config/sheldon/plugins.toml)

**Target machines:**
- macOS (Apple Silicon) -- primary development
- Linux (Ubuntu/Debian) -- servers and containers

## Constraints

- **Cross-platform**: Must work on macOS (Homebrew) and Linux (apt/Homebrew)
- **Backwards compatible**: Existing shell functionality must not break
- **No secrets in git**: chezmoi age encryption and Bitwarden integration handle sensitive configs
- **Bitwarden session required**: BW_SESSION env var needed for chezmoi apply with secret templates

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| chezmoi over Dotbot | Templating for OS/machine differences, built-in secret handling | Validated -- cross-platform templates working, age encryption, Bitwarden integration |
| mise over asdf | Faster, more backends (aqua, cargo, npm), better ergonomics | Validated -- 7 runtimes managed, auto-install working, 10x faster version switching |
| Keep Homebrew for CLI tools | Works on both platforms, well-maintained, familiar | Validated -- 171+ packages, automated via chezmoi run scripts |
| Keep Sheldon for ZSH plugins | Already in use, fast, simple | Validated -- no changes needed, works with chezmoi-managed config |
| Age encryption for SSH keys | Per-machine isolation, Bitwarden as bootstrap | Validated -- 4 keys encrypted, bootstrap chain working |
| Bitwarden for secrets | Free, CLI available, vault already in use | Validated -- git config templated from vault |
| Global gitleaks hooks | Prevent secret leaks across all repos | Validated -- warn on commit, block on push |

## Known Limitations

1. **Shell startup time**: 0.87s (pre-existing, not caused by migration). Target < 300ms deferred to v2.
2. **Phantom/firebase-cli broken**: Shebangs point to removed Homebrew node. Work via mise node when called directly.
3. **Nix system cleanup deferred**: /nix synthetic firmlink requires sudo + reboot. Instructions provided.
4. **Dual mise activation**: hooks.zsh and external.zsh both activate mise. Harmless but redundant.
5. **Many configs still in Dotbot**: Editor (nvim), terminal emulators (aerospace, kitty, ghostty, wezterm), and some tool configs not yet migrated to chezmoi.

---
*Last updated: 2026-02-08 after v1.0.0 milestone completion*
