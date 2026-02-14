---
phase: 20-eval-caching-layer
verified: 2026-02-14T18:30:00Z
status: gaps_found
score: 10/11 must-haves verified
gaps:
  - truth: "Implementation commits exist in version control"
    status: failed
    reason: "Code changes applied to chezmoi source but never committed to git"
    artifacts:
      - path: "chezmoi source files"
        issue: "Modified but not tracked in dotfiles-zsh repository"
    missing:
      - "Commit implementation changes to version control"
      - "Verify commits 383cc9d, a560d83, 9f72172 exist or create new commits"
  - truth: "PERF-03: chezmoi run_onchange_ hook exists to clear eval caches on tool version change"
    status: failed
    reason: "No run_onchange_ script found in chezmoi source"
    artifacts:
      - path: "run_onchange_*"
        issue: "Missing cache invalidation automation"
    missing:
      - "Create chezmoi run_onchange_ hook to detect tool version changes"
      - "Hook should clear ~/.zsh-evalcache/ when oh-my-posh, zoxide, atuin, carapace, or intelli-shell versions change"
---

# Phase 20: Eval Caching Layer Verification Report

**Phase Goal:** Cache all expensive `eval "$(tool init)"` calls and sheldon output.
**Verified:** 2026-02-14T18:30:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | evalcache function (_evalcache) is available to all zsh.d source files | ✓ VERIFIED | Plugin loads first in plugins.toml (line 4-5) |
| 2 | compinit uses -C flag when .zcompdump exists (no date subprocess spawns) | ✓ VERIFIED | plugins.toml lines 14-21, conditional `-C` flag |
| 3 | .zlogin compiles .zcompdump in background without blocking shell | ✓ VERIFIED | dot_zlogin lines 5-11, uses `&!` for async |
| 4 | sheldon source output is cached to file with mtime-based invalidation | ✓ VERIFIED | dot_zshrc.tmpl lines 34-45, anonymous function pattern |
| 5 | oh-my-posh init is cached via evalcache (sync, prompt-critical) | ✓ VERIFIED | hooks.zsh lines 11-13, `_evalcache oh-my-posh` |
| 6 | zoxide init is cached via evalcache | ✓ VERIFIED | external.zsh lines 56-58, `_evalcache zoxide` |
| 7 | atuin init is cached via evalcache | ✓ VERIFIED | atuin.zsh line 7, `_evalcache atuin` |
| 8 | carapace init is cached via evalcache | ✓ VERIFIED | carapace.zsh line 9, `_evalcache carapace` |
| 9 | intelli-shell init is cached via evalcache | ✓ VERIFIED | intelli-shell.zsh line 6, `_evalcache intelli-shell` |
| 10 | Shell startup time improved by 40-80ms from 283.7ms baseline | ✓ VERIFIED | 152.5ms improvement (53.8%), exceeds target |
| 11 | Implementation commits exist in version control | ✗ FAILED | Commits 383cc9d, a560d83, 9f72172 not found in git history |

