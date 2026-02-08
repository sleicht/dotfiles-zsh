# Requirements: Dotfiles Stack

**Defined:** 2026-02-08
**Core Value:** Cross-platform dotfiles that "just work" -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.

## v1.1 Requirements

Requirements for completing the Dotbot-to-chezmoi migration. Each maps to roadmap phases.

### Preparation

- [ ] **PREP-01**: chezmoi apply correctly ignores Dotbot infrastructure files (.chezmoiignore established)
- [ ] **PREP-02**: All config files audited and cleared of embedded secrets before migration
- [ ] **PREP-03**: Verification script confirms migrated configs work after chezmoi apply

### Basic Dotfiles

- [ ] **BASE-01**: .hushlogin deployed via chezmoi apply
- [ ] **BASE-02**: .inputrc deployed via chezmoi apply
- [ ] **BASE-03**: .editorconfig deployed via chezmoi apply
- [ ] **BASE-04**: .nanorc deployed via chezmoi apply

### CLI Tool Configs

- [ ] **CLI-01**: bat config deployed via chezmoi apply
- [ ] **CLI-02**: lsd config deployed via chezmoi apply
- [ ] **CLI-03**: btop config deployed via chezmoi apply
- [ ] **CLI-04**: oh-my-posh prompt theme deployed via chezmoi apply

### Terminal Emulators

- [ ] **TERM-01**: kitty config deployed via chezmoi apply
- [ ] **TERM-02**: ghostty config deployed via chezmoi apply
- [ ] **TERM-03**: wezterm config deployed via chezmoi apply

### Window Manager

- [ ] **WM-01**: aerospace config deployed via chezmoi apply

### Developer Tools

- [ ] **DEV-01**: lazygit config deployed via chezmoi apply
- [ ] **DEV-02**: atuin shell history config deployed via chezmoi apply
- [ ] **DEV-03**: psqlrc deployed via chezmoi apply
- [ ] **DEV-04**: sqliterc deployed via chezmoi apply
- [ ] **DEV-05**: aider config deployed via chezmoi apply (secrets via env vars)
- [ ] **DEV-06**: finicky browser config deployed via chezmoi apply

### Security Configs

- [ ] **SEC-01**: gpg-agent.conf deployed via chezmoi apply with private permissions
- [ ] **SEC-02**: karabiner.json deployed via chezmoi apply

### Shell Enhancements

- [ ] **SHELL-01**: zsh-abbr abbreviations deployed via chezmoi apply

### Claude Code

- [ ] **CLAUDE-01**: Claude Code directory (.claude/) managed by chezmoi with selective sync
- [ ] **CLAUDE-02**: .chezmoiignore excludes .claude/ local state (settings.local.json, cache)

### Cleanup & Retirement

- [ ] **CLEAN-01**: nushell config removed from repo and target
- [ ] **CLEAN-02**: zgenom directory and config removed from repo and target
- [ ] **CLEAN-03**: Dotbot infrastructure removed (install script, steps/, submodules)

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Performance

- **PERF-01**: Profile shell startup with zprof and establish baseline
- **PERF-02**: Implement lazy loading for non-critical tool initialisation
- **PERF-03**: Add eval caching for expensive startup commands
- **PERF-04**: Achieve < 300ms total shell startup time

### Mise Task Runner

- **MISE-03**: Set up mise task runner for common development tasks

## Out of Scope

| Feature | Reason |
|---------|--------|
| Neovim config migration | Stays separate from chezmoi (user decision) |
| Nushell config migration | Not in use -- dropping instead |
| Shell performance optimisation | Separate milestone |
| Mise task runner | Separate milestone |
| Windows support | Not a current need |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PREP-01 | Phase 7 | Pending |
| PREP-02 | Phase 7 | Pending |
| PREP-03 | Phase 7 | Pending |
| BASE-01 | Phase 8 | Pending |
| BASE-02 | Phase 8 | Pending |
| BASE-03 | Phase 8 | Pending |
| BASE-04 | Phase 8 | Pending |
| CLI-01 | Phase 8 | Pending |
| CLI-02 | Phase 8 | Pending |
| CLI-03 | Phase 8 | Pending |
| CLI-04 | Phase 8 | Pending |
| TERM-01 | Phase 9 | Pending |
| TERM-02 | Phase 9 | Pending |
| TERM-03 | Phase 9 | Pending |
| WM-01 | Phase 8 | Pending |
| DEV-01 | Phase 10 | Pending |
| DEV-02 | Phase 10 | Pending |
| DEV-03 | Phase 8 | Pending |
| DEV-04 | Phase 8 | Pending |
| DEV-05 | Phase 10 | Pending |
| DEV-06 | Phase 10 | Pending |
| SEC-01 | Phase 10 | Pending |
| SEC-02 | Phase 8 | Pending |
| SHELL-01 | Phase 8 | Pending |
| CLAUDE-01 | Phase 11 | Pending |
| CLAUDE-02 | Phase 11 | Pending |
| CLEAN-01 | Phase 12 | Pending |
| CLEAN-02 | Phase 12 | Pending |
| CLEAN-03 | Phase 12 | Pending |

**Coverage:**
- v1.1 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0

All requirements mapped to phases 7-12. 100% coverage achieved.

---
*Requirements defined: 2026-02-08*
*Last updated: 2026-02-08 after roadmap creation*
