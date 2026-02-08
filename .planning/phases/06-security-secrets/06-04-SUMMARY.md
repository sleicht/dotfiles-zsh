---
phase: 06-security-secrets
plan: 04
subsystem: security
tags: [bitwarden, chezmoi, secrets, git-config, template]

# Dependency graph
requires:
  - phase: 06-03
    provides: "Age encryption and Bitwarden CLI installed"
provides:
  - "Bitwarden integrated as secret source for chezmoi templates"
  - "Git config email sourced from Bitwarden vault"
  - "Bitwarden naming convention documented in .chezmoidata.yaml"
affects: [06-05, future secret migration plans]

# Tech tracking
tech-stack:
  added: []
  patterns: ["bitwarden template functions for secret sourcing", "gitleaks:allow annotations on bitwarden lines"]

key-files:
  created: []
  modified:
    - "~/.local/share/chezmoi/.chezmoi.yaml.tmpl"
    - "~/.local/share/chezmoi/.chezmoidata.yaml"
    - "~/.local/share/chezmoi/private_dot_gitconfig_local.tmpl"

key-decisions:
  - "Use YAML bitwarden.command config (not TOML) matching chezmoi config format"
  - "Omit bitwarden.unlock: auto (not supported in chezmoi v2.69.3 YAML config)"
  - "Keep prompt variables in .chezmoi.yaml.tmpl as fallback for other templates"
  - "Add gitleaks:allow inline comments on bitwarden template lines"

patterns-established:
  - "bitwarden item naming: dotfiles/{type}/{name} (shared/client/personal)"
  - "bitwardenFields for custom fields, bitwarden for login fields"
  - "Secret rotation: update Bitwarden item, run chezmoi apply"

# Metrics
duration: 8min
completed: 2026-02-08
---

# Phase 6 Plan 04: Bitwarden Integration Summary

**Git config name and email sourced from Bitwarden vault via chezmoi bitwarden/bitwardenFields template functions**

## Performance

- **Duration:** 8 min
- **Started:** 2026-02-08T11:04:16Z
- **Completed:** 2026-02-08T11:12:18Z
- **Tasks:** 2 (1 checkpoint:human-action + 1 auto)
- **Files modified:** 3

## Accomplishments

- Configured Bitwarden CLI as chezmoi secret source (`bitwarden.command: bw`)
- Templated git config to source user.name from `bitwarden "item"` and email from `bitwardenFields "item"` custom fields
- Documented Bitwarden naming convention in `.chezmoidata.yaml` (dotfiles/shared, dotfiles/client, dotfiles/personal)
- Added `# gitleaks:allow` annotations on all bitwarden template lines to prevent false positives

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Bitwarden items for dotfile secrets** - checkpoint:human-action (user created `dotfiles/shared/git-config` item)
2. **Task 2: Configure Bitwarden in chezmoi and template git config** - `04db404` (feat)

## Files Created/Modified

- `~/.local/share/chezmoi/.chezmoi.yaml.tmpl` - Added `bitwarden: command: "bw"` config section
- `~/.local/share/chezmoi/.chezmoidata.yaml` - Added bitwarden naming convention reference
- `~/.local/share/chezmoi/private_dot_gitconfig_local.tmpl` - Replaced hardcoded name/email with bitwarden template functions

## Decisions Made

- **YAML bitwarden config:** Used `bitwarden: command: "bw"` in YAML format (plan suggested TOML-like `[bitwarden]` syntax which doesn't match chezmoi's YAML config)
- **No `unlock: auto`:** Omitted this setting as it's not a supported YAML config option in chezmoi v2.69.3. Bitwarden unlock is managed via `BW_SESSION` environment variable
- **Kept prompt variables:** `$personalEmail` and `$workEmail` prompt variables retained in `.chezmoi.yaml.tmpl` as they may be used by other templates or as fallback
- **gitleaks:allow annotations:** Added inline `# gitleaks:allow` on bitwarden template lines for belt-and-suspenders security scanning protection

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected bitwarden config syntax from TOML to YAML**
- **Found during:** Task 2 (Step 1)
- **Issue:** Plan specified TOML syntax (`[bitwarden]`, `command = "bw"`, `unlock = "auto"`) but chezmoi config is YAML
- **Fix:** Used proper YAML syntax: `bitwarden: command: "bw"`. Omitted `unlock` as it's not a valid chezmoi YAML config key
- **Files modified:** `~/.local/share/chezmoi/.chezmoi.yaml.tmpl`
- **Verification:** `chezmoi cat-config` parses without errors; `chezmoi verify` attempts bitwarden call (confirming config is active)
- **Committed in:** `04db404`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Syntax correction necessary for chezmoi compatibility. No scope creep.

## Issues Encountered

- Bitwarden vault locked during testing -- `chezmoi verify` and `chezmoi execute-template` both attempt to call `bw` which requires an active session. Template syntax confirmed valid (chezmoi recognises the functions and attempts execution). Full end-to-end verification requires user to unlock Bitwarden first with `export BW_SESSION="$(bw unlock --raw)"`.

## Secret Rotation Workflow

To rotate secrets managed via Bitwarden:
1. Update the secret in Bitwarden (e.g., change email in `dotfiles/shared/git-config`)
2. Ensure Bitwarden is unlocked: `export BW_SESSION="$(bw unlock --raw)"`
3. Run `chezmoi apply ~/.gitconfig_local`
4. Verify: `cat ~/.gitconfig_local` shows updated value

## User Setup Required

Before `chezmoi apply` can use Bitwarden templates, the user must:
1. Run `chezmoi init` to regenerate config (picks up new `bitwarden.command` setting)
2. Unlock Bitwarden: `export BW_SESSION="$(bw unlock --raw)"`
3. Run `chezmoi apply ~/.gitconfig_local` to verify

## Next Phase Readiness

- Bitwarden integration complete, ready for additional secret templates (API keys, tokens)
- Plan 06-05 can proceed (GPG key management)
- Pattern established: any future secret can be stored in Bitwarden and referenced via `bitwarden`/`bitwardenFields` template functions

## Self-Check: PASSED

- All 3 modified files exist in chezmoi source directory
- Commit `04db404` verified in chezmoi repo
- SUMMARY.md created at `.planning/phases/06-security-secrets/06-04-SUMMARY.md`
- Bitwarden config present in `.chezmoi.yaml.tmpl` (1 reference)
- Bitwarden naming convention in `.chezmoidata.yaml` (2 references)
- Bitwarden template functions in `private_dot_gitconfig_local.tmpl` (3 references)
- gitleaks:allow annotations present (3 annotations)

---
*Phase: 06-security-secrets*
*Completed: 2026-02-08*
