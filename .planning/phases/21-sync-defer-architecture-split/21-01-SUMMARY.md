---
phase: 21-sync-defer-architecture-split
plan: 01
subsystem: shell-init
tags: [refactoring, performance, architecture]
dependency_graph:
  requires: []
  provides:
    - sync/defer file structure
    - prompt-critical vs deferrable separation
  affects:
    - sheldon plugin configuration (Phase 21 Plan 02)
tech_stack:
  added: []
  patterns:
    - Sync files: prompt-critical, keybinding-critical
    - Defer files: non-blocking initialisation
key_files:
  created:
    - ~/.local/share/chezmoi/dot_zsh.d/prompt.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/external-sync.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/external-defer.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/completions-sync.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/completions-defer.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/ssh-defer.zsh
  modified:
    - ~/.local/share/chezmoi/dot_zprofile
  deleted:
    - ~/.local/share/chezmoi/dot_zsh.d/hooks.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/external.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/completions.zsh
    - ~/.local/share/chezmoi/dot_zsh.d/ssh.zsh
decisions:
  - FZF keybindings and atuin keybindings kept sync (interactive-use-immediately)
  - Dropped unused REPOSITORIES_PATH variables (only referenced in commented code)
  - Added mise command guard in external-defer.zsh
metrics:
  duration_seconds: 208
  tasks_completed: 2
  files_modified: 11
  commits: 2
  completed_date: 2026-02-14
---

# Phase 21 Plan 01: Split sync/defer architecture

**One-liner:** Separated prompt-critical initialisation (oh-my-posh, FZF/atuin keybindings) from deferrable work (zoxide, mise, SSH hosts) into distinct file pairs, enabling Sheldon to load them with different apply strategies.

## Objective

Split existing zsh.d files into sync and defer variants, preparing for Sheldon plugin group reconfiguration in Plan 02. This creates a clean separation between prompt-critical initialisation and deferrable work.

## What Was Built

Created six new/renamed files in chezmoi source directory:

**Sync files (prompt-critical):**
- `prompt.zsh`: oh-my-posh init, FZF keybindings (Ctrl+T, Alt+C), atuin keybindings (Ctrl+R), preexec hook
- `external-sync.zsh`: FZF exports (FZF_DEFAULT_COMMAND, etc.) and compgen functions
- `completions-sync.zsh`: completion foundation (zstyles, colors, word-style, predict)

**Defer files (non-blocking):**
- `external-defer.zsh`: zoxide init and mise activation
- `completions-defer.zsh`: SSH host cache, bun completions, phantom completions
- `ssh-defer.zsh`: SSH keychain loading (renamed from ssh.zsh)

**Also updated:**
- `.zprofile`: Added mise shims for immediate PATH access (full activation deferred)

**Removed:**
- `hooks.zsh`, `external.zsh`, `completions.zsh` (replaced by sync/defer variants)

## Tasks Completed

### Task 1: Split hooks.zsh, external.zsh, and completions.zsh into sync/defer pairs

**What was done:**
- Created `prompt.zsh` with oh-my-posh init, FZF/atuin keybindings, preexec hook
- Created `external-sync.zsh` with FZF exports and compgen functions
- Created `external-defer.zsh` with zoxide and mise activation
- Created `completions-sync.zsh` with completion foundation
- Created `completions-defer.zsh` with SSH hosts, bun, phantom completions
- Deleted original files (hooks.zsh, external.zsh, completions.zsh)
- Dropped unused REPOSITORIES_PATH variables

**Commit:** 62349a8 (refactor(21-01): split hooks, external, and completions into sync/defer pairs)

**Files changed:** 5 files (47 insertions, 43 deletions)

### Task 2: Rename ssh.zsh to ssh-defer.zsh and add mise shims to .zprofile

**What was done:**
- Renamed `ssh.zsh` to `ssh-defer.zsh` for defer group placement
- Added mise shims activation to `.zprofile` for immediate PATH access
- Full mise activation remains in `external-defer.zsh`

**Commit:** 62d1088 (feat(21-01): rename ssh.zsh to ssh-defer and add mise shims to .zprofile)

**Files changed:** 2 files (5 insertions)

## Verification Results

All success criteria met:

- ✅ Six new/renamed files exist in chezmoi source (prompt.zsh, external-sync.zsh, external-defer.zsh, completions-sync.zsh, completions-defer.zsh, ssh-defer.zsh)
- ✅ Three old files removed (hooks.zsh, external.zsh, completions.zsh)
- ✅ .zprofile updated with mise shims
- ✅ All original content accounted for in new files (verified via grep for oh-my-posh, FZF_DEFAULT_COMMAND, zoxide, mise, _cache_hosts, predict-on)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added mise command guard**
- **Found during:** Task 1 - creating external-defer.zsh
- **Issue:** Original external.zsh had unconditional `eval "$(mise activate zsh)"` which could fail if mise not installed
- **Fix:** Added `if (( $+commands[mise] ))` guard around mise activation
- **Files modified:** dot_zsh.d/external-defer.zsh
- **Commit:** 62349a8 (part of Task 1 commit)

No other deviations - plan executed as written with one defensive enhancement.

## Decisions Made

1. **FZF and atuin keybindings kept sync**: Based on research decision tree, keybindings that define widgets for immediate interactive use (Ctrl+T, Alt+C, Ctrl+R) must be sync. These provide core shell navigation functionality that users expect immediately.

2. **Dropped REPOSITORIES_PATH variables**: Variables were only defined in hooks.zsh and only referenced in a commented-out dircolors line. Since actual usage was commented and variables were immediately unset, they were safely removed.

3. **Added mise command guard**: Even though mise is typically installed, defensive programming warranted a command check before eval activation.

## Next Steps

Plan 02 will reconfigure Sheldon to load these files with appropriate apply strategies:
- Sync files: loaded immediately (source without defer)
- Defer files: loaded with zsh-defer for non-blocking init

## Self-Check: PASSED

Verified all files exist and commits are in git history:

```bash
# Files created
✓ /Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/prompt.zsh
✓ /Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/external-sync.zsh
✓ /Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/external-defer.zsh
✓ /Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/completions-sync.zsh
✓ /Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/completions-defer.zsh
✓ /Users/stephanlv_fanaka/.local/share/chezmoi/dot_zsh.d/ssh-defer.zsh

# Files deleted
✓ hooks.zsh, external.zsh, completions.zsh removed
✓ ssh.zsh renamed to ssh-defer.zsh

# Files modified
✓ /Users/stephanlv_fanaka/.local/share/chezmoi/dot_zprofile

# Commits
✓ 62349a8: refactor(21-01): split hooks, external, and completions into sync/defer pairs
✓ 62d1088: feat(21-01): rename ssh.zsh to ssh-defer and add mise shims to .zprofile
```

All claims verified. Plan execution complete.
