# Phase 4: Package Management Migration - Context

**Gathered:** 2026-01-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Automate package installation via chezmoi and remove Nix completely. Users run `chezmoi apply` and all Homebrew packages install/update automatically. Machine-specific package lists consolidated into `.chezmoidata` format. Nix is fully removed from the system and repository. macOS-only scope — Linux package management is out of scope.

</domain>

<decisions>
## Implementation Decisions

### Package list structure
- Common packages shared across all machines, with machine-specific additions (common + overrides pattern)
- Claude's discretion on grouping approach (by category vs flat) — pick what fits the existing Brewfile structure best
- macOS only — no Linux package management in this phase
- VS Code extensions stay managed separately (Settings Sync) — not included in chezmoidata

### Brewfile generation
- Claude's discretion on handling different package types (formulae, casks, taps, mas apps) — pick cleanest chezmoi templating approach
- Generated Brewfile lives at `~/.Brewfile` for `brew bundle --global` compatibility
- Full sync mode: `brew bundle cleanup` removes packages not in Brewfile
- Deleted packages logged to a "deleted-packages" logfile for audit trail
- Old Brewfile_Client and Brewfile_Fanaka replaced completely once chezmoidata verified working

### Nix removal
- Claude to investigate what Nix is currently managing on the system (services, Home Manager modules) before removal
- All packages available via Homebrew — no Nix-only dependencies
- Complete removal: Nix store, nix-darwin, Home Manager, config files, shell hooks, /nix volume — everything
- nix-config/ directory deleted from repo (git history preserves it)

### Installation behaviour
- brew bundle runs automatically during `chezmoi apply`
- Uses `run_onchange_` script: only re-runs when chezmoidata package list changes (fast applies when nothing changed)
- Full Homebrew output shown during installation (not summarised)
- chezmoi handles installing Homebrew itself on fresh systems via `run_once_` script — true one-command bootstrap

### Claude's Discretion
- Package grouping strategy (by category vs flat list)
- Brewfile template structure (single vs multiple files, section organisation)
- Nix removal script implementation and safety checks
- Exact run_onchange hash strategy for detecting package list changes
- Deleted-packages logfile format and location

</decisions>

<specifics>
## Specific Ideas

- User wants deleted packages logged when `brew bundle cleanup` removes them — audit trail for what was removed and when
- Full sync (add + remove) rather than add-only — system stays clean and matches the declared state
- One-command bootstrap: fresh macOS → `chezmoi init && chezmoi apply` → working system with all packages

</specifics>

<deferred>
## Deferred Ideas

- Linux package management (apt/linuxbrew) — future phase or when needed
- VS Code extension management via chezmoi — stays with Settings Sync

</deferred>

---

*Phase: 04-package-management-migration*
*Context gathered: 2026-01-27*
