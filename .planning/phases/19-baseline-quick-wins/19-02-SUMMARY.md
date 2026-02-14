---
phase: 19-baseline-quick-wins
plan: 02
subsystem: performance
tags: [zsh, shell-startup, optimisation, quick-wins, startup-time, performance-improvement]

# Dependency graph
requires:
  - phase: 19-baseline-quick-wins
    plan: 01
    provides: Three-stage performance baseline
provides:
  - Four zero-risk quick wins applied (duplicate load removal, pure-zsh SSH parsing, command check optimisation, PATH deduplication)
  - Post-optimisation measurements showing 30.9ms improvement
  - 300ms startup target achieved (283.7ms)
affects: [20-defer-heavy-tools, performance-optimisation]

# Tech tracking
tech-stack:
  added: []
  patterns: [pure-zsh-parameter-expansion, typeset-U-deduplication, zsh-command-hash-table]

key-files:
  created:
    - .planning/phases/19-baseline-quick-wins/post-quickwins-results.txt
  modified:
    - dot_zsh.d/hooks.zsh
    - dot_zsh.d/completions.zsh
    - dot_zsh.d/intelli-shell.zsh
    - dot_zsh.d/carapace.zsh
    - dot_zsh.d/atuin.zsh
    - dot_zsh.d/keybinds.zsh
    - dot_zsh.d/functions.zsh
    - dot_zshenv

key-decisions:
  - "Applied four quick wins targeting duplicate loads, external interpreter calls, and subshell spawns"
  - "Kept runtime command checks in aliases.zsh unchanged (as per research - not startup bottlenecks)"
  - "Used pure-zsh parameter expansion ${${${(M)${(f)...}:#Host *}#Host }:#*[*?]*} to replace Ruby SSH parsing"

patterns-established:
  - "Quick win pattern: Remove duplicate work (plugins loaded twice via hooks and Sheldon)"
  - "Pure-zsh pattern: Replace external interpreter calls (Ruby) with native ZSH parameter expansion"
  - "Command check optimisation: Use (( $+commands[tool] )) instead of command -v for startup guards"
  - "PATH management: Use typeset -U to automatically deduplicate PATH and FPATH arrays"

# Metrics
duration: 20min
completed: 2026-02-14
---

# Phase 19 Plan 02: Quick Wins Application Summary

**Applied four zero-risk quick wins achieving 30.9ms improvement (9.8% faster) and reaching < 300ms target (283.7ms) by eliminating duplicate plugin loads, Ruby SSH parsing, subshell spawns, and PATH duplication**

## Performance

- **Duration:** 20 min
- **Started:** 2026-02-14T15:10:27Z
- **Completed:** 2026-02-14T15:30:00Z (estimated)
- **Tasks:** 2 (both auto)
- **Files modified:** 8 (chezmoi source) + 1 (measurements)

## Accomplishments

- Applied QUICK-01: Removed duplicate zsh-autosuggestions and zsh-syntax-highlighting loads from hooks.zsh (already loaded via Sheldon defer)
- Applied QUICK-02: Replaced Ruby SSH config parsing with pure-zsh parameter expansion in completions.zsh
- Applied QUICK-03: Replaced all startup-time `command -v` checks with `(( $+commands[tool] ))` across 6 files
- Applied QUICK-04: Added `typeset -U PATH path FPATH fpath` to .zshenv for automatic deduplication
- Re-measured with hyperfine and zsh-bench, documenting 30.9ms improvement
- Achieved 300ms startup target: 283.7ms (5.4% below target)

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply quick wins QUICK-01 through QUICK-04** - `a7be280` (feat) - chezmoi source repo
2. **Task 2: Re-measure with three-stage methodology** - `546fadc` (chore) - main dotfiles repo

## Performance Results

### Before Quick Wins (Baseline from Plan 01)
- **hyperfine mean:** 314.6 ms ± 2.1 ms
- **zsh-bench first_prompt_lag_ms:** 533.518 ms
- **Gap to 300ms target:** 14.6 ms (5% over)

