# Phase 22: Monitoring & Hardening - Research

**Researched:** 2026-02-14
**Domain:** ZSH shell startup monitoring, regression prevention, smoke testing
**Confidence:** MEDIUM-HIGH

## Summary

Phase 22 focuses on preventing performance regressions and ensuring long-term maintainability of the optimised shell configuration through automated monitoring, validation, and cache invalidation mechanisms.

The phase requires implementing three monitoring/validation layers:
1. **Self-monitoring** - Startup time tracking that warns if > 300ms threshold exceeded
2. **Smoke testing** - Automated validation script verifying shell functionality remains intact
3. **Cache invalidation** - chezmoi hook to clear evalcache when tool versions change

Research reveals that ZSH provides native timing mechanisms (EPOCHREALTIME, zprof) suitable for self-monitoring. The evalcache plugin already exists and supports manual cache clearing. chezmoi's run_onchange_ scripts can detect tool version changes via checksum embedding. Smoke testing requires a custom validation script as no shell-specific smoke test framework exists for this use case.

**Primary recommendation:** Use EPOCHREALTIME-based timing wrapper in .zshrc to measure startup and emit warnings. Create purpose-built smoke test script validating critical functionality. Implement run_onchange_ hook tracking tool version hashes to trigger evalcache clearing.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| zsh/datetime | builtin | EPOCHREALTIME timing | Native ZSH module, zero overhead, microsecond precision |
| zprof | builtin | Function profiling | Native ZSH profiler, community standard for bottleneck analysis |
| evalcache | current (mroth) | Eval caching | Already integrated in Phase 20, provides _evalcache_clear function |
| hyperfine | 1.x+ | External benchmarking | Already installed (Homebrew), used in Phase 19/20/21 baselines |
| zsh-bench | git clone | Interactive latency | Already cloned to ~/zsh-bench, used in Phase 19/20/21 for first_prompt_lag_ms |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| chezmoi run_onchange_ | builtin | Trigger on content change | Cache invalidation when tool versions change |
| chezmoi templates | builtin | Embed version checksums | Track tool version state in run_onchange_ scripts |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| EPOCHREALTIME | `date +%s%N` | External process spawn adds overhead, defeats purpose |
| Custom smoke test | ShellSpec/ZUnit frameworks | Heavyweight for simple validation, adds dependencies |
| run_onchange_ hooks | run_once_ scripts | Won't re-run when versions change, defeats purpose |
| evalcache manual clear | zsh-smartcache auto-update | Not already integrated, requires plugin migration |

**Installation:**

Already installed - no new dependencies required. All tools either built into ZSH or already integrated in previous phases.

## Architecture Patterns

### Pattern 1: EPOCHREALTIME Self-Monitoring

**What:** Track shell startup time and warn if threshold exceeded

**When to use:** In .zshrc after all configuration loaded, before interactive prompt

**Implementation approach:**
1. Store start time early in .zshenv: `ZSHRC_START_TIME=$EPOCHREALTIME`
2. Calculate elapsed time at end of .zshrc: `ZSHRC_ELAPSED=$(( (EPOCHREALTIME - ZSHRC_START_TIME) * 1000 ))`
3. Conditionally warn if > threshold: `if (( ZSHRC_ELAPSED > 300 )); then print -P "%F{yellow}⚠️  Shell startup took ${ZSHRC_ELAPSED}ms (> 300ms target)%f"; fi`

**Example:**
```zsh
# In ~/.zshenv (EARLY - before any slow operations)
ZSHRC_START_TIME=$EPOCHREALTIME

# In ~/.zshrc (LATE - after sheldon, all inits, etc.)
if [[ -n "$ZSHRC_START_TIME" ]]; then
  ZSHRC_ELAPSED=$(( (EPOCHREALTIME - ZSHRC_START_TIME) * 1000 ))

  if (( ZSHRC_ELAPSED > 300 )); then
    print -P "%F{yellow}⚠️  Shell startup: ${ZSHRC_ELAPSED%.??}ms (exceeds 300ms target)%f"
  fi

  # Optional: Store for inspection
  export LAST_SHELL_STARTUP_MS=${ZSHRC_ELAPSED%.??}
fi
```

