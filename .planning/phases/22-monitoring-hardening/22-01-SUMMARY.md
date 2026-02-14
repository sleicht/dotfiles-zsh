---
phase: 22-monitoring-hardening
plan: 01
subsystem: performance
tags: [zsh, startup-monitoring, profiling, zprof, epochrealtime, chezmoi, evalcache]

# Dependency graph
requires:
  - phase: 20-02-evalcache
    provides: _evalcache function for caching tool init commands
  - phase: 21-02-sheldon-sync-defer
    provides: Two-tier loading architecture for shell startup
provides:
  - Startup time self-monitoring with 300ms threshold warning
  - Conditional zprof profiling via ZSH_PROFILE_STARTUP env var
  - Automatic evalcache invalidation on tool version changes
affects: [future-performance-phases, shell-optimization]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "EPOCHREALTIME-based startup time measurement"
    - "chezmoi run_onchange_ hooks for cache invalidation"
    - "Conditional zprof profiling via environment variable"

key-files:
  created:
    - run_onchange_after_03-clear-evalcache.sh.tmpl
  modified:
    - dot_zshenv
    - dot_zshrc.tmpl

key-decisions:
  - "Use EPOCHREALTIME for microsecond-precision startup timing"
  - "Set 300ms as performance threshold for startup warnings"
  - "Track only evalcache-relevant tools (oh-my-posh, zoxide, atuin, carapace) excluding mise"
  - "Omit intelli-shell from version tracking (not available on this system)"

patterns-established:
  - "ZSHRC_START_TIME set in dot_zshenv, consumed in dot_zshrc.tmpl"
  - "LAST_SHELL_STARTUP_MS exported for user inspection after startup"
  - "ZSH_PROFILE_STARTUP=1 env var enables detailed profiling"
  - "chezmoi sha256sum template function for version tracking"

# Metrics
duration: 2.1min
completed: 2026-02-14
---

# Phase 22 Plan 01: Startup Monitoring & Evalcache Invalidation Summary

**EPOCHREALTIME-based startup monitoring with 300ms threshold warnings and automatic evalcache invalidation on tool version changes**

## Performance

- **Duration:** 2.1 min
- **Started:** 2026-02-14T19:52:11Z
- **Completed:** 2026-02-14T19:54:16Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added microsecond-precision startup time monitoring using EPOCHREALTIME
- Implemented 300ms threshold warning with diagnostic instructions
- Created chezmoi run_onchange_ hook that automatically clears evalcache when tool versions change
- Enabled conditional zprof profiling via ZSH_PROFILE_STARTUP environment variable

## Task Commits

Each task was committed atomically:

1. **Task 1: Add EPOCHREALTIME self-monitoring and conditional zprof** - `8fb12d1` (feat)
2. **Task 2: Add chezmoi hook for evalcache invalidation** - `274c09d` (feat)

## Files Created/Modified
- `dot_zshenv` - Added ZSHRC_START_TIME capture with EPOCHREALTIME and conditional zprof loading
- `dot_zshrc.tmpl` - Added startup duration calculation, 300ms warning, and zprof output
- `run_onchange_after_03-clear-evalcache.sh.tmpl` - chezmoi hook tracking oh-my-posh, zoxide, atuin, carapace versions and clearing evalcache on changes

## Decisions Made

1. **EPOCHREALTIME over date command**: Native zsh module provides microsecond precision with zero overhead vs spawning external date process
2. **300ms threshold**: Aligned with v2.0 Performance milestone target established in Phase 19 baseline
3. **Integer comparison**: Truncate milliseconds to integer with `${_zshrc_elapsed%.*}` for reliable threshold comparison
4. **Selective tool tracking**: Only track tools cached via evalcache (Phase 20-02); exclude mise (directory-dependent) and intelli-shell (not available)
5. **sha256sum checksums**: Use chezmoi builtin sha256sum template function to detect tool version changes

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - implementation was straightforward with no blocking issues.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Startup monitoring infrastructure complete and operational
- LAST_SHELL_STARTUP_MS currently shows 148-244ms (well under 300ms target)
- ZSH_PROFILE_STARTUP=1 profiling confirms evalcache delivering expected performance gains
- Ready for additional hardening and security measures in Phase 22 Plan 02

## Self-Check

Verifying plan deliverables:

**Files exist:**
- dot_zshenv: FOUND
- dot_zshrc.tmpl: FOUND
- run_onchange_after_03-clear-evalcache.sh.tmpl: FOUND

**Commits exist:**
- 8fb12d1: FOUND
- 274c09d: FOUND

**Functional verification:**
- LAST_SHELL_STARTUP_MS exported: ✓ (244ms observed)
- 300ms warning triggers correctly: ✓ (tested with ZSH_PROFILE_STARTUP=1)
- zprof output appears with ZSH_PROFILE_STARTUP=1: ✓
- evalcache hook renders with sha256 hashes: ✓

## Self-Check: PASSED

---
*Phase: 22-monitoring-hardening*
*Completed: 2026-02-14*
