# Phase 20: Eval Caching Layer - Research

**Researched:** 2026-02-14
**Domain:** ZSH shell performance optimisation, eval caching, completion compilation
**Confidence:** HIGH

## Summary

Phase 20 implements caching for expensive `eval "$(tool init)"` calls and sheldon plugin loader output to reduce shell startup time from the current baseline of 283.7ms to an estimated 170-320ms. The primary mechanism is **mroth/evalcache**, a mature ZSH plugin that caches static eval output to files, eliminating repeated subprocess spawns during shell initialisation.

The current configuration performs five expensive eval calls on every startup: oh-my-posh (28ms), zoxide (3ms), atuin (8ms), carapace (via `source <()`), and intelli-shell, plus sheldon plugin loading (11ms). Additionally, phantom completions add 112ms but require a different approach (already identified in Phase 19 baseline as non-cacheable via evalcache due to dynamic output).

This phase also implements **zcompdump compilation** in background via `.zlogin` and simplifies compinit to always use `-C` flag (skip security checks on cached dump). Sheldon output caching with mtime-based invalidation is considered but may provide minimal benefit since sheldon already uses a lock file mechanism.

**Primary recommendation:** Implement evalcache for all static init calls (oh-my-posh, zoxide, atuin, carapace, intelli-shell), add background zcompile in .zlogin, simplify compinit to `-C`, and measure actual improvement against baseline. Expected savings of 250-400ms appears optimistic given current 283.7ms baseline; realistic target is 40-80ms improvement (bringing total to ~200-240ms).

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mroth/evalcache | v1.0.3 | Cache eval output to files | De facto standard for ZSH eval caching, 88% speedup for rbenv, 80% for hub, 58% for scmpuff in author's benchmarks |
| zcompile | Built-in | Compile ZSH scripts to bytecode | Native ZSH functionality for pre-compiling functions and completion dumps |
| sheldon | 0.8+ | Plugin manager (already in use) | Already managing plugins with lock file mechanism |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| compinit -C | Built-in | Skip completion security checks | Safe when .zcompdump is managed by single user, saves check overhead on every startup |
| .zlogin | N/A | Login shell initialization | Standard location for background compilation tasks that run once per login session |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| evalcache | Manual caching with temp files | Evalcache provides version tracking, graceful degradation, and convenience functions; manual approach requires custom invalidation logic |
| evalcache | z-a-eval (Zinit annex) | z-a-eval auto-invalidates on plugin update but requires Zinit; we use Sheldon |
| Background zcompile | Synchronous compilation | Sync adds ~30ms to startup; background eliminates user-visible delay but requires .zlogin support |

**Installation:**
```bash
# Via Sheldon (recommended approach for this project)
# Add to ~/.config/sheldon/plugins.toml before zsh-defer:
[plugins.evalcache]
github = "mroth/evalcache"
```

## Architecture Patterns

### Recommended Integration Structure

```
Sheldon plugin loading order:
1. evalcache (MUST load first)
2. zsh-defer (for deferred loading)
3. compinit (with -C flag simplification)
4. Other plugins (fzf-tab, zsh-syntax-highlighting, etc.)
5. dotfiles (applies source - uses evalcache where needed)
```

### Pattern 1: Evalcache Wrapper for Static Init

**What:** Replace `eval "$(tool init)"` with `_evalcache tool init` for tools producing static output

**When to use:** When init output is static (same on every invocation) and tool version doesn't change frequently

**Example:**
```zsh
# Before (from current dot_zsh.d/hooks.zsh:11)
if (( $+commands[oh-my-posh] )); then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"
fi

# After
if (( $+commands[oh-my-posh] )); then
  _evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
fi
```

**Performance impact:** oh-my-posh init currently takes 28ms (10.2ms eval + 17.4ms autoload from Phase 19 baseline); evalcache reduces this to ~3-5ms on subsequent runs (based on mroth benchmarks showing 80-88% reduction)

