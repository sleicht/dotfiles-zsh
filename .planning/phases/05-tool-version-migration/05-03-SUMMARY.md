---
phase: 05-tool-version-migration
plan: 03
subsystem: infra
tags: [mise, homebrew, runtime-management, node, rust, ruby]

# Dependency graph
requires:
  - phase: 05-01
    provides: "mise global config with multi-language support"
  - phase: 05-02
    provides: "mise shell activation for runtime management"
provides:
  - "Exclusive mise control over runtimes (no Homebrew conflicts)"
  - "Cleanup script for future chezmoi applies"
  - "Updated .chezmoidata.yaml without conflicting packages"
affects: [05-04, 05-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "run_once_after for one-time cleanup tasks"
    - "Comments in .chezmoidata.yaml to explain removed packages"

key-files:
  created:
    - "~/.local/share/chezmoi/run_once_after_cleanup-homebrew-runtimes.sh.tmpl"
  modified:
    - "~/.local/share/chezmoi/.chezmoidata.yaml"

key-decisions:
  - "Remove rbenv, rust, volta from client_brews (mise manages these)"
  - "Remove rbenv, rust from fanaka_brews (mise manages these)"
  - "Keep python@3.x in Homebrew as build dependencies (versioned paths don't conflict)"
  - "Use --ignore-dependencies flag for safe uninstall"

patterns-established:
  - "run_once_after_ prefix for cleanup scripts that should run once"

# Metrics
duration: 4 min
completed: 2026-01-29
---

# Phase 5 Plan 3: Remove Conflicting Homebrew Runtimes Summary

**Removed Homebrew node, rust, rbenv to give mise exclusive control over runtime versions**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-29T17:39:03Z
- **Completed:** 2026-01-29T17:42:37Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Updated .chezmoidata.yaml to remove packages that conflict with mise
- Created run_once cleanup script to uninstall conflicting Homebrew packages
- Manually uninstalled node, rust, rbenv from Homebrew
- Verified mise-managed runtimes are now in PATH

## Task Commits

Tasks executed but git commits pending user approval:

1. **Task 1: Update .chezmoidata.yaml** - (pending commit)
2. **Task 2: Create cleanup script** - (pending commit)
3. **Task 3: Apply and verify** - (verification complete, no file changes)

**Note:** Git operations in ~/.local/share/chezmoi require explicit user permission. Files have been modified but not yet committed.

## Files Created/Modified

- `~/.local/share/chezmoi/.chezmoidata.yaml` - Removed conflicting packages (rust, volta, rbenv from client_brews; rust, rbenv from fanaka_brews)
- `~/.local/share/chezmoi/run_once_after_cleanup-homebrew-runtimes.sh.tmpl` - One-time cleanup script for macOS

## Decisions Made

1. **Removed packages from .chezmoidata.yaml:**
   - `rbenv` - mise manages ruby versions
   - `rust` - mise manages rust via stable channel
   - `volta` - mise replaces volta for node management

2. **Kept packages:**
   - `python@3.x` - Homebrew build dependency, uses versioned paths that don't conflict with mise
   - `mise` - Remains in common_brews as the runtime manager

3. **Cleanup approach:**
   - Used `--ignore-dependencies` flag to allow safe uninstall
   - Script runs once after chezmoi apply via `run_once_after_` prefix

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **brew bundle check failure:** The iFinance 5 MAS app needs a manual upgrade (requires sudo/password). This is unrelated to the mise migration and does not affect runtime management.

- **Git commit permissions:** Git operations in ~/.local/share/chezmoi directory require explicit user approval. The file modifications are complete but commits are pending.

## Verification Results

All success criteria met:

| Check | Result |
|-------|--------|
| `brew list node` | NOT installed |
| `brew list rust` | NOT installed |
| `brew list volta` | NOT installed |
| `brew list rbenv` | NOT installed |
| `which node` | ~/.local/share/mise/installs/node/22.21.1/bin/node |
| `which ruby` | ~/.local/share/mise/installs/ruby/3.4.5/bin/ruby |
| `node --version` | v22.21.1 |
| `ruby --version` | ruby 3.4.5 |
| `mise current` | Shows all 7 managed runtimes |

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Mise has exclusive control over runtimes
- Ready for 05-04: Mise Completions (already done in 05-02)
- Ready for 05-05: Final verification

---
*Phase: 05-tool-version-migration*
*Completed: 2026-01-29*