### After Quick Wins (Post-optimisation)
- **hyperfine mean:** 283.7 ms ± 6.2 ms
- **zsh-bench first_prompt_lag_ms:** 501.311 ms
- **Gap to 300ms target:** -16.3 ms (5.4% under)

### Improvement Delta
- **hyperfine improvement:** 30.9 ms (9.8% faster)
- **zsh-bench improvement:** 32.2 ms (6.0% faster)
- **Target status:** ACHIEVED ✓

## Quick Wins Applied

### QUICK-01: Remove Duplicate Plugin Loads
**File:** `dot_zsh.d/hooks.zsh`
**Change:** Deleted lines 19-20 loading zsh-autosuggestions and zsh-syntax-highlighting
**Reason:** These plugins were already loaded via Sheldon with `apply = ["defer"]` - the synchronous loads in hooks.zsh were pure waste
**Also:** Replaced `command -v oh-my-posh > /dev/null` with `(( $+commands[oh-my-posh] ))`

### QUICK-02: Replace Ruby SSH Config Parsing
**File:** `dot_zsh.d/completions.zsh`
**Before:** `` _cache_hosts=(`ruby -ne 'if /^Host\s+(.+)$/; print $1.strip, "\n"; end' $HOME/.ssh/config`) ``
**After:**
```zsh
_cache_hosts=()
if [[ -r $HOME/.ssh/config ]]; then
  _cache_hosts=(${${${(M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi
```
**Reason:** Eliminated external Ruby interpreter call during every shell startup
**Also:** Replaced `command -v phantom > /dev/null 2>&1` with `(( $+commands[phantom] ))`

### QUICK-03: Replace command -v with (( $+commands[tool] ))
**Files modified:** 6 files
- `dot_zsh.d/intelli-shell.zsh` line 5
- `dot_zsh.d/carapace.zsh` line 5
- `dot_zsh.d/atuin.zsh` line 5
- `dot_zsh.d/keybinds.zsh` line 16
- `dot_zsh.d/functions.zsh` line 287
- `dot_zsh.d/completions.zsh` line 49 (phantom)

**Reason:** `(( $+commands[tool] ))` uses ZSH's internal command hash table instead of spawning a subshell for each check
**Note:** Runtime checks in `aliases.zsh` (lines 105, 108, 111) were intentionally left unchanged - they're conditional alias definitions, not startup guards

### QUICK-04: Add PATH Deduplication
**File:** `dot_zshenv`
**Change:** Added `typeset -U PATH path FPATH fpath` after header comments
**Reason:** Ensures PATH and FPATH arrays contain only unique entries, reducing overhead from repeated path lookups
**Pattern:** ZSH automatically synchronises uppercase and lowercase versions (PATH ↔ path, FPATH ↔ fpath)

## Files Created/Modified

### Created
- `.planning/phases/19-baseline-quick-wins/post-quickwins-results.txt` - Complete post-optimisation measurements

### Modified (chezmoi source at ~/.local/share/chezmoi/)
- `dot_zsh.d/hooks.zsh` - Removed duplicate plugin loads, replaced command -v
- `dot_zsh.d/completions.zsh` - Pure-zsh SSH parsing, replaced command -v
- `dot_zsh.d/intelli-shell.zsh` - Replaced command -v
- `dot_zsh.d/carapace.zsh` - Replaced command -v
- `dot_zsh.d/atuin.zsh` - Replaced command -v
- `dot_zsh.d/keybinds.zsh` - Replaced command -v
- `dot_zsh.d/functions.zsh` - Replaced command -v (clone function fd check)
- `dot_zshenv` - Added PATH/FPATH deduplication

## Decisions Made

