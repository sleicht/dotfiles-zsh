---
phase: 09-terminal-emulators
plan: 01
subsystem: dotfiles-migration
tags: [chezmoi, terminal, kitty, ghostty, wezterm, dotbot]

# Dependency graph
requires:
  - phase: 07-preparation
    provides: ".chezmoiignore with Phase 9 pending block preventing premature management"
  - phase: 08-basic-configs-cli-tools
    provides: "Proven manual cp -L workaround for chezmoi add --follow limitation"
provides:
  - "All 3 terminal emulator configs (kitty, ghostty, wezterm) managed by chezmoi"
  - "kitty cache exclusion patterns in .chezmoiignore preventing spurious diffs"
  - "Real files deployed to $HOME (Dotbot symlinks replaced)"
affects: [10-dev-tools-secrets, 12-dotbot-retirement]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Manual cp -L workaround for files within symlinked directories"
    - "Targeted --force flag with specific paths to bypass Bitwarden auth gate"
    - "Cache exclusion patterns for runtime-generated files"

key-files:
  created:
    - ~/.local/share/chezmoi/private_dot_config/kitty/kitty.conf
    - ~/.local/share/chezmoi/private_dot_config/ghostty/config
    - ~/.local/share/chezmoi/dot_wezterm.lua
  modified:
    - ~/.local/share/chezmoi/.chezmoiignore

key-decisions:
  - "Used manual cp -L workaround for all 3 terminal configs (chezmoi add --follow limitation)"
  - "Replaced Phase 9 pending block with Terminal Emulator Cache section in .chezmoiignore"
  - "Applied configs with targeted --force flag to bypass Bitwarden auth gate"

patterns-established:
  - "Pattern 1: Cache exclusion sections in .chezmoiignore prevent runtime-generated files from triggering diffs"
  - "Pattern 2: Manual cp -L is reliable workaround for chezmoi add --follow limitation with symlinked directories"

# Metrics
duration: 4min 9sec
completed: 2026-02-09
---

# Phase 09 Plan 01: Terminal Emulators Migration Summary

**All 3 terminal emulator configs (kitty 2600L, ghostty 39L, wezterm 135L) migrated from Dotbot symlinks to chezmoi-managed real files with kitty cache exclusion patterns**

## Performance

- **Duration:** 4min 9sec (249 seconds)
- **Started:** 2026-02-09T22:42:58Z
- **Completed:** 2026-02-09T22:47:07Z
- **Tasks:** 2
- **Files modified:** 4 (3 created + 1 modified)

## Accomplishments
- Migrated all 3 terminal emulator configs (kitty, ghostty, wezterm) from Dotbot symlinks to chezmoi source
- Removed Phase 9 pending block from .chezmoiignore
- Added Terminal Emulator Cache section with kitty cache exclusion patterns
- Deployed real files to $HOME replacing Dotbot symlinks

## Task Commits

Each task was committed atomically:

1. **Task 1: Add all 3 terminal emulator configs to chezmoi source** - `8107da0` (feat)
2. **Task 2: Update .chezmoiignore with cache exclusions and apply configs** - `204cc8a` (chore)

## Files Created/Modified
- `~/.local/share/chezmoi/private_dot_config/kitty/kitty.conf` - kitty terminal configuration (2600 lines)
- `~/.local/share/chezmoi/private_dot_config/ghostty/config` - ghostty terminal configuration (39 lines)
- `~/.local/share/chezmoi/dot_wezterm.lua` - wezterm terminal configuration (135 lines)
- `~/.local/share/chezmoi/.chezmoiignore` - Updated with Phase 9 block removed and cache exclusions added

## Decisions Made

**1. Execution order adjustment**
- Originally planned to add files first, then update .chezmoiignore
- Adjusted to update .chezmoiignore first to remove ignore patterns, then add files
- Rationale: Files were being ignored by existing Phase 9 patterns, preventing chezmoi add from working

**2. Manual cp -L workaround for all 3 configs**
- chezmoi add --follow failed with "follow and recursive are mutually exclusive for directories" error
- Used Phase 8's proven manual cp -L workaround for all 3 configs
- Rationale: Reliable pattern already validated in Phase 8

**3. Targeted --force flag application**
- Applied configs with specific paths (--force ~/.config/kitty/kitty.conf ~/.config/ghostty/config ~/.wezterm.lua)
- Rationale: Bypass Bitwarden auth gate while applying only Phase 9 files (not all managed files)

## Deviations from Plan

None - plan executed with minor execution order adjustment (update .chezmoiignore before adding files instead of after). This was necessary due to ignore patterns blocking file addition.

## Issues Encountered

**1. chezmoi add --follow limitation**
- **Problem:** chezmoi add --follow failed for files within directories (ghostty, kitty) with "follow and recursive are mutually exclusive" error
- **Resolution:** Used manual cp -L workaround from Phase 8 for all 3 terminal configs
- **Outcome:** All files successfully added to chezmoi source as real files (not symlinks)

**2. Execution order requirement**
- **Problem:** Files being ignored by .chezmoiignore Phase 9 patterns
- **Resolution:** Updated .chezmoiignore to remove Phase 9 block before adding files
- **Outcome:** Files successfully added and managed by chezmoi

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for Phase 10 (Dev Tools with Secrets):**
- All 3 terminal emulator configs successfully migrated to chezmoi
- Dotbot symlinks replaced with real files
- Cache exclusion patterns prevent spurious diffs from kitty theme switching
- Phase 9 pending block removed from .chezmoiignore
- No blockers or concerns

**Phase 10 notes:**
- Dev tools (lazygit, atuin, aider, gpg-agent) may contain secrets requiring Bitwarden template integration
- Pattern established: use targeted --force flag for specific paths to bypass auth gates
- Pattern established: manual cp -L workaround for chezmoi add --follow limitation

---
*Phase: 09-terminal-emulators*
*Completed: 2026-02-09*

## Self-Check: PASSED

All claims verified:
- ✓ ~/.local/share/chezmoi/private_dot_config/kitty/kitty.conf exists
- ✓ ~/.local/share/chezmoi/private_dot_config/ghostty/config exists
- ✓ ~/.local/share/chezmoi/dot_wezterm.lua exists
- ✓ Commit 8107da0 exists (Task 1)
- ✓ Commit 204cc8a exists (Task 2)
