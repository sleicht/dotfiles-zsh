---
phase: 05-tool-version-migration
plan: 01
subsystem: tooling
tags: [mise, chezmoi, runtime-versions, node, python, go, rust, java, ruby, terraform]

# Dependency graph
requires:
  - phase: 04-package-management-migration
    provides: chezmoi foundation, Homebrew package management, mise installed
provides:
  - Mise global configuration template managed by chezmoi
  - Centralised tool version data in .chezmoidata.yaml
  - Auto-install settings for missing runtimes
affects: [05-02-shell-activation, 05-03-project-version-management, 05-04-legacy-cleanup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Mise config as TOML in chezmoi private_dot_config
    - Tool versions stored in .chezmoidata.yaml for future templating

key-files:
  created:
    - ~/.local/share/chezmoi/private_dot_config/mise/config.toml.tmpl
  modified:
    - ~/.local/share/chezmoi/.chezmoidata.yaml

key-decisions:
  - "Use private_dot_config prefix for ~/.config directory"
  - "Store tool versions in .chezmoidata.yaml for potential machine-specific overrides"
  - "Enable idiomatic version files for node and python only (most common)"
  - "Remove deprecated task_auto_install setting"

patterns-established:
  - "Mise global config via chezmoi: private_dot_config/mise/config.toml.tmpl"
  - "Tool version data structure in .chezmoidata.yaml under tools.mise.global_tools"

# Metrics
duration: 8min
completed: 2026-01-29
---

# Phase 05 Plan 01: Mise Global Configuration Summary

**Chezmoi-managed mise global config with 7 runtime defaults (node, python, go, rust, java, ruby, terraform) and auto-install settings**

## Performance

- **Duration:** 8 min
- **Started:** 2026-01-29T18:25:00Z
- **Completed:** 2026-01-29T18:33:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Created mise global configuration template with 7 runtime tool defaults
- Established .chezmoidata.yaml data structure for mise tool versions
- Enabled auto-install for missing tools when entering directories
- Deployed config to ~/.config/mise/config.toml via chezmoi apply

## Task Commits

Each task was committed atomically:

1. **Task 1: Create mise config directory structure in chezmoi** - `71f1be9` (feat)
2. **Task 2: Update .chezmoidata.yaml with mise tool versions** - `8db7593` (feat)
3. **Task 3: Apply chezmoi and verify mise config deployed** - `6fd5f12` (fix)

## Files Created/Modified

- `~/.local/share/chezmoi/private_dot_config/mise/config.toml.tmpl` - Mise global configuration template with [tools], [settings], and [env] sections
- `~/.local/share/chezmoi/.chezmoidata.yaml` - Added tools.mise section with global_tools and settings data

## Decisions Made

- **private_dot_config prefix**: Using this prefix ensures ~/.config directory has correct permissions (600)
- **Tool versions in .chezmoidata.yaml**: Enables future templating for machine-specific version overrides if needed
- **Idiomatic version files**: Only enabled for node and python as they're most commonly used with .nvmrc/.python-version files
- **jobs = 4**: Reasonable parallelism for tool installation without overwhelming the system

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed deprecated task_auto_install setting**
- **Found during:** Task 3 (Apply chezmoi and verify mise config deployed)
- **Issue:** mise config ls showed warning: "unknown field in ~/.config/mise/config.toml: settings.task_auto_install"
- **Fix:** Removed task_auto_install from config template (deprecated/renamed in recent mise versions)
- **Files modified:** private_dot_config/mise/config.toml.tmpl
- **Verification:** mise config ls shows no warnings
- **Committed in:** `6fd5f12` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor fix to remove deprecated setting. No scope creep.

## Issues Encountered

- **chezmoi apply exit code 1**: MAS app iFinance 5 failed to upgrade (requires sudo/password) - unrelated to mise config work, did not block plan completion

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Mise global config deployed and active
- Auto-install settings enabled (not_found_auto_install=true, exec_auto_install=true)
- Ready for 05-02: Shell activation (mise hook integration with zsh)

---
*Phase: 05-tool-version-migration*
*Completed: 2026-01-29*
