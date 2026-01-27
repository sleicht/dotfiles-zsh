---
phase: 04-package-management-migration
plan: 01
subsystem: package-management
tags: [homebrew, brewfile, chezmoi, nix-darwin, package-consolidation]

# Dependency graph
requires:
  - phase: 03-templating-machine-detection
    provides: .chezmoidata.yaml structure for static data
provides:
  - Complete package inventory in .chezmoidata.yaml (171 packages across all categories)
  - Single source of truth for Homebrew packages replacing 3 separate Brewfiles
  - Machine-type-based package structure (common, client, fanaka)
affects: [04-02-generate-brewfile-templates, 04-03-automate-package-install]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Package list consolidation pattern (common + machine-specific)
    - Alphabetically sorted package lists for maintainability

key-files:
  created: []
  modified:
    - .chezmoidata.yaml

key-decisions:
  - "Structured packages as common (all machines) vs client-specific vs fanaka-specific"
  - "Excluded asdf (being replaced by mise in Phase 5)"
  - "Merged Nix-managed Homebrew packages from apps.nix and apps-fanaka.nix as most up-to-date source"
  - "Deduplicated CJ-Systems/homebrew-gitflow-cjs tap (case-sensitive variants)"

patterns-established:
  - "Package lists alphabetically sorted within each category"
  - "All OS conditionals (if OS.mac?) removed - template handles OS detection"
  - "Separate sections for taps, brews, casks, fonts, and MAS apps"

# Metrics
duration: 2min
completed: 2026-01-27
---

# Phase 04 Plan 01: Package Inventory Consolidation Summary

**Complete package inventory in .chezmoidata.yaml: 82 common brews, 22 common casks, 171 total packages merged from 5 source files**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-27T13:34:04Z
- **Completed:** 2026-01-27T13:35:44Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Merged all packages from Brewfile, Brewfile_Client, Brewfile_Fanaka, apps.nix, and apps-fanaka.nix
- Created structured package data with common + machine-specific sections
- Deduplicated packages across all sources (e.g., mas, trivy, git appeared multiple times)
- Alphabetically sorted all package lists for maintainability
- Excluded asdf (replaced by mise in Phase 5)

## Task Commits

Each task was committed atomically:

1. **Task 1: Merge and deduplicate all package lists into .chezmoidata.yaml** - `112ab57` (feat)

## Files Created/Modified
- `.chezmoidata.yaml` - Complete package inventory with 171 packages structured by machine type

## Package Summary

### Taps (16 total)
All taps merged and deduplicated from all sources.

### Brews
- **Common:** 82 packages (all machines need)
- **Client:** 12 packages (work machine only)
- **Fanaka:** 3 packages (personal machine only)

### Casks
- **Common:** 22 apps (all machines need)
- **Client:** 28 apps (work machine only)
- **Fanaka:** 17 apps (personal machine only)

### Fonts (7 total)
All Nerd Fonts and Liberation fonts common to all machines.

### Mac App Store Apps
- **Common:** 2 apps (Racompass, Xcode)
- **Fanaka:** 8 apps (iFinance 5, kChat, LilyView, MacFamilyTree 10, etc.)

## Decisions Made

1. **Package structure:** Used common + machine-specific pattern (common_brews/common_casks vs client_brews/client_casks vs fanaka_brews/fanaka_casks) to support templating in next plan
2. **Excluded asdf:** Being replaced by mise in Phase 5, so not migrated to chezmoidata
3. **Nix-managed Homebrew as source of truth:** The apps.nix `homebrew` section contained the most comprehensive and up-to-date cask list, used as primary source
4. **Deduplication strategy:** Packages in BOTH global Brewfile AND machine-specific files placed in common sections (needed everywhere)
5. **Tap case sensitivity:** Merged both "CJ-Systems/homebrew-gitflow-cjs" and "cj-systems/gitflow-cjs" (Homebrew handles case-insensitive)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness

- Package data structure ready for template generation in 04-02
- All 171 packages captured and categorized
- chezmoi can read and template the package data (verified with `chezmoi execute-template`)
- Ready to generate machine-specific Brewfile templates

---
*Phase: 04-package-management-migration*
*Completed: 2026-01-27*