**Score:** 10/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `private_dot_config/sheldon/plugins.toml` | evalcache plugin loaded before zsh-defer, simplified compinit | ✓ VERIFIED | Lines 4-5: evalcache added; Lines 14-21: compinit simplified with -C flag |
| `dot_zshrc.tmpl` | sheldon source caching with lock file invalidation | ✓ VERIFIED | Lines 34-45: Anonymous function, mtime check against plugins.lock |
| `dot_zlogin` | background zcompdump compilation | ✓ VERIFIED | Lines 5-11: Background compilation with `&!` |
| `dot_zsh.d/hooks.zsh` | Cached oh-my-posh init | ✓ VERIFIED | Lines 11-13: `_evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json` |
| `dot_zsh.d/external.zsh` | Cached zoxide init | ✓ VERIFIED | Lines 56-58: `_evalcache zoxide init zsh --no-cmd` with command guard |
| `dot_zsh.d/atuin.zsh` | Cached atuin init | ✓ VERIFIED | Line 7: `_evalcache atuin init zsh` |
| `dot_zsh.d/carapace.zsh` | Cached carapace init | ✓ VERIFIED | Line 9: `_evalcache carapace _carapace` |
| `dot_zsh.d/intelli-shell.zsh` | Cached intelli-shell init | ✓ VERIFIED | Line 6: `_evalcache intelli-shell init zsh` |
| `post-caching-results.txt` | Performance measurements | ✓ VERIFIED | 101 lines, documents 131.2ms mean (152.5ms improvement) |
| Git commits | Implementation commits | ✗ FAILED | Claimed commits not in repository |
| `run_onchange_*` | Cache invalidation hook | ✗ MISSING | PERF-03 requirement not implemented |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| plugins.toml | dot_zsh.d/*.zsh | evalcache loaded first | ✓ WIRED | evalcache at line 4-5, dotfiles group at line 58-61 |
| hooks.zsh | _evalcache function | Plugin load order | ✓ WIRED | `_evalcache oh-my-posh` at line 12 |
| external.zsh | _evalcache function | Plugin load order | ✓ WIRED | `_evalcache zoxide` at line 57 |
| atuin.zsh | _evalcache function | Plugin load order | ✓ WIRED | `_evalcache atuin` at line 7 |
| carapace.zsh | _evalcache function | Plugin load order | ✓ WIRED | `_evalcache carapace` at line 9 |
| intelli-shell.zsh | _evalcache function | Plugin load order | ✓ WIRED | `_evalcache intelli-shell` at line 6 |
| external.zsh | mise activate | Intentionally NOT cached | ✓ VERIFIED | Line 67: `eval "$(mise activate zsh)"` unchanged |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| CACHE-01: Add evalcache plugin before zsh-defer | ✓ SATISFIED | — |
| CACHE-02: Cache oh-my-posh init (sync) | ✓ SATISFIED | — |
| CACHE-03: Cache zoxide, atuin, carapace, intelli-shell | ✓ SATISFIED | — |
| CACHE-04: Cache sheldon source with mtime invalidation | ✓ SATISFIED | — |
| CACHE-05: zcompile .zcompdump in background | ✓ SATISFIED | — |
| CACHE-06: Simplify compinit to use -C flag | ✓ SATISFIED | — |
| PERF-03: chezmoi run_onchange_ hook for cache invalidation | ✗ BLOCKED | Hook not implemented |
| PERF-04: All functionality preserved | ✓ SATISFIED | All tools functional per SUMMARY |

### Anti-Patterns Found

None detected. All files scanned for:
- TODO/FIXME/PLACEHOLDER comments: None found
- Empty implementations: None found
- Console.log-only handlers: N/A (shell scripts)
- Stub patterns: None found

### Human Verification Required

#### 1. Verify Shell Startup Performance

**Test:** Open a new shell and measure startup time with hyperfine
```bash
hyperfine --warmup 3 --runs 10 'zsh -i -c exit'
```

**Expected:** Mean time around 131.2ms (±2-3ms), consistent with documented results

**Why human:** Performance measurement requires live shell execution, cannot verify from static files

#### 2. Verify All Tools Functional

**Test:** 
1. Open new shell, confirm oh-my-posh prompt renders
2. Test zoxide: `z /tmp && pwd && cd -`
3. Test atuin: Press `Ctrl+R` and confirm history search appears
4. Test completions: `git <TAB>` shows carapace-bridged completions
5. Verify mise works: `cd` to project with `.mise.toml`, confirm tools activate

**Expected:** All tools work exactly as before caching

**Why human:** Interactive tool behaviour requires live shell session

#### 3. Verify Cache Invalidation

**Test:**
1. Check cache exists: `ls ~/.zsh-evalcache/`
2. Clear cache: `rm -rf ~/.zsh-evalcache/`
3. Open new shell (should regenerate cache)
4. Check cache regenerated: `ls ~/.zsh-evalcache/` shows .sh and .zwc files

**Expected:** Cache regenerates automatically when missing

**Why human:** Cache invalidation behaviour requires live shell execution

#### 4. Verify Sheldon Cache Behaviour

**Test:**
1. Check cache: `ls ~/.cache/sheldon/source.zsh`
2. Note mtime: `stat -f %Sm ~/.cache/sheldon/source.zsh`
3. Touch lock file: `touch ~/.config/sheldon/plugins.lock`
4. Open new shell
5. Verify cache regenerated: `stat -f %Sm ~/.cache/sheldon/source.zsh` should be newer

**Expected:** Cache regenerates when plugins.lock is newer

**Why human:** Timestamp-based invalidation requires live filesystem operations

### Gaps Summary

**Gap 1: Missing Implementation Commits**

The SUMMARY files claim commits `383cc9d`, `a560d83`, and `9f72172` for the actual code changes, but these commits do not exist in the git repository. The implementation work was done in the chezmoi managed files (`~/.local/share/chezmoi/`) but never committed to version control.

**Impact:** Documentation-code mismatch, no historical record of when changes were made, difficult to track what changed and when.

**Resolution needed:**
- Determine if chezmoi source is tracked in a different repository
- If not tracked, add implementation commits to dotfiles-zsh repository
- Update SUMMARY files with correct commit hashes

**Gap 2: Missing Cache Invalidation Hook (PERF-03)**

Requirement PERF-03 specifies: "Add chezmoi run_onchange_ hook to clear eval caches on tool version change." No such hook exists in the chezmoi source directory.

**Impact:** When tool versions change (e.g., `brew upgrade oh-my-posh`), cached output may become stale or incompatible, requiring manual cache clearing.

**Resolution needed:**
- Create `run_onchange_clear-evalcache.sh.tmpl` in chezmoi source
- Detect version changes for oh-my-posh, zoxide, atuin, carapace, intelli-shell
- Clear `~/.zsh-evalcache/` when versions change
- Template should generate a hash of tool versions to trigger on change

---

_Verified: 2026-02-14T18:30:00Z_
_Verifier: Claude (gsd-verifier)_