1. **Applied all four quick wins atomically** - These are zero-risk changes with no architectural implications, so all were applied in one commit
2. **Kept runtime checks in aliases.zsh unchanged** - Per 19-RESEARCH.md guidance, command -v checks in aliases.zsh (lines 105, 108, 111) are runtime conditional alias definitions, not startup bottlenecks
3. **Used pure-zsh parameter expansion for SSH parsing** - Pattern `${${${(M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }:#*[*?]*}` replaces Ruby with native ZSH, breaking down as:
   - `$(<file)` - Read file contents
   - `${(f)...}` - Split on newlines into array
   - `${(M)...:#Host *}` - Match lines starting with "Host "
   - `${...#Host }` - Remove "Host " prefix
   - `${...:#*[*?]*}` - Remove wildcard patterns

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**Issue: chezmoi apply permission error**
- **Context:** Running `chezmoi apply` hit permission error on `.claude/settings.json`
- **Resolution:** Applied only the specific modified files: `chezmoi apply ~/.zsh.d/hooks.zsh ~/.zsh.d/completions.zsh ...`
- **Impact:** None - all ZSH configuration files were successfully deployed

**Discovery: Improvement less than expected**
- **Expected:** 100-150ms improvement from quick wins
- **Actual:** 30.9ms improvement (9.8% faster)
- **Analysis:** The duplicate plugin loads may have been mostly deferred by Sheldon already, and Ruby SSH parsing impact varies based on SSH config size. Most startup time is still in sync tool initialisation (phantom 112ms, mise 29ms, oh-my-posh 28ms from baseline profiling)
- **Outcome:** Despite smaller gains, 300ms target achieved. Next phase will target remaining bottlenecks for further improvement.

## User Setup Required

None - all changes are internal ZSH configuration optimisations.

## Next Phase Readiness

**Ready for Phase 20 (defer-heavy-tools)** with:
- 300ms startup target achieved (283.7ms)
- Quick wins exhausted - further gains require deferring heavy tools
- Baseline and post-optimisation measurements documented for comparison
- Primary bottlenecks identified: phantom (112ms), mise (29ms), oh-my-posh (28ms)

**No blockers.** Shell fully functional, all verification passed.

## Verification Results

All verification criteria passed:

- ✓ `grep -n 'zsh-autosuggestions\|zsh-syntax-highlighting' ~/.zsh.d/hooks.zsh` returns nothing (duplicate loads removed)
- ✓ `grep -n 'ruby' ~/.zsh.d/completions.zsh` returns nothing (Ruby parsing removed)
- ✓ `grep -rn 'command -v' ~/.zsh.d/` returns only aliases.zsh and commented direnv (startup guards replaced)
- ✓ `grep -n 'typeset -U' ~/.zshenv` shows deduplication line at line 8
- ✓ New terminal starts without errors
- ✓ Autosuggestions work (via Sheldon defer)
- ✓ Syntax highlighting works (via Sheldon defer)
- ✓ SSH tab completion works (pure-zsh implementation)
- ✓ oh-my-posh prompt renders correctly

## Self-Check: PASSED

**Created files exist:**
```
FOUND: .planning/phases/19-baseline-quick-wins/post-quickwins-results.txt
```

**Modified files deployed:**
```
VERIFIED: ~/.zsh.d/hooks.zsh (duplicate loads removed)
VERIFIED: ~/.zsh.d/completions.zsh (pure-zsh SSH parsing)
VERIFIED: ~/.zsh.d/intelli-shell.zsh (command check replaced)
VERIFIED: ~/.zsh.d/carapace.zsh (command check replaced)
VERIFIED: ~/.zsh.d/atuin.zsh (command check replaced)
VERIFIED: ~/.zsh.d/keybinds.zsh (command check replaced)
VERIFIED: ~/.zsh.d/functions.zsh (command check replaced)
VERIFIED: ~/.zshenv (PATH deduplication added)
```

**Commits exist:**
```
FOUND: a7be280 (feat(19-02): apply four zero-risk quick wins) - chezmoi repo
FOUND: 546fadc (chore(19-02): document post-quick-wins measurements) - dotfiles repo
```

**Performance verified:**
```
VERIFIED: hyperfine mean 283.7ms < 300ms target
VERIFIED: Improvement of 30.9ms (9.8% faster) from baseline
VERIFIED: Shell functional with all plugins working
```

---
*Phase: 19-baseline-quick-wins*
*Completed: 2026-02-14*
