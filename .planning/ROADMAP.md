# Roadmap: Dotfiles Stack Migration

## Overview

This roadmap guides the migration from a complex multi-tool setup (Dotbot symlinks, Nix packages, asdf version management) to a modern, streamlined approach using chezmoi for dotfiles templating and mise for tool version management. The migration follows a "foundation first, complexity later" approach with six phases that progress from safety nets to working shell, then layer in templating, package management, tool versioning, and finally security. Each phase delivers a verifiable, working system with clear rollback points.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Preparation & Safety Net** - Create backups, recovery scripts, and test environment
- [ ] **Phase 2: chezmoi Foundation** - Initialize chezmoi and migrate core shell configuration
- [ ] **Phase 3: Templating & Machine Detection** - Add cross-platform and machine-specific templating
- [ ] **Phase 4: Package Management Migration** - Migrate to automated Homebrew installation and remove Nix
- [ ] **Phase 5: Tool Version Migration (mise)** - Replace asdf with mise for runtime version management
- [ ] **Phase 6: Security & Secrets** - Implement secret management and security hardening

## Phase Details

### Phase 1: Preparation & Safety Net
**Goal**: Establish safety mechanisms before touching any live configurations
**Depends on**: Nothing (first phase)
**Requirements**: PREP-01, PREP-02, PREP-03
**Success Criteria** (what must be TRUE):
  1. User has complete backup of current dotfiles state (all files, symlinks, and configurations archived)
  2. User can run emergency recovery script and restore working shell within 2 minutes
  3. User has working Linux test environment (Docker or VM) to validate cross-platform changes
  4. User can verify backup completeness (all critical files present and restorable)
**Plans**: 4 plans in 2 waves

Plans:
- [ ] 01-01-PLAN.md - Create backup infrastructure (exclusions + backup script)
- [ ] 01-02-PLAN.md - Create recovery infrastructure (restore + verify scripts)
- [ ] 01-03-PLAN.md - Create Linux test environment (Docker/OrbStack)
- [ ] 01-04-PLAN.md - Execute backup and verify safety net (checkpoint)

### Phase 2: chezmoi Foundation
**Goal**: Establish core dotfiles management with chezmoi without complexity
**Depends on**: Phase 1
**Requirements**: CHEM-01
**Success Criteria** (what must be TRUE):
  1. User can open new terminal and shell works correctly (all aliases, functions, completions available)
  2. User has chezmoi source directory (`~/.local/share/chezmoi`) under Git version control with remote
  3. User can run `chezmoi apply` and dotfiles are updated without breaking shell
  4. User has migrated core shell files (.zshrc, .zshenv, .zprofile, zsh.d/*.zsh) to chezmoi
  5. User understands new workflow (edit with `chezmoi edit`, apply changes, not direct file editing)
**Plans**: TBD

Plans:
- TBD (will be created during planning)

### Phase 3: Templating & Machine Detection
**Goal**: Enable cross-platform support and machine-specific configurations through templating
**Depends on**: Phase 2
**Requirements**: CHEM-02, CHEM-03, CHEM-04
**Success Criteria** (what must be TRUE):
  1. User can run `chezmoi apply` on macOS and Linux and get platform-appropriate configurations
  2. User can switch between machines (client/personal) and get machine-specific settings automatically
  3. User has working templates for git config, tool configs (mise, sheldon, etc.) that adapt to OS and machine
  4. User can verify templates with `chezmoi execute-template` before applying
  5. User can test configuration on Linux VM without breaking macOS setup
**Plans**: TBD

Plans:
- TBD (will be created during planning)

### Phase 4: Package Management Migration
**Goal**: Automate package installation via chezmoi and remove Nix completely
**Depends on**: Phase 3
**Requirements**: PKGM-01, PKGM-02, PKGM-03
**Success Criteria** (what must be TRUE):
  1. User can run `chezmoi apply` and all Homebrew packages install/update automatically
  2. User has consolidated machine-specific package lists in `.chezmoidata` format (no separate Brewfiles)
  3. User can verify Nix is completely removed (no nix-config/, nix-darwin, Home Manager, or Nix binaries)
  4. User can install dotfiles on fresh system and get all required packages without manual intervention
  5. User has OS-specific package installation working correctly on macOS and Linux
**Plans**: TBD

Plans:
- TBD (will be created during planning)

### Phase 5: Tool Version Migration (mise)
**Goal**: Replace asdf with mise for runtime version management (node, python, go, rust)
**Depends on**: Phase 4
**Requirements**: MISE-01, MISE-02, MISE-03
**Success Criteria** (what must be TRUE):
  1. User can run `mise use node@22` and node is immediately available in shell
  2. User has all existing .tool-versions files working with mise (no asdf commands needed)
  3. User can verify asdf is completely removed (no asdf binary, plugins, or shell initialization)
  4. User can run `mise install` in any project and get correct tool versions automatically
  5. User experiences faster tool switching (mise 10-50x faster than asdf for common operations)
**Plans**: TBD

Plans:
- TBD (will be created during planning)

### Phase 6: Security & Secrets
**Goal**: Implement secure secret management and harden file permissions
**Depends on**: Phase 5
**Requirements**: SECU-01, SECU-02, SECU-03, SECU-04
**Success Criteria** (what must be TRUE):
  1. User can template secrets from Bitwarden into chezmoi-managed configs without committing secrets to git
  2. User has sensitive files encrypted with age (if any need to be in git)
  3. User cannot commit secrets accidentally (pre-commit hooks with gitleaks block pushes containing secrets)
  4. User can verify all credential files have correct permissions (600 for private keys, tokens, etc.)
  5. User can rotate secrets via Bitwarden and re-run `chezmoi apply` to update configurations
**Plans**: TBD

Plans:
- TBD (will be created during planning)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Preparation & Safety Net | 0/4 | Ready to execute | - |
| 2. chezmoi Foundation | 0/TBD | Not started | - |
| 3. Templating & Machine Detection | 0/TBD | Not started | - |
| 4. Package Management Migration | 0/TBD | Not started | - |
| 5. Tool Version Migration (mise) | 0/TBD | Not started | - |
| 6. Security & Secrets | 0/TBD | Not started | - |
