---
status: complete
phase: 09-terminal-emulators
source: [09-01-SUMMARY.md, 09-02-SUMMARY.md]
started: 2026-02-09T23:10:00Z
updated: 2026-02-09T23:10:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete — 1 issue found and fixed inline]

## Tests

### 1. Ghostty launches with chezmoi-managed config
expected: Open Ghostty terminal. It should launch without errors, using the same fonts/colours/settings as before the migration. The config file at ~/.config/ghostty/config should be a real file (not a symlink).
result: pass

### 2. Wezterm launches with chezmoi-managed config
expected: Open WezTerm terminal. It should launch without errors, using the same fonts/colours/settings as before the migration. The config file at ~/.wezterm.lua should be a real file (not a symlink).
result: pass

### 3. Kitty config deployed via chezmoi
expected: Run `ls -la ~/.config/kitty/kitty.conf` — should show a regular file (no -> arrow indicating symlink). The file should contain your kitty configuration (~2600 lines). Kitty doesn't need to be installed for this check.
result: pass

### 4. Kitty cache files excluded from chezmoi diff
expected: Run `chezmoi diff` — no lines should mention kitty theme files (current-theme.conf, *-theme.auto.conf, themes/). If kitty theme files exist on disk, they should be invisible to chezmoi.
result: pass

### 5. Terminal config symlinks replaced
expected: Run `ls -la ~/.config/ghostty/config ~/.wezterm.lua ~/.config/kitty/kitty.conf` — all three should show as regular files with no -> symlink arrow. Dotbot symlinks have been replaced with chezmoi-managed real files.
result: pass

### 6. Verification script passes
expected: Run `./scripts/verify-configs.sh --phase 09` — all 12 checks should pass (file existence, not-a-symlink, no template errors, app parsability, cache exclusion). Exit code 0.
result: issue
reported: "Check 5 is hanging because chezmoi diff asks for the bitwarden masterpassword"
severity: major

## Summary

total: 6
passed: 5
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Verification script completes without hanging or prompting for credentials"
  status: fixed
  reason: "User reported: Check 5 is hanging because chezmoi diff asks for the bitwarden masterpassword"
  severity: major
  test: 6
  root_cause: "chezmoi diff evaluates templates which triggers Bitwarden auth gate; replaced with chezmoi managed --include=files which checks metadata only"
  artifacts:
    - path: "scripts/verify-checks/09-terminal-emulators.sh"
      issue: "Line 156: chezmoi diff triggers Bitwarden prompt"
  missing:
    - "Use chezmoi managed instead of chezmoi diff for cache exclusion check"
