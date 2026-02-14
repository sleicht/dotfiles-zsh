---
phase: 14-migrate-san-proxy-to-chezmoi
plan: 01
subsystem: shell-configuration
tags: [chezmoi, templating, zsh, san-proxy, machine-type]

# Dependency graph
requires:
  - phase: 02-chezmoi-foundation
    provides: chezmoi setup with machine_type templating
provides:
  - Client-only san-proxy sourcing via chezmoi templates
  - Template pattern for machine-type conditional configuration
affects: [15-runtime-management-cleanup]

# Tech tracking
tech-stack:
  added: []
  patterns: [chezmoi template conditionals for machine-type specific config]

key-files:
  created: [dot_zshrc.tmpl]
  modified: [.config/profile]

key-decisions:
  - "Use chezmoi template conditional with eq .machine_type 'client' for san-proxy"
  - "Remove san-proxy sourcing from legacy .config/profile"

patterns-established:
  - "Template pattern: Use {{- if eq .machine_type 'client' }} for work-specific configs"

# Metrics
duration: 1min
completed: 2026-02-14
---

# Phase 14 Plan 01: Migrate san-proxy to chezmoi Summary

**Client-only san-proxy sourcing via chezmoi template conditional using machine_type variable**

## Performance

- **Duration:** 1 min 40 sec
- **Started:** 2026-02-14T07:36:45Z
- **Completed:** 2026-02-14T07:38:25Z
- **Tasks:** 1
- **Files modified:** 2 (chezmoi source + legacy profile)

## Accomplishments
- Templated zshrc with client-only san-proxy conditional
- Removed san-proxy sourcing from legacy .config/profile
- Verified template renders correctly (san-proxy absent on personal machine)

## Task Commits

Each task was committed atomically:

1. **Task 1: Template zshrc with client-only san-proxy and clean up legacy profile**
   - Chezmoi: `0968a3f` (feat)
   - Dotfiles: `1ef7388` (chore)

## Files Created/Modified
- `~/.local/share/chezmoi/dot_zshrc.tmpl` - Templated zshrc with client-only san-proxy block
- `.config/profile` - Removed san-proxy sourcing

## Decisions Made
- Used chezmoi template conditional `{{- if eq .machine_type "client" }}` to wrap san-proxy sourcing
- Removed san-proxy block from legacy .config/profile (lines 2-4)
- Template uses existing `.machine_type` data variable from `.chezmoi.yaml.tmpl`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - straightforward template migration.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Phase 15 (runtime management cleanup). The san-proxy migration establishes the pattern for other machine-type specific configurations.

**Blockers:** None

**Notes:**
- This is a personal machine (machine_type != "client"), so san-proxy block correctly excluded from rendered ~/.zshrc
- Template pattern established can be reused for other work-specific configs
- Legacy .config/profile can be removed in future cleanup phase

## Self-Check: PASSED

All claims verified:
- ✓ dot_zshrc.tmpl exists in chezmoi source directory
- ✓ Chezmoi commit 0968a3f exists
- ✓ Dotfiles commit 1ef7388 exists
- ✓ Template has machine_type conditional
- ✓ .config/profile cleaned up (no san-proxy references)

---
*Phase: 14-migrate-san-proxy-to-chezmoi*
*Completed: 2026-02-14*