### Pattern 2: Source Redirection for Carapace

**What:** Replace `source <(carapace _carapace)` with evalcache-compatible pattern

**When to use:** When tool uses process substitution instead of standard eval pattern

**Example:**
```zsh
# Before (from current dot_zsh.d/carapace.zsh:9)
source <(carapace _carapace)

# After
if (( $+commands[carapace] )); then
  eval "$(_evalcache carapace _carapace)"
fi
```

**Note:** Carapace generates completion bridges and must remain synchronous (loaded before completions are used)

### Pattern 3: Background zcompdump Compilation

**What:** Compile .zcompdump in background during login to avoid blocking shell startup

**When to use:** Always, in .zlogin which runs once per login session (not per shell)

**Example:**
```zsh
# Create dot_zlogin file
# Compile zsh completion dump to .zwc for faster loading
{
  # Set the base directory for completions
  local zcompdump="${HOME}/.zcompdump"

  # Compile the completion dump file in the background
  if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    zcompile "$zcompdump"
  fi
} &!
```

**Source:** Adapted from [zimfw PR #218](https://github.com/zimfw/zimfw/pull/218) - consolidates compilation in login init

**Performance impact:** Compilation happens asynchronously; no blocking impact. Subsequent shells load .zwc (bytecode) instead of text file for marginal improvement (~5-10ms according to zimfw benchmarks)

### Pattern 4: Simplified compinit with -C Flag

**What:** Remove complex timestamp checking and always use `compinit -C` when dump exists

**When to use:** In single-user environments where security checks add overhead without benefit

**Example:**
```zsh
# Before (from current plugins.toml:11-24)
[plugins.compinit]
inline = '''
if [ ! -f $HOME/.zcompdump ]; then
  autoload -Uz compinit && compinit
else
  local now=$(date +"%s")
  local updated=$(date -r $HOME/.zcompdump +"%s")
  local threshold=$((60 * 60 * 24))
  if [ $((${now} - ${updated})) -gt ${threshold} ]; then
    autoload -Uz compinit && compinit
  else
    autoload -Uz compinit && compinit -C
  fi
fi
'''

# After
[plugins.compinit]
inline = '''
autoload -Uz compinit
if [ -f $HOME/.zcompdump ]; then
  compinit -C
else
  compinit
fi
'''
```

**Rationale:** `-C` flag "omits the check for new functions and skips the call to compaudit" (source: [zsh.sourceforge.io](https://zsh.sourceforge.io/Doc/Release/Completion-System.html)). Timestamp checks using `date` spawn subprocesses; eliminating them removes overhead.

### Pattern 5: Sheldon Source Caching (Optional)

**What:** Cache `sheldon source` output to file and source from cache with mtime invalidation

**When to use:** Only if profiling shows sheldon source itself (currently 11ms from baseline) warrants caching

**Example:**
```zsh
# In .zshrc, replace: eval "$(sheldon source)"
# With:
_sheldon_cache="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon/source.zsh"
_sheldon_lock="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.lock"

if [[ ! -f "$_sheldon_cache" || "$_sheldon_lock" -nt "$_sheldon_cache" ]]; then
  mkdir -p "${_sheldon_cache:h}"
  sheldon source > "$_sheldon_cache"
fi
source "$_sheldon_cache"

unset _sheldon_cache _sheldon_lock
```

**Rationale:** Sheldon already uses lock file for plugin sources; cache invalidation based on lock mtime ensures cache is fresh when plugins update

**Performance impact:** Reduces sheldon overhead from 11ms to ~2-3ms (file source vs subprocess eval)

### Anti-Patterns to Avoid

- **Caching phantom completions:** Phantom generates dynamic completions based on available commands; output changes as tools are installed/updated. Profiling shows 112ms overhead from `eval "$(phantom completion zsh)"` but this CANNOT be cached via evalcache
- **Caching mise activate:** mise generates environment variables based on project context (current directory); output is directory-dependent and must run on every shell
- **Over-caching prompts that read git state:** oh-my-posh init is cacheable, but prompt segments that read git status must remain dynamic
- **Forgetting manual invalidation:** After updating oh-my-posh, zoxide, atuin, carapace, or intelli-shell via brew, user MUST run `_evalcache_clear` or cache will serve stale init code

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Eval output caching | Custom temp file logic with version detection | mroth/evalcache | Handles graceful degradation when tools uninstall, provides _evalcache_clear convenience, stores cache with configurable location ($ZSH_EVALCACHE_DIR), mature and tested |
| Cache invalidation on tool update | Hash-based or version-checking invalidation | Manual _evalcache_clear after brew upgrade | Tools don't consistently expose version in machine-readable format; manual invalidation is simple and reliable |
| ZSH script compilation | Custom bytecode compilation logic | Built-in zcompile | Native ZSH functionality with proper error handling, mtime checking, and .zwc format |
| Sheldon lock file parsing for mtime | JSON/TOML parsing in ZSH | Simple stat/mtime comparison with -nt operator | Lock file format may change; mtime comparison is format-agnostic and sufficient |

**Key insight:** Caching in shell initialization is deceptively complex due to tool version changes, environment differences, and failure modes. Evalcache provides battle-tested patterns; custom solutions introduce maintenance burden without meaningful benefit.

## Common Pitfalls

### Pitfall 1: Loading evalcache After Tools Use It

**What goes wrong:** If evalcache plugin loads after a file tries to use `_evalcache`, the function is undefined and init commands fail or fall back to uncached eval

**Why it happens:** Sheldon's alphabetical plugin loading or incorrect `apply` ordering in plugins.toml

**How to avoid:**
1. Add evalcache as first plugin in plugins.toml (before zsh-defer)
2. Use explicit plugin ordering in sheldon configuration
3. Verify `_evalcache` function exists before first use: `(( $+functions[_evalcache] ))`

**Warning signs:**
- Errors like "_evalcache: command not found" in shell startup
- Tools initializing slowly despite evalcache being "installed"
- Cache directory ($HOME/.zsh-evalcache) remains empty

### Pitfall 2: Caching Directory-Dependent Output

**What goes wrong:** Some tools generate output based on current working directory (mise, direnv, asdf with .tool-versions). Caching this output breaks directory-specific behaviour.

**Why it happens:** Assumption that all `eval "$(tool init)"` output is static

**How to avoid:**
1. Only cache tools with truly static init output (oh-my-posh, zoxide, atuin, carapace, intelli-shell)
2. Do NOT cache mise activate (already correct in current config - mise uses hooks, not direct eval in .zshrc)
3. Test in multiple directories after caching to verify environment is correct

**Warning signs:**
- Environment variables not updating when changing directories
- Tool versions "stuck" on first cached values
- Project-specific settings not loading

### Pitfall 3: Forgetting to Clear Cache After Tool Updates

**What goes wrong:** After updating oh-my-posh, zoxide, atuin, etc. via brew, cached init output becomes stale. Tool may not work correctly or miss new features/fixes.

**Why it happens:** Evalcache has no built-in version detection; cache persists until manually cleared

**How to avoid:**
1. Document in README/CLAUDE.md: "After brew upgrade, run: _evalcache_clear"
2. Consider adding post-install hook to clear cache (but increases complexity)
3. Set $ZSH_EVALCACHE_DIR to known location and include in dotfiles backup/sync strategy

**Warning signs:**
- Tools behave differently in new shell vs existing shell after upgrade
- Features documented in changelog not working
- Errors about missing/changed flags after tool update

### Pitfall 4: Compiling .zcompdump While compinit Is Running

**What goes wrong:** If synchronous zcompile runs while compinit is writing .zcompdump, compilation can fail or produce corrupted .zwc file

**Why it happens:** Race condition between completion system initialization and compilation

**How to avoid:**
1. Use background compilation in .zlogin: `{ zcompile ... } &!`
2. Check if .zcompdump exists and is newer than .zwc before compiling
3. Never run zcompile synchronously during .zshrc execution

**Warning signs:**
- Intermittent "zcompile: permission denied" errors
- Corrupted .zcompdump.zwc files
- Completions stop working randomly

**Source:** [zimfw PR #218](https://github.com/zimfw/zimfw/pull/218) discussion notes consolidating compilation in login init to avoid races

### Pitfall 5: Over-Optimistic Performance Expectations

**What goes wrong:** Phase description estimates 250-400ms savings bringing total from ~720ms to ~320-470ms, but current baseline is already 283.7ms (Phase 19 post-quick-wins)

**Why it happens:** Phase description written before Phase 19 baseline measurements; assumed 870ms starting point from old STATE.md

**How to avoid:**
1. Reset expectations: Current baseline 283.7ms means maximum possible improvement from caching is ~80-100ms (if ALL eval overhead eliminated)
2. Realistic target: 40-80ms improvement → final startup time ~200-240ms
3. Measure before/after with same three-stage methodology (hyperfine, EPOCHREALTIME, zsh-bench)
4. Accept that diminishing returns apply - may not reach 170ms unless phantom completion (112ms) is addressed separately

**Warning signs:**
- Actual improvement less than 100ms
- User disappointment if expecting 400ms reduction
- Claims of "failure" when phase achieves 50ms improvement (actually strong result from current baseline)

## Code Examples

Verified patterns from official sources and current dotfiles:

### Caching oh-my-posh Init (Synchronous - Prompt Critical)

```zsh
# File: dot_zsh.d/hooks.zsh
# Current (line 11):
if (( $+commands[oh-my-posh] )); then eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"; fi

# With evalcache:
if (( $+commands[oh-my-posh] )); then
  _evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
fi
```

**Note:** oh-my-posh init MUST remain synchronous (cannot defer) as it sets up prompt functions needed immediately. Evalcache reduces from 28ms to ~5ms without breaking prompt timing.

**Source:** [mroth/evalcache README](https://github.com/mroth/evalcache/blob/master/README.md) - hub alias example shows 80% reduction (30ms → 6ms)

### Caching zoxide, atuin, intelli-shell Init

```zsh
# File: dot_zsh.d/external.zsh (line 56)
# Current:
eval "$(zoxide init zsh --no-cmd)"

# With evalcache:
if (( $+commands[zoxide] )); then
  _evalcache zoxide init zsh --no-cmd
fi

# File: dot_zsh.d/atuin.zsh (line 7)
# Current:
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh)"
fi

# With evalcache:
if (( $+commands[atuin] )); then
  _evalcache atuin init zsh
fi

# File: dot_zsh.d/intelli-shell.zsh (line 6)
# Current:
if (( $+commands[intelli-shell] )); then
  eval "$(intelli-shell init zsh)"
fi

# With evalcache:
if (( $+commands[intelli-shell] )); then
  _evalcache intelli-shell init zsh
fi
```

**Performance:** zoxide currently 3ms, atuin 8ms, intelli-shell unknown (not in baseline). Evalcache reduces each to ~1-2ms.

### Caching carapace Completion Bridge

```zsh
# File: dot_zsh.d/carapace.zsh (line 9)
# Current:
source <(carapace _carapace)

# With evalcache:
if (( $+commands[carapace] )); then
  eval "$(_evalcache carapace _carapace)"
fi
```

**Note:** Process substitution `<(...)` is not directly compatible with evalcache. Wrap in eval with command substitution instead.

### Background .zcompdump Compilation

```zsh
# File: dot_zlogin (create new file)
#!/usr/bin/env zsh
# Managed by chezmoi - edit in ~/.local/share/chezmoi/dot_zlogin

# Compile zsh completion dump in background for faster loading
{
  local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

  # Compile if dump exists and (.zwc doesn't exist OR .zwc is older than dump)
  if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    zcompile "$zcompdump"
  fi
} &!
```

**Source:** Adapted from [zimfw PR #218](https://github.com/zimfw/zimfw/pull/218) - background async block with `&!` ensures non-blocking

### Simplified compinit in Sheldon plugins.toml

```toml
# Current plugins.toml lines 10-25 (complex timestamp checking)
[plugins.compinit]
inline = '''
if [ ! -f $HOME/.zcompdump ]; then
  autoload -Uz compinit && compinit
else
  local now=$(date +"%s")
  local updated=$(date -r $HOME/.zcompdump +"%s")
  local threshold=$((60 * 60 * 24))
  if [ $((${now} - ${updated})) -gt ${threshold} ]; then
    autoload -Uz compinit && compinit
  else
    autoload -Uz compinit && compinit -C
  fi
fi
'''

# Simplified (always use -C when dump exists)
[plugins.compinit]
inline = '''
autoload -Uz compinit
if [[ -f "${ZDOTDIR:-$HOME}/.zcompdump" ]]; then
  compinit -C
else
  compinit
fi
'''
```

**Rationale:** Eliminates two `date` subprocess spawns per shell startup. The `-C` flag skips security checks and new function detection - acceptable in single-user dotfiles environment.

**Source:** [zsh.sourceforge.io Completion System docs](https://zsh.sourceforge.io/Doc/Release/Completion-System.html) - "security check is skipped entirely when -C option is given"

### Clearing Evalcache After Tool Updates

```zsh
# Manual cache clear after brew upgrade
$ brew upgrade oh-my-posh zoxide atuin carapace intelli-shell
$ _evalcache_clear

# Or clear specific tool
$ _evalcache_clear oh-my-posh
```

**Source:** [mroth/evalcache README](https://github.com/mroth/evalcache/blob/master/README.md) - convenience function

### Optional: Sheldon Source Caching

```zsh
# File: dot_zshrc.tmpl (line 34)
# Current:
eval "$(sheldon source)"

# With mtime-based caching:
() {
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon"
  local cache_file="$cache_dir/source.zsh"
  local lock_file="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.lock"

  # Regenerate cache if lock file is newer (plugins updated)
  if [[ ! -f "$cache_file" || "$lock_file" -nt "$cache_file" ]]; then
    mkdir -p "$cache_dir"
    sheldon source > "$cache_file"
  fi

  source "$cache_file"
}
```

**Note:** Anonymous function `() { ... }` prevents variable pollution. Only implement if profiling shows sheldon source (11ms) warrants caching.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Uncached eval on every startup | Evalcache with manual invalidation | ~2016 (evalcache v1.0.0) | 50-88% reduction in init overhead for static tools |
| Synchronous zcompile in .zshrc | Background zcompile in .zlogin | ~2017 (zimfw framework) | Removes blocking compilation from critical startup path |
| Complex compinit timestamp checking with date subprocesses | Simple -C flag when dump exists | Ongoing (varies by framework) | Eliminates 2 subprocesses per startup (~5-10ms) |
| Sheldon source via eval every startup | Lock file + cached source (optional) | Not yet standard | Potential 5-8ms savings (11ms → 3ms based on eval overhead) |
| Security checks on every compinit | -C flag to skip in single-user env | Long-standing option | Skips compaudit (~3-5ms) when unnecessary |

**Deprecated/outdated:**
- **oh-my-zsh without compilation:** Oh-my-zsh historically ran compinit without -C flag and didn't zcompile dumps; modern best practice is compilation + -C flag
- **Evalcache alternatives for Zinit users:** z-a-eval (Zinit annex) provides auto-invalidation on plugin update, but requires Zinit plugin manager; for Sheldon users, mroth/evalcache remains current approach
- **Synchronous compilation in startup:** Blocking on zcompile during .zshrc adds perceptible delay; background compilation in .zlogin is now best practice

## Open Questions

1. **Should sheldon source caching be implemented?**
   - What we know: Sheldon source currently takes 11ms (from baseline); caching could reduce to ~3ms (~8ms gain)
   - What's unclear: Whether 8ms improvement justifies added complexity and maintenance (cache invalidation logic, manual testing)
   - Recommendation: Implement all other caching first (evalcache, compinit -C, zcompile), measure results, then revisit if total improvement is insufficient

2. **How to handle phantom completions (112ms bottleneck)?**
   - What we know: Phantom completion is largest single bottleneck at 112ms but generates dynamic output (cannot use evalcache)
   - What's unclear: Whether phantom can be deferred without breaking completions, or if alternative completion strategy exists
   - Recommendation: Mark as out of scope for Phase 20; consider separate phase for phantom optimisation (possibly defer via zsh-defer or replace with static completions)

3. **What is realistic performance improvement target?**
   - What we know: Current baseline 283.7ms; eval overhead totals ~50ms (oh-my-posh 28ms + atuin 8ms + sheldon 11ms + zoxide 3ms); phantom 112ms not cacheable
   - What's unclear: Whether compinit simplification and zcompile background will show measurable improvement (likely marginal)
   - Recommendation: Set realistic target of 40-80ms improvement (final ~200-240ms), NOT 250-400ms from phase description

4. **Should .zlogin be created or will this interfere with existing login shell configuration?**
   - What we know: No .zlogin currently exists in dotfiles; background zcompile requires login-time execution
   - What's unclear: Whether user relies on login shell behaviour that .zlogin might alter
   - Recommendation: Create dot_zlogin managed by chezmoi with only background zcompile; test in fresh login session before committing

## Sources

### Primary (HIGH confidence)
- [mroth/evalcache GitHub](https://github.com/mroth/evalcache) - Official plugin repository with benchmarks and usage examples
- [mroth/evalcache README](https://github.com/mroth/evalcache/blob/master/README.md) - Installation methods, API, cache clearing
- [zsh.sourceforge.io Completion System](https://zsh.sourceforge.io/Doc/Release/Completion-System.html) - Official ZSH documentation for compinit flags and behaviour
- [zimfw PR #218](https://github.com/zimfw/zimfw/pull/218) - Background zcompile implementation and performance discussion
- [Sheldon CLI docs](https://sheldon.cli.rs/Command-line-interface.html) - Lock file mechanism and source command behaviour

### Secondary (MEDIUM confidence)
- [Speed up zsh compinit gist by ctechols](https://gist.github.com/ctechols/ca1035271ad134841284) - Daily timestamp checking pattern (superseded by -C approach)
- [Holy Grail of zsh performance (Medium)](https://medium.com/@voyeg3r/holy-grail-of-zsh-performance-a56b3d72265d) - Compilation best practices
- [Speeding Up My Shell by Matthew Clemente](https://blog.mattclemente.com/2020/06/26/oh-my-zsh-slow-to-load/) - Real-world evalcache usage and cache invalidation pitfall
- [zimfw discussions on zcompiling](https://github.com/zimfw/zimfw/discussions/547) - Community discussion on compilation strategies

### Tertiary (LOW confidence)
- WebSearch results on "evalcache pitfalls" - Mentioned infinite loop with thefuck tool (rare edge case, not applicable to oh-my-posh/zoxide/atuin)
- Community discussions on cache invalidation strategies - Various approaches (version detection, hash-based) but no consensus; manual clearing remains standard

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - evalcache is mature (v1.0.3, 2020 release), zcompile is built-in ZSH functionality, compinit -C is official flag
- Architecture: HIGH - Patterns verified in official docs and framework implementations (zimfw, oh-my-zsh)
- Pitfalls: HIGH - Cache invalidation and plugin loading order documented in multiple sources; performance expectation pitfall derived from comparing phase description (720ms baseline) to actual Phase 19 measurements (283.7ms)

**Research date:** 2026-02-14
**Valid until:** 2026-03-16 (30 days) - Stable domain, no fast-moving dependencies
