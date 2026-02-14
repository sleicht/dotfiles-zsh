# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-14)

**Core value:** Cross-platform dotfiles that "just work" -- one repository that handles Mac vs Linux differences through templating, without requiring Nix expertise to maintain.
**Current focus:** v2.0 Performance — achieve < 300ms shell startup (currently 0.87s)

## Current Position

Phase: 20 of 22 (20-eval-caching-layer)
Plan: 01 of 02 (evalcache foundation complete)
Status: Phase 20 in progress - eval caching layer implementation
Last activity: 2026-02-14 -- evalcache plugin added, compinit simplified, sheldon source cached

Progress: [██████████░░░░░░░░░░] 50% (1 of 2 phase 20 plans complete)

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
- Total plans completed: 3
- Total commits: 5
- Latest plan: 20-01 (3 min, 2 tasks, 3 files)

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
- [Phase 19-01]: Three-stage baseline established: 314.6ms startup (5% above 300ms target) with phantom completion (112ms), mise (29ms), oh-my-posh (28ms) as primary optimisation targets
- [Phase 19-02]: Applied four zero-risk quick wins achieving 30.9ms improvement (9.8% faster) and 300ms target (283.7ms) via duplicate load removal, pure-zsh SSH parsing, command check optimisation, and PATH deduplication
- [Phase 20-01]: Use -C flag universally for compinit (skip security checks in single-user dotfiles), cache sheldon source with lock file mtime invalidation, background zcompdump compilation in .zlogin to never block startup

### Key Findings (v2.0 Startup Analysis)

**Identified sync bottlenecks in shell startup chain:**
- oh-my-posh init: 50-200ms (hooks.zsh line 11)
- mise activate: 30-80ms (external.zsh line 65)
- carapace _carapace: 20-50ms (carapace.zsh)
- zoxide init: 20-40ms (external.zsh line 56)
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
- Shell startup time: 283.7ms (post-quick-wins, 2026-02-14, target < 300ms ACHIEVED ✓)
- chezmoi diff performance: ~13s (upstream limitation with .claude/ directory)

## Session Continuity

Last session: 2026-02-14
Stopped at: Completed 20-01-PLAN.md (evalcache foundation)
Resume file: None