**Source:** [EPOCHREALTIME ZSH documentation](https://www.bashsupport.com/zsh/variables/epochrealtime/), [zsh profiling with EPOCHREALTIME](https://esham.io/2018/02/zsh-profiling)

**Confidence:** HIGH - EPOCHREALTIME is native, well-documented, widely used for this pattern

### Pattern 2: zprof Conditional Profiling

**What:** Enable detailed profiling via environment variable for diagnosis

**When to use:** Diagnostic mode when startup time warning appears

**Implementation:**
```zsh
# In ~/.zshrc (EARLY)
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
  zmodload zsh/zprof
fi

# In ~/.zshrc (LATE)
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
  zprof
fi
```

**Usage:** `ZSH_PROFILE_STARTUP=1 zsh -i -c exit` to see detailed profile

**Source:** [BigBinary zprof profiling guide](https://www.bigbinary.com/blog/zsh-profiling), [Mike Kasberg zprof optimisation](https://www.mikekasberg.com/blog/2025/05/29/optimizing-zsh-init-with-zprof.html)

**Confidence:** HIGH - Standard community practice since 2018+

### Pattern 3: Custom Smoke Test Script

**What:** Executable script validating core shell functionality

**When to use:** After chezmoi apply, after major config changes, in CI/CD if desired

**Validation checklist:**
- Prompt styled (oh-my-posh renders)
- Tools on PATH (mise shims available)
- No double-loads (check for duplicate plugin sourcing via debug)
- Completions work (compinit ran, _cache exists)
- Key bindings functional (Ctrl+R for atuin, etc.)
- Deferred plugins loaded (check $ZSH_DEFER_LOADED or equivalent)

**Implementation approach:**
```bash
#!/usr/bin/env zsh
# smoke-test.sh - Validate shell configuration

set -e
FAILED=0

print_test() { print -P "%F{blue}[TEST]%f $1" }
print_pass() { print -P "%F{green}✓%f $1" }
print_fail() { print -P "%F{red}✗%f $1"; FAILED=$((FAILED + 1)) }

# Test: oh-my-posh available and prompt renders
print_test "Checking oh-my-posh prompt..."
if (( $+commands[oh-my-posh] )) && [[ -n "$PROMPT" ]]; then
  print_pass "Prompt configured"
else
  print_fail "Prompt not configured"
fi

# Test: mise shims on PATH
print_test "Checking mise shims..."
if [[ "$PATH" == *".local/share/mise/shims"* ]]; then
  print_pass "mise shims on PATH"
else
  print_fail "mise shims NOT on PATH"
fi

# Test: compinit ran (completion system initialised)
print_test "Checking completion system..."
if (( $+_cache )); then
  print_pass "Completion system initialised"
else
  print_fail "Completion system NOT initialised"
fi

# Test: key bindings work
print_test "Checking key bindings..."
if bindkey | grep -q 'atuin'; then
  print_pass "Atuin keybindings configured"
else
  print_fail "Atuin keybindings NOT configured"
fi

# Test: tools available
print_test "Checking tool availability..."
TOOLS=(git zoxide fzf bat lsd)
for tool in $TOOLS; do
  if (( $+commands[$tool] )); then
    print_pass "$tool available"
  else
    print_fail "$tool NOT available"
  fi
done

# Summary
print ""
if (( FAILED > 0 )); then
  print -P "%F{red}FAILED: $FAILED checks failed%f"
  exit 1
else
  print -P "%F{green}PASSED: All checks passed%f"
  exit 0
fi
```

**Source:** General smoke testing principles from [BrowserStack smoke testing guide](https://www.browserstack.com/guide/smoke-testing), adapted for shell environment

**Confidence:** MEDIUM - No existing shell smoke test standard, custom approach based on general QA principles

### Pattern 4: chezmoi run_onchange_ Cache Invalidation

**What:** Trigger evalcache clear when tool versions change

**When to use:** Automatically via chezmoi apply whenever tracked tool versions change

**Implementation:**
```bash
#!/bin/bash
# run_onchange_after_clear-evalcache.sh.tmpl
# Tool version hashes - change triggers evalcache clear
# oh-my-posh: {{ output "oh-my-posh" "--version" | sha256sum }}
# zoxide: {{ output "zoxide" "--version" | sha256sum }}
# atuin: {{ output "atuin" "--version" | sha256sum }}
# carapace: {{ output "carapace" "--version" | sha256sum }}
# mise: {{ output "mise" "--version" | sha256sum }}

set -eufo pipefail

echo "==> Tool versions changed, clearing evalcache..."
zsh -c '_evalcache_clear' 2>/dev/null || true
rm -rf ~/.zsh-evalcache 2>/dev/null || true
echo "==> evalcache cleared"
```

**How it works:**
1. Template embeds checksums of tool version outputs
2. If any tool version changes, checksum changes
3. Script content changes, triggering run_onchange_
4. Script clears evalcache, forcing regeneration with new tool output

**Source:** [chezmoi run_onchange_ documentation](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/), [chezmoi FAQ on cache clearing](https://github.com/twpayne/chezmoi/discussions/1678)

**Confidence:** HIGH - chezmoi native pattern, well-documented

### Anti-Patterns to Avoid

- **Timing every individual source/eval** - Too verbose, defeats purpose of monitoring (just use zprof on-demand)
- **Blocking shell start on slow startup** - Warning is sufficient, blocking creates bad UX
- **Smoke test on every shell start** - Adds overhead, defeats optimisation work
- **Hard-coding tool paths in smoke test** - Use `(( $+commands[tool] ))` for portability
- **Forgetting to unset timing variables** - Cleanup ZSHRC_START_TIME after calculating to avoid pollution

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Microsecond timing | Custom date/gdate wrappers | EPOCHREALTIME | Native, zero overhead, microsecond precision |
| Function profiling | Manual timing of each function | zprof module | Comprehensive, automatic call tree, native |
| Cache detection | Parse evalcache internals | _evalcache_clear function | Plugin provides API, internals may change |
| Tool version detection | Parse --version manually | `{{ output "tool" "--version" \| sha256sum }}` | chezmoi template handles execution and hashing |
| Completion testing | Mock completion functions | Test `$+_cache` existence | Lightweight, sufficient for smoke test |

**Key insight:** ZSH provides robust native timing and profiling. Don't spawn external processes for timing—that adds the very overhead you're measuring. chezmoi templates already handle command execution and hashing for version tracking.

## Common Pitfalls

### Pitfall 1: Timing Measurements Add Overhead

**What goes wrong:** Adding EPOCHREALTIME measurements and conditional checks in tight loops adds measurable overhead

**Why it happens:** Arithmetic expansion and conditionals aren't free, especially repeated

**How to avoid:**
- Measure only at coarse boundaries (start of .zshenv, end of .zshrc)
- Don't measure individual plugin loads—use zprof for that (on-demand)
- Unset timing variables after use to avoid repeated checks

**Warning signs:** Startup time increases after adding monitoring

### Pitfall 2: Smoke Test Checks Too Much

**What goes wrong:** Comprehensive validation script takes 5+ seconds, defeats purpose

**Why it happens:** Checking every alias, every completion, every plugin feature

**How to avoid:** Test only **critical functionality**:
- Prompt renders (oh-my-posh)
- PATH set correctly (mise shims)
- Completion system initialised (compinit ran)
- One key binding works (Ctrl+R → atuin)
- 3-5 critical tools available

**Warning signs:** Smoke test takes > 2 seconds

### Pitfall 3: evalcache Cleared But Not Regenerated

**What goes wrong:** After clearing evalcache, shell startup is SLOWER until cache regenerates

**Why it happens:** Clearing is immediate, regeneration happens on next shell start

**How to avoid:**
- Document that first shell after `chezmoi apply` will be slower (cache rebuild)
- Consider regenerating cache in the hook itself: `zsh -i -c 'echo "Cache regenerated"' > /dev/null 2>&1`
- Trade-off: Adds time to chezmoi apply but avoids slow next shell

**Warning signs:** User reports slow shell after chezmoi apply

### Pitfall 4: Tracking Wrong Tools in run_onchange_

**What goes wrong:** Tracking tools NOT cached by evalcache (e.g., mise) causes unnecessary cache clears

**Why it happens:** Unclear which tools use evalcache vs direct execution

**How to avoid:**
- Track ONLY tools cached via evalcache: oh-my-posh, zoxide, atuin, carapace, intelli-shell (from Phase 20-02)
- DO NOT track mise (not cached per CACHE-04 decision—directory-dependent)
- DO NOT track fzf, sheldon (not using evalcache)

**Warning signs:** evalcache cleared frequently but startup time unchanged

### Pitfall 5: Measuring Total Time vs Perceived Time

**What goes wrong:** Monitoring total time (hyperfine) when perceived time (zsh-bench first_prompt_lag_ms) is what matters

**Why it happens:** Total time includes deferred work that doesn't affect UX

**How to avoid:**
- Phase 21 achieved 128.7ms total, ~70ms perceived
- Monitor perceived time (prompt appearance), not total time
- Self-monitoring should track time until prompt ready, not until all deferred work completes
- Use EPOCHREALTIME measured up to when prompt is set, not end of .zshrc

**Warning signs:** Warning fires even though prompt appears instantly

## Code Examples

### Example 1: Complete Self-Monitoring Setup

```zsh
# In ~/.zshenv (MUST be early, before any sourcing)
# Load datetime module for EPOCHREALTIME
zmodload zsh/datetime
ZSHRC_START_TIME=$EPOCHREALTIME

# In ~/.zshrc (LATE, after all sourcing/evals)
# Self-monitoring: warn if startup exceeds 300ms
if [[ -n "$ZSHRC_START_TIME" ]]; then
  typeset -F ZSHRC_ELAPSED
  ZSHRC_ELAPSED=$(( (EPOCHREALTIME - ZSHRC_START_TIME) * 1000 ))

  # Store for inspection (integer milliseconds)
  export LAST_SHELL_STARTUP_MS=${ZSHRC_ELAPSED%.??}

  # Warn if threshold exceeded
  if (( ${ZSHRC_ELAPSED%.??} > 300 )); then
    print -P "%F{yellow}⚠️  Shell startup: ${LAST_SHELL_STARTUP_MS}ms (exceeds 300ms target)%f"
    print -P "%F{yellow}   Run 'ZSH_PROFILE_STARTUP=1 zsh -i -c exit' to profile%f"
  fi

  # Cleanup
  unset ZSHRC_START_TIME ZSHRC_ELAPSED
fi
```

Source: Adapted from [EPOCHREALTIME profiling patterns](https://gist.github.com/elalemanyo/cb3395af64ac23df2e0c3ded8bd63b2f)

### Example 2: Conditional zprof for Diagnostics

```zsh
# In ~/.zshrc (VERY EARLY, before any plugins/sourcing)
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
  zmodload zsh/zprof
fi

# ... all configuration ...

# In ~/.zshrc (VERY LATE, after all configuration)
if [[ -n "$ZSH_PROFILE_STARTUP" ]]; then
  zprof | head -20
fi
```

Usage:
```bash
# Trigger profiling
ZSH_PROFILE_STARTUP=1 zsh -i -c exit

# Output shows function call counts, time per call, total time
```

Source: [BigBinary zprof guide](https://www.bigbinary.com/blog/zsh-profiling)

### Example 3: Smoke Test Script (Minimal Version)

```bash
#!/usr/bin/env zsh
# ~/.local/bin/zsh-smoke-test
# Validates critical shell functionality

set -e
typeset -i FAILED=0

test_item() {
  local name=$1
  local test_cmd=$2

  print -n "Testing $name... "
  if eval "$test_cmd" &>/dev/null; then
    print "✓"
  else
    print "✗"
    FAILED=$((FAILED + 1))
  fi
}

# Critical functionality checks
test_item "oh-my-posh available" "(( \$+commands[oh-my-posh] ))"
test_item "Prompt configured" "[[ -n \$PROMPT ]]"
test_item "mise shims on PATH" "[[ \$PATH == *mise/shims* ]]"
test_item "Completion system" "(( \$+_comps ))"
test_item "zoxide available" "(( \$+commands[zoxide] ))"
test_item "fzf available" "(( \$+commands[fzf] ))"
test_item "Atuin keybinding" "bindkey | grep -q atuin"

# No double-loads check (Phase 22 requirement)
test_item "No double plugin loads" "! grep -r 'source.*zsh-autosuggestions' ~/.zsh.d/"

# Summary
print ""
if (( FAILED > 0 )); then
  print -P "%F{red}FAILED: $FAILED checks%f"
  exit 1
else
  print -P "%F{green}PASSED: All checks OK%f"
  exit 0
fi
```

Source: Custom implementation based on [smoke testing principles](https://www.browserstack.com/guide/smoke-testing)

### Example 4: chezmoi Cache Invalidation Hook

```bash
#!/bin/bash
# ~/.local/share/chezmoi/run_onchange_after_clear-evalcache.sh.tmpl
# Clears evalcache when tool versions change

{{- if eq .chezmoi.os "darwin" }}
# Tool version checksums (Phase 20 evalcache tools only)
# oh-my-posh: {{ output "oh-my-posh" "--version" | trim | sha256sum }}
# zoxide: {{ output "zoxide" "--version" | trim | sha256sum }}
# atuin: {{ output "atuin" "--version" | trim | sha256sum }}
# carapace: {{ output "carapace" "--version" | trim | sha256sum }}
# intelli-shell: {{ output "intelli-shell" "--version" 2>&1 | trim | sha256sum }}
{{- end }}

set -eufo pipefail

echo "==> Tool version changed, clearing evalcache..."

# Method 1: Use evalcache plugin function (preferred)
if command -v zsh &>/dev/null; then
  zsh -i -c '_evalcache_clear 2>/dev/null || true'
fi

# Method 2: Direct cache removal (fallback)
rm -rf ~/.zsh-evalcache 2>/dev/null || true

echo "==> Evalcache cleared. Next shell startup will regenerate cache."
```

Source: [chezmoi scripts documentation](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual timing with `date` | EPOCHREALTIME native variable | ZSH 5.0+ (2013) | Microsecond precision, zero subprocess overhead |
| Always-on profiling | Conditional zprof via env var | Community practice ~2018 | No overhead unless diagnosing |
| Manual cache clearing | chezmoi run_onchange_ triggers | chezmoi 2.x (2020+) | Automatic invalidation on version change |
| hyperfine total time | zsh-bench perceived time | zsh-bench release (2021) | Measures UX-relevant latency (first prompt, input lag) |
| evalcache manual mgmt | Template-driven cache clear | Pattern emerged 2023+ | Automatic detection of version mismatches |

**Deprecated/outdated:**
- **`date +%s%N` for timing**: Use EPOCHREALTIME instead (native, no subprocess)
- **Permanent zprof instrumentation**: Use conditional via ZSH_PROFILE_STARTUP env var
- **ShellSpec/ZUnit for simple smoke tests**: Heavyweight for basic validation, adds dependencies

## Open Questions

1. **Should smoke test be run automatically on chezmoi apply?**
   - What we know: Can add as run_after_ script in chezmoi
   - What's unclear: Does this slow down chezmoi apply too much? Is manual execution better?
   - Recommendation: Start with manual execution (`zsh-smoke-test` command), add to chezmoi later if desired

2. **Should monitoring differentiate between first-time (cache regeneration) and normal startup?**
   - What we know: First startup after cache clear is slower (expected)
   - What's unclear: Does warning on first startup create confusion?
   - Recommendation: Accept slower first startup, document in smoke test or hook output

3. **What's the appropriate warning threshold: 300ms total or 300ms perceived?**
   - What we know: Phase 21 achieved 128.7ms total, ~70ms perceived
   - What's unclear: Phase requirement says "300ms wall-clock" but optimisation targeted perceived time
   - Recommendation: Use 300ms total (conservative), clarify in implementation that perceived time is much lower

4. **Should the run_onchange_ hook regenerate cache or just clear it?**
   - What we know: Clearing is fast, regeneration requires starting a shell
   - What's unclear: User UX trade-off (slow chezmoi apply vs slow next shell)
   - Recommendation: Clear only (fast), document expected slow first shell in output message

## Sources

### Primary (HIGH confidence)

- [ZSH EPOCHREALTIME documentation](https://www.bashsupport.com/zsh/variables/epochrealtime/) - Variable specification
- [Benjamin Esham: How to profile your zsh startup time](https://esham.io/2018/02/zsh-profiling) - EPOCHREALTIME profiling pattern
- [chezmoi: Use scripts to perform actions](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) - run_onchange_ official docs
- [mroth/evalcache GitHub README](https://github.com/mroth/evalcache) - Cache clearing API
- [romkatv/zsh-bench GitHub](https://github.com/romkatv/zsh-bench) - Metrics and measurement approach

### Secondary (MEDIUM confidence)

- [BigBinary: Profiling your zsh setup with zprof](https://www.bigbinary.com/blog/zsh-profiling) - zprof conditional pattern
- [Mike Kasberg: Optimizing Zsh Init with ZProf](https://www.mikekasberg.com/blog/2025/05/29/optimizing-zsh-init-with-zprof.html) - 2025 profiling practices
- [BrowserStack: Smoke Testing guide](https://www.browserstack.com/guide/smoke-testing) - General smoke test principles
- [chezmoi discussions: Clear run_once_ cache](https://github.com/twpayne/chezmoi/discussions/1678) - Cache invalidation patterns
- [ZSH profiling gist by elalemanyo](https://gist.github.com/elalemanyo/cb3395af64ac23df2e0c3ded8bd63b2f) - Community profiling patterns

### Tertiary (LOW confidence, marked for validation)

- [Z-Shell benchmarking guide](https://wiki.zshell.dev/docs/guides/benchmark) - Plugin manager benchmarking (may not apply to this setup)
- [DarkPhilosophy/zsh-bench](https://github.com/DarkPhilosophy/zsh-bench) - Alternative zsh-bench fork (unverified vs romkatv version)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools native or already integrated
- Architecture patterns: MEDIUM-HIGH - EPOCHREALTIME/zprof patterns well-established (HIGH), smoke test custom approach (MEDIUM), chezmoi patterns documented (HIGH)
- Pitfalls: MEDIUM - Based on community experience and logical inference, not exhaustive testing

**Research date:** 2026-02-14
**Valid until:** 2026-03-14 (30 days - stable domain, slow-moving standards)

**Key constraints:**
- No new dependencies (all tools already available)
- Must not add measurable overhead to normal shell startup
- Must be maintainable without ongoing manual intervention
- Should integrate with existing chezmoi/evalcache architecture from Phases 20-21
