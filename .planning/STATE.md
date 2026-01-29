# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-25)

**Core value:** Cross-platform dotfiles that "just work" — one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.
**Current focus:** Phase 5: Tool Version Migration

## Current Position

Phase: 5 of 6 (Tool Version Migration)
Plan: 2 of 5 (shell activation complete)
Status: Executing
Last activity: 2026-01-29 — Completed 05-02-PLAN.md (Shell Activation)

Progress: [███████░░░] 72% (18/25 plans complete)

## Performance Metrics

**Velocity:**
- Total plans completed: 16
- Average duration: 10 min
- Total execution time: 2.6 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-preparation | 4 | 12 min | 3 min |
| 02-chezmoi-foundation | 4 | 75 min | 19 min |
| 03-templating-machine-detection | 4 | 13 min | 3.3 min |
| 04-package-management-migration | 4 | 61 min | 15.3 min |

**Recent Trend:**
- Last 5 plans: 04-01 (2min), 04-02 (7min), 04-03 (7min), 04-04 (45min)
- Trend: Phase 4 complete (verification checkpoint took longer due to fixes)

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- All key decisions are pending (see PROJECT.md for rationale on chezmoi, mise, Homebrew, Sheldon)
- 01-02: Six critical files defined for backup validation (.zshrc, .zshenv, .zprofile, .config/git/config, .config/sheldon/plugins.toml, .dotfiles)
- 01-02: Backup age warning threshold set to 7 days
- 01-03: Ubuntu 24.04 LTS chosen for Linux test container
- 01-03: OrbStack preferred over Docker for faster startup
- 01-03: Read-only mount for dotfiles to prevent accidental modification
- 02-01: IDE-friendly workflow (autoCommit=true, autoPush=false, manual apply)
- 02-01: Delta pager configured for better diff output
- 02-02: Changed chezmoi diff pager from delta to less (delta not installed)
- 02-02: Standalone zshrc combines Nix wrapper essentials with actual config
- 02-03: Use --follow flag to follow symlinks when adding to chezmoi
- 02-03: Add chezmoi header comment only to primary config files
- 02-04: zgenom cache reset required after migration
- 02-04: README.md excluded from chezmoi deployment via .chezmoiignore
- 03-01: Remove stdinIsATTY check to allow --promptString values to work
- 03-01: Include config settings in .chezmoi.yaml.tmpl for complete config generation
- 03-01: Always call promptString functions - chezmoi handles value provision
- 03-02: Use private_ prefix for .gitconfig_local to set 600 permissions (contains email)
- 03-02: Template selects email based on machine_type: work_email for client, personal_email otherwise
- 03-03: Use {{- if eq .chezmoi.os "darwin" }} for OS-conditional path configuration
- 03-03: Wrap macOS-specific Homebrew paths in darwin conditionals (GNU tools, Homebrew Ruby)
- 03-03: Keep cross-platform tools unconditional (nix, rbenv, npm, pnpm, volta, cargo)
- 03-04: Docker container with read-only chezmoi mount for Linux verification
- 03-04: Templates verified working on Ubuntu 24.04 (0 macOS paths in Linux output)
- 04-01: Structured packages as common (all machines) vs client-specific vs fanaka-specific
- 04-01: Excluded asdf (being replaced by mise in Phase 5)
- 04-01: Merged Nix-managed Homebrew packages from apps.nix as most up-to-date source
- 04-01: Deduplicated CJ-Systems/homebrew-gitflow-cjs tap (case-sensitive variants)
- 04-02: Use run_once_before_ for Homebrew bootstrap (runs once, before other scripts)
- 04-02: Use run_onchange_after_ with SHA256 hash for package scripts (only re-run when .chezmoidata.yaml changes)
- 04-02: Map 'personal' machine_type to fanaka package sections (else clause handles non-client machines)
- 04-02: Log removed packages to ~/.local/state/homebrew-cleanup.log with timestamps
- 04-03: Print Nix removal instructions rather than auto-executing root commands
- 04-03: Remove Nix PATH from both chezmoi template and legacy dotfiles path.zsh
- 04-04: Always use brew bundle --global to interact with chezmoi-managed ~/.Brewfile
- 04-04: Run brew commands from ~ to avoid confusion with old Brewfiles in subdirectories
- 04-04: Added mise to common_brews and made activation unconditional
- 04-04: Fixed /opt/homebrew/share permissions for oh-my-zsh completion security
- 05-01: Global mise config with multi-language support (node, python, go, rust, java, ruby, terraform)
- 05-01: Use private_dot_config prefix for ~/.config directory (correct permissions)
- 05-01: Store tool versions in .chezmoidata.yaml for potential machine-specific overrides
- 05-01: Enable idiomatic version files for node and python only
- 05-02: mise activate over shims for zero runtime overhead in interactive shells
- 05-02: run_once_after pattern for one-time completion generation

