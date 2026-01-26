# Requirements: Dotfiles Stack Migration

**Defined:** 2026-01-25
**Core Value:** Cross-platform dotfiles that "just work" — one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Preparation

- [x] **PREP-01**: Create complete backup of current dotfiles state before migration
- [x] **PREP-02**: Create emergency recovery scripts that restore working shell if migration breaks
- [x] **PREP-03**: Set up Linux test environment (Docker/VM) for cross-platform validation

### chezmoi Migration

- [x] **CHEM-01**: Initialize chezmoi and migrate all Dotbot symlinks with working shell
- [x] **CHEM-02**: Add OS detection templating (macOS vs Linux conditionals)
- [x] **CHEM-03**: Add machine-specific templating (hostname-based work vs personal detection)
- [x] **CHEM-04**: Template tool configurations (git, mise, sheldon, etc.)

### Package Management

- [ ] **PKGM-01**: Implement automated Homebrew installation via run_onchange scripts
- [ ] **PKGM-02**: Consolidate Brewfile_Client and Brewfile_Fanaka into .chezmoidata format
- [ ] **PKGM-03**: Remove Nix completely (nix-config/, nix-darwin, Home Manager, Nix itself)

### Tool Version Management (mise)

- [ ] **MISE-01**: Install mise, configure global settings, migrate all .tool-versions, remove asdf
- [ ] **MISE-02**: Configure mise environment variable management (replace direnv functionality)
- [ ] **MISE-03**: Set up mise task runner for common development tasks

### Security

- [ ] **SECU-01**: Integrate Bitwarden for secret templating in chezmoi configs
- [ ] **SECU-02**: Implement age encryption for sensitive files committed to git
- [ ] **SECU-03**: Install pre-commit hooks with gitleaks for secret leakage prevention
- [ ] **SECU-04**: Verify and harden file permissions on sensitive files (600 for credentials)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Performance Optimisation

- **PERF-01**: Profile shell startup with zprof and establish baseline
- **PERF-02**: Implement lazy loading for non-critical tool initialisation
- **PERF-03**: Add eval caching for expensive startup commands
- **PERF-04**: Achieve < 300ms total shell startup time

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| 1Password integration | Using Bitwarden instead |
| Moving all Homebrew packages to mise | Most CLI tools work fine in Homebrew; only runtimes move to mise |
| Windows support | Not a current need |
| Nix-style reproducibility | Accepting Homebrew version drift as trade-off for simplicity |
| Terminal emulator changes | Keep current Ghostty/WezTerm/Kitty configs as-is |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PREP-01 | Phase 1 | Complete |
| PREP-02 | Phase 1 | Complete |
| PREP-03 | Phase 1 | Complete |
| CHEM-01 | Phase 2 | Complete |
| CHEM-02 | Phase 3 | Complete |
| CHEM-03 | Phase 3 | Complete |
| CHEM-04 | Phase 3 | Complete |
| PKGM-01 | Phase 4 | Pending |
| PKGM-02 | Phase 4 | Pending |
| PKGM-03 | Phase 4 | Pending |
| MISE-01 | Phase 5 | Pending |
| MISE-02 | Phase 5 | Pending |
| MISE-03 | Phase 5 | Pending |
| SECU-01 | Phase 6 | Pending |
| SECU-02 | Phase 6 | Pending |
| SECU-03 | Phase 6 | Pending |
| SECU-04 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0 ✓

---
*Requirements defined: 2026-01-25*
*Last updated: 2026-01-25 after initial definition*
