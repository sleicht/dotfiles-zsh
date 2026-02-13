---
phase: 13-remove-legacy-config-files
plan: 01
subsystem: legacy-cleanup
tags: [scan, documentation, phase13]

dependency_graph:
  requires: []
  provides:
    - legacy-file-reference-scan
    - safe-delete-list
    - blocked-file-analysis
  affects:
    - 13-02-PLAN.md (deletion decisions)

tech_stack:
  added: []
  patterns:
    - reference-scanning
    - dependency-analysis

key_files:
  created:
    - .planning/phases/13-remove-legacy-config-files/13-SCAN-REPORT.md
  modified: []

decisions:
  - title: "Comprehensive scan before any deletions"
    rationale: "User decision: verify no references exist before removing legacy files"
    alternatives: ["Delete immediately", "Manual inspection"]
    impact: "Safe deletion path established"

metrics:
  duration_minutes: 4.5
  tasks_completed: 1
  files_scanned: 31
  completion_date: 2026-02-13
---

# Phase 13 Plan 01: Repository Scan for Legacy File References Summary

**One-liner:** Scanned 31 legacy files for references across repo and chezmoi; identified 6 safe deletions and 25 blocked by scripts/configs.

## What Was Done

Performed comprehensive reference scan of all legacy configuration files identified in Phase 13 requirements (LEGACY-01, LEGACY-02, LEGACY-04, LEGACY-05) to determine safe deletion order.

### Task 1: Scan repository for legacy file references ✓

**Created:** `.planning/phases/13-remove-legacy-config-files/13-SCAN-REPORT.md`

Scanned 31 legacy items across 4 categories:

1. **Category 1 - .config/ directories (10 items):**
   - aerospace, atuin, bat, btop, claude, ghostty, git, karabiner, lsd, zsh-abbr
   - Result: 1 SAFE, 9 BLOCKED

2. **Category 2 - .config/ flat files (17 items):**
   - aider.conf.yml, editorconfig, finicky.js, gpgagent, hushlogin, inputrc, kitty.conf, lazygit.yml, nanorc, oh-my-posh.omp.json, psqlrc, sqliterc, ssh_config, wezterm.lua, zprofile, zshenv, zshrc
   - Result: 3 SAFE, 14 BLOCKED

3. **Category 3 - zsh.d/ directory:**
   - Verified all 15 files have dot_zsh.d/ counterparts in chezmoi
   - Confirmed sheldon plugins.toml uses `local = "~/.zsh.d"`
   - Result: 0 SAFE, 1 BLOCKED (actively used by sheldon)

4. **Category 4 - Brewfiles (3 items):**
   - Brewfile, Brewfile_Client, Brewfile_Fanaka
   - Result: 2 SAFE, 1 BLOCKED

**Scan methodology:**
- Used ripgrep to search both repository and chezmoi source (`~/.local/share/chezmoi`)
- Excluded self-references, `.git/`, and `.planning/` directories
- Explicitly verified sheldon configuration for zsh.d/ path usage
- Cross-checked zsh.d/ file coverage against dot_zsh.d/ templates

**Key findings:**
- **6 files safe to delete immediately:** .config/claude, .config/gpgagent, .config/lazygit.yml, .config/ssh_config, Brewfile_Client, Brewfile_Fanaka
- **25 files blocked** by verification scripts, backup/restore scripts, sheldon config, or chezmoi references
- **Primary blockers:**
  - `scripts/verify-checks/*.sh` (blocks 15+ files)
  - `scripts/backup-dotfiles.sh`, `scripts/restore-dotfiles.sh`, `scripts/verify-backup.sh` (blocks 8+ files)
  - Sheldon `plugins.toml` (blocks zsh.d/)
  - Chezmoi cleanup script (blocks Brewfile)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All verification criteria met:

- ✓ Scan report exists at `.planning/phases/13-remove-legacy-config-files/13-SCAN-REPORT.md`
- ✓ Contains results for all 4 categories (10 dirs + 17 flat files + zsh.d/ + 3 Brewfiles)
- ✓ Each entry has SAFE or BLOCKED status
- ✓ Sheldon plugins.toml explicitly checked and documented
- ✓ zsh.d/ file coverage against dot_zsh.d/ verified and documented

## Success Criteria Met

- ✓ Scan report written with per-file status for all 31 legacy items
- ✓ Report clearly states which files are safe (6) and blocked (25)
- ✓ All 4 requirement categories covered (LEGACY-01, LEGACY-02, LEGACY-04, LEGACY-05)
- ✓ No false negatives: scanned both repo AND chezmoi source
- ✓ Sheldon plugins.toml explicitly checked for zsh.d/ paths
- ✓ zsh.d/ to dot_zsh.d/ coverage verified

## Next Steps for Plan 02

Based on scan results, Plan 02 must:

1. **Phase 1:** Remove blocking scripts first
   - `scripts/verify-checks/08-basic-configs.sh` (blocks 11 files)
   - `scripts/verify-checks/09-terminal-emulators.sh` (blocks 3 files)
   - `scripts/verify-checks/10-dev-tools-secrets.sh` (blocks 3 files)
   - `scripts/backup-dotfiles.sh` (blocks 3 files)
   - `scripts/restore-dotfiles.sh` (blocks 6 files)
   - `scripts/verify-backup.sh` (blocks 1 file)

2. **Phase 2:** Update chezmoi references
   - `run_onchange_after_02-cleanup-packages.sh.tmpl` (Brewfile reference)
   - Git hook scripts and `dot_gitconfig`
   - Documentation files

3. **Phase 3:** Handle zsh.d/ special case
   - Verify sheldon will use ~/.zsh.d from chezmoi
   - Confirm .zsh.d.private handling

4. **Phase 4:** Delete safe files immediately (6 files)

## Impact

**Files created:** 1 (scan report)

**Decisions enabled:** Plan 02 can now proceed with confidence about deletion order and dependencies.

**Risk mitigation:** Prevents accidental deletion of files still referenced by active scripts or configurations.

## Self-Check: PASSED

**Files verified:**
- ✓ FOUND: .planning/phases/13-remove-legacy-config-files/13-SCAN-REPORT.md

**Commits verified:**
- ✓ FOUND: 06888a2 (docs(13-01): scan repository for legacy file references)

**Content verified:**
- ✓ Report contains 4 category sections
- ✓ Report contains 31 individual file assessments
- ✓ Report contains sheldon plugins.toml analysis
- ✓ Report contains zsh.d/ coverage verification
- ✓ Report contains next steps section

All claims in summary verified against actual files and commits.