### Completed Phases

**Phase 1: Preparation & Safety Net** (2026-01-25)
- Created backup infrastructure with rsync, exclusions, pre-flight checks
- Created recovery infrastructure with interactive category-based restore
- Created Linux test environment with Ubuntu 24.04 container
- User verified all safety mechanisms work correctly
- Requirements covered: PREP-01, PREP-02, PREP-03

**Phase 2: chezmoi Foundation** (2026-01-26)
- chezmoi installed and configured with IDE-friendly workflow
- Shell files migrated (.zshrc, .zshenv, .zprofile, zsh.d/*.zsh)
- Git config migrated (.gitconfig, .gitignore_global, .gitattributes_global)
- Dotbot config updated with migration notes
- chezmoi source under git version control (7 commits)
- User verified shell works correctly, chezmoi verify passes
- Requirements covered: CHEM-01

**Phase 3: Templating & Machine Detection** (2026-01-26)
- Created .chezmoi.yaml.tmpl with interactive prompts for machine type and emails
- Created .chezmoidata.yaml for static package data structure
- Machine identity captured: personal machine, stephan@fanaka.ch
- OS detection working: osid=darwin on macOS, osid=linux-ubuntu on Linux
- Created templated .gitconfig_local with machine-type-based email selection
- Established pattern for sensitive file handling with private_ prefix (600 permissions)
- Converted path.zsh to template with OS conditionals for cross-platform support
- macOS gets GNU tools paths, Linux excludes macOS-specific Homebrew paths
- Verified templates work correctly on both macOS and Linux Ubuntu 24.04
- User verified shell works, git email correct, chezmoi data complete
- Requirements covered: TEMP-01, TEMP-02

**Phase 4: Package Management Migration** (2026-01-27 to 2026-01-28 - complete)
- Plan 04-01: Consolidated all packages from 5 sources into .chezmoidata.yaml
- 171 total packages: 82 common brews, 22 common casks, 12 client brews, 28 client casks, 3 fanaka brews, 17 fanaka casks
- 16 taps, 7 fonts, 2 common MAS apps, 8 fanaka MAS apps
- Single source of truth for Homebrew packages replacing 3 separate Brewfiles
- Plan 04-02: Created Homebrew automation via chezmoi run scripts
- Four templates created: Homebrew bootstrap, Brewfile generator, package installer, package cleanup
- One-command bootstrap achieved: `chezmoi apply` installs Homebrew + all packages
- Change-triggered installation: scripts only re-run when .chezmoidata.yaml changes
- Cleanup audit trail: removed packages logged to ~/.local/state/homebrew-cleanup.log
- Plan 04-03: Removed Nix completely from repository
- Deleted nix-config/ directory (12 files) from git
- Cleaned Nix references from chezmoi templates (path.zsh, .zshrc)
- Created run_once_after_remove-nix-references.sh.tmpl with safe manual removal instructions
- Nix system state documented: daemon running, /nix volume exists, hooks in /etc/zshrc
- Plan 04-04: Verified complete package management migration
- brew bundle check --global passes (all 171+ packages satisfied)
- Fixed 5 issues during verification: deprecated taps, missing packages, permissions, mise
- Shell works correctly in new terminals
- User approved migration complete

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-01-29
Stopped at: Completed 05-02-PLAN.md (Shell Activation)
Resume file: None

### Next Action

Continue to 05-03: Tool Migration

Next steps: Execute 05-03-PLAN.md to migrate tool version management to mise
