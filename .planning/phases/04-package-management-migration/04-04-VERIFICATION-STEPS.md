# Phase 04-04: Verification Steps

## What was built

1. All packages consolidated into `.chezmoidata.yaml` (171 packages, single source of truth)
2. `chezmoi apply` generates `~/.Brewfile` (178 lines) and installs packages automatically
3. Package cleanup with audit trail (`~/.local/state/homebrew-cleanup.log`)
4. Homebrew bootstrap for fresh systems (`run_once_before`)
5. `nix-config/` deleted from repository (12 files)
6. Nix removal script prints safe manual instructions

## How to verify

1. Run `chezmoi apply --verbose` — this will create ~/.Brewfile, install packages, run cleanup, and print Nix removal instructions
2. Open a new terminal — verify shell works correctly
3. Run `cat ~/.Brewfile | head -20` — verify expected packages
4. Run `brew bundle check --global` — should report all satisfied
5. Run `chezmoi data | grep -A 5 packages` — verify data structure
6. Verify nix-config/ is gone: `ls nix-config/ 2>/dev/null || echo "deleted"`
7. (Optional) Follow Nix removal instructions to remove Nix from system
8. (Optional) After removal + reboot: `ls /nix 2>/dev/null || echo "Nix removed"`

**Note:** Running `chezmoi apply` will trigger `brew bundle --global --verbose` which will install/update all packages. This may produce significant output.

## After verification

Type "approved" to complete Phase 4, or describe any issues found.
