# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-14)

**Core value:** Cross-platform dotfiles that "just work" -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.
**Current focus:** v2.0 Performance — achieve < 300ms shell startup (currently 0.87s)

## Current Position

Phase: 22 of 22 (22-monitoring-hardening)
Plan: 02 of 02
Status: Complete - v2.0 Performance milestone achieved
Last activity: 2026-02-14 -- created smoke test script and validated final performance at 139.8ms (53.4% better than 300ms target)

Progress: [████████████████████████] 100% (2 of 2 phase 22 plans complete)

## Performance Metrics

**Velocity (v1.0.0):**
- Total plans completed: 25
- Average duration: 7.4 min
- Total execution time: 3.10 hours

**Velocity (v1.1):**
- Total plans completed: 13
- Total commits: 57
- Timeline: 4 days (2026-02-08 to 2026-02-12)

**Velocity (v1.2):**
- Total plans completed: 7
- Total commits: 40
- Timeline: 2 days (2026-02-13 to 2026-02-14)
- Net lines removed: -16,609

**Velocity (v2.0):**
- Total plans completed: 8
- Total commits: 13
- Latest plan: 22-02 (4.6 min, 2 tasks, 1 file)

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
- [Phase 19-01]: Three-stage baseline established: 314.6ms startup (5% above 300ms target) with phantom completion (112ms), mise (29ms), oh-my-posh (28ms) as primary optimisation targets
- [Phase 19-02]: Applied four zero-risk quick wins achieving 30.9ms improvement (9.8% faster) and 300ms target (283.7ms) via duplicate load removal, pure-zsh SSH parsing, command check optimisation, and PATH deduplication
- [Phase 20-01]: Use -C flag universally for compinit (skip security checks in single-user dotfiles), cache sheldon source with lock file mtime invalidation, background zcompdump compilation in .zlogin to never block startup
- [Phase 20-02]: Use _evalcache for all static eval init calls (oh-my-posh, zoxide, atuin, carapace, intelli-shell); leave mise uncached due to directory-dependent output generation
- [Phase 21-01]: Split zsh.d files into sync (prompt-critical: oh-my-posh, FZF/atuin keybindings) and defer (deferrable: zoxide, mise, SSH hosts) variants to enable Sheldon plugin group separation; added mise shims to .zprofile for immediate PATH access
- [Phase 21-02]: Reconfigured Sheldon with dotfiles-sync (immediate source) and dotfiles-defer (zsh-defer source) plugin groups, achieving two-tier loading architecture with 128.7ms total startup (1.9% improvement) and ~47% perceived improvement (70ms to prompt vs 131ms total)
- [Phase 22-01]: Use EPOCHREALTIME for microsecond-precision startup timing with 300ms threshold warning; track only evalcache-relevant tools (oh-my-posh, zoxide, atuin, carapace) via chezmoi run_onchange_ hook for automatic cache invalidation
- [Phase 22-02]: Created comprehensive smoke test script validating 13 critical shell checks (prompt, PATH, completions, keybindings, tools, plugins, monitoring); final three-stage measurement confirms 139.8ms startup (53.4% better than 300ms target) with negligible monitoring overhead

### Key Findings (v2.0 Startup Analysis)

**Identified sync bottlenecks in shell startup chain:**
- ~~oh-my-posh init: 50-200ms (hooks.zsh line 11)~~ [FIXED 20-02: cached via evalcache]
- mise activate: 30-80ms (external.zsh line 65) [NOT CACHED: directory-dependent output]
- ~~carapace _carapace: 20-50ms (carapace.zsh)~~ [FIXED 20-02: cached via evalcache]
- ~~zoxide init: 20-40ms (external.zsh line 56)~~ [FIXED 20-02: cached via evalcache]
- ssh-add --apple-load-keychain: unknown (ssh.zsh)
- ~~ruby SSH host parsing: unknown (completions.zsh line 16)~~ [FIXED 19-02: replaced with pure-zsh]
- Large completion scripts: wt.zsh (214 lines), lens-completion.zsh (214 lines)
- ~~Potential double-load: zsh-autosuggestions and zsh-syntax-highlighting sourced both in hooks.zsh (sync) and via Sheldon (deferred)~~ [FIXED 19-02: removed duplicate loads]

**Current optimisations already in place:**
- Sheldon with zsh-defer for 12 plugins (fzf-tab, fzf-git, zsh-syntax-highlighting, zsh-autosuggestions, zsh-sdkman x2, zsh-abbr, 6 ohmyzsh plugins)
- compinit caching with 24h threshold
- dotfiles and dotfiles-private loaded as sync source (not deferred)

### Pending Todos

None.

### Blockers/Concerns

**Known Limitations (from PROJECT.md):**
- Shell startup time: 139.8ms total (post-monitoring-phase, 2026-02-14, 55.6% improvement from 314.6ms baseline, 53.4% better than 300ms target)
- Perceived startup time: ~70ms to prompt (Phase 21-02 measurement, 77.7% improvement from baseline)
- chezmoi diff performance: ~13s (upstream limitation with .claude/ directory)

## Session Continuity

Last session: 2026-02-14
Stopped at: Completed 22-02-PLAN.md (Smoke test and final performance validation) - Phase 22 Complete, v2.0 Performance milestone achieved
Resume file: None
