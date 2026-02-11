---
phase: 08-basic-configs-cli-tools
plan: 03
subsystem: cli-tools
tags: [bat, syntax-highlighting, theme, environment-variables, regression-testing]

# Dependency graph
requires:
  - phase: 08-basic-configs-cli-tools
    provides: bat config managed by chezmoi with Dracula theme specified
provides:
  - bat syntax highlighting now uses Dracula theme from config file
  - BAT_THEME environment variable removed (no longer overrides config)
  - Regression check added to prevent BAT_THEME re-introduction
  - UAT gap from Phase 8 closed
affects: [verification, cli-tools, shell-environment]

# Tech tracking
tech-stack:
  added: []
  patterns: [environment-variable-precedence, config-file-priority, regression-prevention]

key-files:
  created: []
  modified:
    - zsh.d/variables.zsh
    - scripts/verify-checks/08-basic-configs.sh

key-decisions:
  - "Removed BAT_THEME env var to allow bat config file precedence"
  - "Kept SOBOLE_SYNTAX_THEME variable for potential use by other tools"
  - "Added regression check to verification script to prevent BAT_THEME re-introduction"

patterns-established:
  - "Environment variables override config files - remove env var when config file should be source of truth"
  - "Add regression checks to verification scripts when fixing override issues"

# Metrics
duration: 2min
completed: 2026-02-11
---

# Phase 8 Plan 03: bat Theme Fix Summary

**Removed BAT_THEME environment variable override to allow bat config file (Dracula theme) to take effect**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-11T22:53:40Z
- **Completed:** 2026-02-11T22:55:33Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Identified and removed BAT_THEME environment variable override in zsh.d/variables.zsh
- Confirmed bat now uses Dracula theme from chezmoi-managed config file
- Added regression check to verification script to prevent BAT_THEME re-introduction
- Closed UAT gap: bat theme configuration now works as user expected

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove BAT_THEME env var override and add verification check** - `1b86d5e` (fix)
2. **Task 2: Verify bat uses Dracula theme** - `31a4a9f` (docs - checkpoint approval)

## Files Created/Modified
- `zsh.d/variables.zsh` - Removed BAT_THEME export (lines 92-95), kept SOBOLE_SYNTAX_THEME
- `scripts/verify-checks/08-basic-configs.sh` - Added Check 5 to verify BAT_THEME not exported (regression prevention)

## Decisions Made
- **Remove BAT_THEME entirely:** Environment variables override config files in bat. Since the chezmoi-managed config already specifies `--theme="Dracula"`, the env var export was preventing the config from taking effect. Removed the entire "=== bat ===" section from zsh.d/variables.zsh.
- **Keep SOBOLE_SYNTAX_THEME:** While not currently used by bat, this variable may be referenced by other tools in the future, so we preserved it.
- **Add regression check:** Added Check 5 to verification script that uses grep to confirm zsh.d/variables.zsh does NOT contain `export BAT_THEME`. This prevents accidental re-introduction of the override.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - straightforward fix applied cleanly.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 8 UAT gap now closed
- All Phase 8 configurations verified and working as expected
- Ready to proceed to Phase 11 (Claude Code directory migration) or any other remaining phases

## UAT Gap Closure

This plan was created to close the single UAT gap identified in Phase 8:

**Original Issue:** User reported that changing bat theme to Dracula in the config file had no effect.

**Root Cause:** BAT_THEME environment variable exported in zsh.d/variables.zsh (line 95) was overriding the config file setting. Environment variables take precedence over bat's config file.

**Resolution:** Removed BAT_THEME export. Config file is now the sole source of truth for bat theme configuration.

**Verification:** User confirmed in fresh shell that bat now renders files using the Dracula colour scheme (purple/pink/green) instead of the previous gruvbox-dark theme (warm orange/yellow).

**Status:** UAT gap closed ✓

---
*Phase: 08-basic-configs-cli-tools*
*Completed: 2026-02-11*

## Self-Check: PASSED

All artifacts verified:
- Files modified: zsh.d/variables.zsh, scripts/verify-checks/08-basic-configs.sh
- Commits: 1b86d5e (Task 1), 31a4a9f (Task 2)
- SUMMARY.md created
