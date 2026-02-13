# Dotfiles Stack

## What This Is

A complete ZSH dotfiles management system powered by chezmoi, providing cross-platform templating (macOS/Linux), machine-specific configuration (client/personal), automated Homebrew package management, mise runtime version management (7 runtimes), Bitwarden-backed secret templating with age encryption, gitleaks leak prevention, and a plugin-based verification framework with 112 automated checks. All configs (135 files) are managed by chezmoi with Dotbot fully retired.

## Core Value

**Cross-platform dotfiles that "just work"** -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.

## Requirements

### Validated

#### v1.0.0 -- shipped 2026-02-08

- Remove Nix completely (nix-config/, nix-darwin, home-manager)
- Migrate core Dotbot symlinks to chezmoi
- Add chezmoi templating for OS-specific configurations (macOS vs Linux)
- Add chezmoi templating for machine-specific configurations (work vs personal)
- Replace asdf with mise for runtime version management
- Move runtime tools (node, python, go, rust, java, ruby, terraform) to mise
- Keep CLI tools in Homebrew (pragmatic -- works well on both platforms)
- Migrate Sheldon configuration to be managed by chezmoi
- Ensure shell startup time is not degraded (0.87s maintained)
- Bitwarden integration for secret templating
- Age encryption for SSH keys with per-machine key pairs
- Global gitleaks scanning via git hooks (warn on commit, block on push)
- Automated permission verification for sensitive files

#### v1.1 -- shipped 2026-02-12

- Migrate all remaining configs to chezmoi (69 files: basic dotfiles, CLI tools, terminal emulators, dev tools, Claude Code)
- Build verification framework with automated checks (112 checks across 5 phases)
- OS-conditional templating for gpg-agent pinentry path
- Selective sync for .claude/ directory (47 files tracked, local state excluded)
- Retire Dotbot infrastructure (submodules, install script, steps/ directory)
- Drop deprecated configs (nushell, zgenom)
- Update README to chezmoi-only workflow

### Active

#### Current Milestone: v1.2 Legacy Cleanup

**Goal:** Remove all pre-chezmoi artifacts from the repo and fix stale code in the chezmoi source, so the repository reflects reality.

**Target:**
- Remove legacy .config/ directories and flat files (Dotbot-era source files)
- Remove redundant zsh.d/ and Brewfile (chezmoi equivalents exist)
- Fix stale PATH entries, aliases, and Python 2 code in chezmoi source
- Migrate san-proxy from .config/profile to chezmoi (client-only)
- Clean audit scripts of retired directory references
- Resolve dual mise activation and other known limitations

#### Deferred to future milestone
- [ ] Set up mise task runner for common development tasks (MISE-03, deferred from v1)
- [ ] Profile shell startup with zprof and establish baseline (PERF-01)
- [ ] Implement lazy loading for non-critical tool initialisation (PERF-02)
- [ ] Add eval caching for expensive startup commands (PERF-03)
- [ ] Achieve < 300ms total shell startup time (PERF-04)

### Out of Scope

- Moving all Homebrew packages to mise -- most CLI tools work fine in Homebrew
- Windows support -- not a current need
- Nix-style reproducibility -- accepting Homebrew version drift as trade-off
- Neovim config -- stays separate from chezmoi (own repo, intentional exception documented in README)

## Context

**Current state (post v1.1):**
- chezmoi manages 135 files with cross-platform templates and OS-conditional configs
- 171+ Homebrew packages consolidated in .chezmoidata.yaml with automated installation
- mise manages 7 runtime versions (node, python, go, rust, java, ruby, terraform)
- Bitwarden provides secrets to chezmoi templates (git config email/name)
- 4 SSH keys encrypted with age in chezmoi source
- Global gitleaks hooks deployed to all git repos
- Permission verification runs on every chezmoi apply
- Plugin-based verification framework: 112 automated checks across Phases 8-12
- Dotbot fully retired -- no submodules, no install script, no steps/ directory
- All terminal emulators (kitty, ghostty, wezterm), CLI tools, dev tools, and Claude Code managed by chezmoi

**Architecture:**
- chezmoi source: ~/.local/share/chezmoi (templates, data, run scripts)
- Package data: .chezmoidata.yaml (single source of truth for all packages)
- Config template: .chezmoi.yaml.tmpl (machine identity, encryption, Bitwarden)
- Shell config: modular zsh.d/*.zsh files managed by chezmoi
- Plugin management: Sheldon (.config/sheldon/plugins.toml)
- Verification: scripts/verify-configs.sh with scripts/verify-checks/*.sh plugins

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
| chezmoi over Dotbot | Templating for OS/machine differences, built-in secret handling | Validated -- cross-platform templates working, age encryption, Bitwarden integration, Dotbot retired v1.1 |
| mise over asdf | Faster, more backends (aqua, cargo, npm), better ergonomics | Validated -- 7 runtimes managed, auto-install working, 10x faster version switching |
| Keep Homebrew for CLI tools | Works on both platforms, well-maintained, familiar | Validated -- 171+ packages, automated via chezmoi run scripts |
| Keep Sheldon for ZSH plugins | Already in use, fast, simple | Validated -- no changes needed, works with chezmoi-managed config |
| Age encryption for SSH keys | Per-machine isolation, Bitwarden as bootstrap | Validated -- 4 keys encrypted, bootstrap chain working |
| Bitwarden for secrets | Free, CLI available, vault already in use | Validated -- git config templated from vault |
| Global gitleaks hooks | Prevent secret leaks across all repos | Validated -- warn on commit, block on push |
| Manual cp -L for chezmoi add | chezmoi add --follow limitation with directories | Validated -- reliable workaround used across all v1.1 phases (8-11) |
| Plugin-based verification | Extensible check framework per phase | Validated -- 112 checks, 5 phase check files, auto-discovered by runner |
| Selective sync for .claude/ | Track synced files, exclude 491MB cache/state | Validated -- 47 files tracked, 43 exclusion patterns, ~13s diff (upstream limitation) |
| Three-step submodule removal | Complete cleanup of Dotbot submodules | Validated -- 4 submodules + orphaned metadata fully cleaned |

## Known Limitations

1. **Shell startup time**: 0.87s (pre-existing, not caused by migration). Target < 300ms deferred to future milestone.
2. **Phantom/firebase-cli broken**: Shebangs point to removed Homebrew node. Work via mise node when called directly.
3. ~~**Dual mise activation**: hooks.zsh and external.zsh both activate mise. Harmless but redundant.~~ → Targeted in v1.2
4. **chezmoi diff performance**: ~13s with .claude/ tracked (491MB directory). Selective sync correct; upstream chezmoi limitation.
5. **Neovim exception**: nvim config stays as symlink outside chezmoi management (intentional, documented in README).
6. **Legacy .config/ artifacts**: Dotbot-era source files still in repo, superseded by chezmoi. → Targeted in v1.2
7. **Stale PATH entries**: Volta, rbenv PATH additions deployed via chezmoi source despite being replaced by mise. → Targeted in v1.2

---
*Last updated: 2026-02-13 after v1.2 milestone started*
