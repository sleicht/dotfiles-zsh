# Feature Landscape: ZSH Startup Performance Optimisation

**Domain:** Shell startup performance (0.87s -> <300ms target)
**Researched:** 2026-02-14
**Overall confidence:** HIGH (well-documented domain with abundant community evidence)

## Table Stakes

Features that any serious ZSH performance optimisation must include. Missing any of these and the target is unlikely to be met.

| Feature | Why Expected | Estimated Savings | Complexity | Confidence |
|---------|--------------|-------------------|------------|------------|
| Eval caching for all `eval "$(tool init zsh)"` | Each eval forks a subprocess; caching replaces fork+exec with file source | 150-350ms total | Low | HIGH |
| Deferred/lazy loading for non-prompt tools | Tools not needed for first prompt block startup unnecessarily | 100-250ms total | Medium | HIGH |
| `compinit` once-daily check | `compinit` checks `.zcompdump` freshness on every startup; skip when recent | 20-50ms | Low | HIGH |
| PATH deduplication with `typeset -U` | Prevents PATH growth across nested shells, reduces lookup time | 5-10ms | Low | HIGH |

## Feature Details

### 1. Eval Caching

**Confidence:** HIGH (verified via evalcache source code, multiple community reports)

#### The Problem

Every `eval "$(tool init zsh)"` forks a subprocess, runs the tool binary, captures stdout, and evaluates it. The output is almost always static between tool version changes.

Current eval calls in the codebase:
```
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"  # 50-200ms
eval "$(mise activate zsh)"                                            # 30-80ms
eval "$(zoxide init zsh --no-cmd)"                                     # 20-40ms
eval "$(atuin init zsh)"                                               # 10-30ms
source <(carapace _carapace)                                           # 20-50ms
```

**Total eval overhead: ~130-400ms** (significant chunk of the 870ms budget)

#### Recommended Solution: Custom Eval Cache Function

Use a standalone eval cache function (no plugin manager dependency). Three options exist:

**Option A: mroth/evalcache**
- Single file, ~40 lines, no dependencies
- MD5-based cache key from command string
- Auto-zcompiles cache files
- Cache stored in `$ZSH_EVALCACHE_DIR` (default `~/.zsh-evalcache`)
- Invalidation: manual via `_evalcache_clear`
- Weakness: does NOT auto-invalidate on tool version change

**Option B: QuarticCat/zsh-smartcache**
- Auto-invalidates by running command in background and comparing output
- Updates cache silently without slowing startup
- More robust but slightly more complex

**Option C: Custom inline function (RECOMMENDED -- no external dependency)**

Write a ~25 line function that:
1. Hashes the command + tool version (`tool --version`) to create cache key
2. Stores cache in `${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval-cache/`
3. Sources cache if it exists and hash matches
4. Otherwise runs eval and saves output

```zsh
# Eval cache with version-aware invalidation
# Usage: _cached_eval <cache-name> <command...>
_cached_eval() {
  local name="$1"; shift
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/eval-cache"
  local cache_file="$cache_dir/$name.zsh"
  local hash_file="$cache_dir/$name.hash"

  # Build hash from command + tool version
  local tool_bin="$1"
  local current_hash
  current_hash="$($tool_bin --version 2>/dev/null || echo unknown)-$*"

  if [[ -s "$cache_file" ]] && [[ -s "$hash_file" ]] \
     && [[ "$(< "$hash_file")" == "$current_hash" ]]; then
    source "$cache_file"
  else
    mkdir -p "$cache_dir"
    eval "$@" > "$cache_file"
    echo "$current_hash" > "$hash_file"
    source "$cache_file"
    zcompile "$cache_file" 2>/dev/null
  fi
}
```

**Recommendation:** Use Option C (custom function). It avoids external dependencies, gives version-aware invalidation, and fits the project's self-contained philosophy. The function is ~25 lines and trivial to maintain.

#### Per-Tool Caching Strategy

| Tool | Command | Can Cache? | Invalidation Trigger | Notes |
|------|---------|-----------|---------------------|-------|
| oh-my-posh | `oh-my-posh init zsh --config ...` | YES | Binary version + config file mtime | Output is static shell functions |
| mise | `mise activate zsh` | YES | Binary version | Output is PATH manipulation + hooks |
| zoxide | `zoxide init zsh --no-cmd` | YES | Binary version | Output is shell functions |
| atuin | `atuin init zsh` | YES | Binary version | Output is keybindings + functions |
| carapace | `carapace _carapace` | YES | Binary version | Output is completion system setup |

#### oh-my-posh Cache Invalidation Refinement

oh-my-posh init output depends on both the binary version AND the config file. A more robust hash for oh-my-posh specifically:

```zsh
# For oh-my-posh, include config file mtime in the hash
local omp_config="$HOME/.config/oh-my-posh.omp.json"
local omp_hash="$(oh-my-posh --version 2>/dev/null)-$(stat -f%m "$omp_config" 2>/dev/null)"
```

---

### 2. Lazy Loading / Deferred Execution

**Confidence:** HIGH (zsh-defer is well-established, authored by romkatv of Powerlevel10k)

#### The Concept

Split shell startup into two phases:
1. **Critical path** (synchronous): Only what's needed for the first prompt to render
2. **Deferred path** (idle-time): Everything else, executed when zsh is waiting for input

#### Tool: zsh-defer

- Author: romkatv (Powerlevel10k author)
- Mechanism: queues commands, executes them one-by-one when zsh is idle
- Refreshes prompt and command line buffer after each deferred command
- Standalone plugin, no zinit/oh-my-zsh dependency
- Source: https://github.com/romkatv/zsh-defer

#### Per-Tool Lazy Loading Assessment

##### oh-my-posh init zsh (50-200ms) -- THE BIGGEST BOTTLENECK

**Can it be deferred?** PARTIALLY, with caveats.

**Problem:** oh-my-posh sets the prompt. If deferred, the user sees a bare `%` prompt until oh-my-posh loads, causing a visual glitch.

**Strategies (ranked by preference):**

1. **Eval cache only, no defer (RECOMMENDED)**
   - Cache the output of `oh-my-posh init zsh --config ...`
   - Sourcing the cached file is ~1-3ms vs 50-200ms for the eval
   - No visual glitch because prompt is set synchronously from cache
   - Invalidate when oh-my-posh version or config file changes

2. **Instant prompt + deferred full init** -- If cache alone is insufficient
   - Set a minimal PROMPT synchronously (`PROMPT='%~ > '`)
   - Defer the full oh-my-posh init
   - Prompt will "flash" from minimal to full theme
   - Acceptable if flash is <100ms, annoying if longer

3. **Do not defer** -- If visual consistency is paramount
   - Just use eval caching; the ~1-3ms source time is already fast enough

**Recommendation:** Eval caching alone should reduce oh-my-posh from 50-200ms to ~2ms. No need to defer.

##### mise activate zsh (30-80ms)

**Can it be deferred?** YES, with care.

**What breaks if deferred:**
- Tool shims (node, python, etc.) won't be on PATH until mise activates
- `cd` hook for per-directory tool versions won't fire until activation

**Strategies:**

1. **Eval cache (RECOMMENDED)** -- Reduces to ~2ms, no functional loss
2. **Shims in .zprofile + defer activate** -- Use `mise activate --shims` in `.zprofile` for immediate PATH availability, then defer full `mise activate zsh` for hook support
3. **Full defer with zsh-defer** -- Acceptable if you don't need tool binaries in the first command

**Recommendation:** Eval cache is sufficient. If further savings needed, use the shims approach.

##### carapace _carapace (20-50ms)

**Can it be deferred?** YES, safely.

**What breaks if deferred:** Tab completion won't work until carapace loads. This is invisible to the user until they press Tab.

**Strategy:** Defer with `zsh-defer`:
```zsh
zsh-defer eval '_cached_eval carapace carapace _carapace'
```

**Recommendation:** Defer. Users don't Tab-complete in the first milliseconds of a shell session.

##### zoxide init zsh (20-40ms)

**Can it be deferred?** YES, with minor caveat.

**What breaks if deferred:**
- The `z` command won't work until zoxide loads
- Directory changes before activation won't be recorded in zoxide's database

**Strategy:** Eval cache + defer:
```zsh
zsh-defer eval '_cached_eval zoxide zoxide init zsh --no-cmd'
```

**Recommendation:** Defer. The `z` command is never the first thing typed.

##### ssh-add --apple-load-keychain

**Can it be deferred?** YES, fully.

**What breaks if deferred:** SSH operations attempted before the keychain loads will fail. This is extremely unlikely in the first moments of a shell.

**Strategy:**
```zsh
zsh-defer ssh-add --apple-load-keychain &>/dev/null
```

**Alternative:** Move to a macOS LaunchAgent so it runs once at login, not per-shell. This is the better long-term solution.

**Recommendation:** Defer with zsh-defer. Consider LaunchAgent for even cleaner solution.

##### atuin init zsh (10-30ms)

**Can it be deferred?** YES, safely.

**What breaks if deferred:** History search keybindings (Ctrl-R) won't work until atuin loads. Minor -- user won't search history as their very first action.

**Strategy:**
```zsh
zsh-defer eval '_cached_eval atuin atuin init zsh'
```

**Recommendation:** Eval cache + defer. Double savings.

#### Deferred Loading Summary

| Tool | Eval Cache Savings | Defer? | Combined Strategy |
|------|--------------------|--------|-------------------|
| oh-my-posh | 50-200ms -> ~2ms | NO (visual glitch) | Cache only |
| mise | 30-80ms -> ~2ms | Optional | Cache (defer optional) |
| carapace | 20-50ms -> ~2ms | YES | Cache + defer |
| zoxide | 20-40ms -> ~2ms | YES | Cache + defer |
| ssh-add | N/A (not an eval) | YES | Defer only |
| atuin | 10-30ms -> ~2ms | YES | Cache + defer |

**Projected savings from eval caching alone: ~150-400ms**
**Additional savings from deferring: ~50-150ms (perceived startup)**

---

### 3. zcompile / .zwc Pre-compilation

**Confidence:** MEDIUM (benefits are real but modest for small files)

#### What It Does

`zcompile` compiles `.zsh` files to `.zwc` (wordcode) format. ZSH can source `.zwc` files directly, skipping the parsing step.

#### Measured Benefits

- **Large files (>1000 lines):** Noticeable speedup (~5-15ms per file)
- **Small files (<100 lines):** Negligible speedup (<1ms per file)
- **Completion dump (.zcompdump):** Worth compiling -- it's the largest sourced file

From romkatv's analysis: zcompile helps most with large completion files and plugin files. For small config snippets, the parsing overhead is already minimal.

#### Where to Apply

| File | Size | Worth Compiling? | Notes |
|------|------|-----------------|-------|
| `.zcompdump` | Large (~50-200KB) | YES | Biggest single-file win |
| Eval cache files | Small | YES (included in cache function) | Already handled |
| `zsh.d/*.zsh` | Small-Medium | MARGINAL | Only if >500 lines |
| Plugin files (zsh-syntax-highlighting, etc.) | Large | YES | But managed by plugin loader |

#### Implementation

```zsh
# Compile .zcompdump after compinit (once daily)
autoload -Uz compinit
if [[ -n "$HOME/.zcompdump"(#qN.mh+24) ]]; then
  compinit
  zcompile "$HOME/.zcompdump"
else
  compinit -C  # Skip security check, use cache
fi
```

**Recommendation:** Apply zcompile to `.zcompdump` and eval cache files. Don't bother with small config files -- the effort isn't worth the ~1ms saving per file.

---

### 4. PATH Optimisation

**Confidence:** HIGH (well-documented ZSH feature)

#### Deduplication

```zsh
# Add to .zshenv or early in .zshrc
typeset -U PATH path
typeset -U FPATH fpath
typeset -U MANPATH manpath
```

The `-U` flag ensures only the first occurrence of each value is kept. This prevents PATH bloat in nested shells (tmux, subshells, etc.).

#### Reducing PATH Entries

Each PATH entry is checked during command lookup. Fewer entries = faster lookups. However, the effect is minimal (microseconds per lookup) -- this is more about hygiene than performance.

#### Lazy PATH Additions

For tools that add to PATH only when used (e.g., language-specific bin directories), add them lazily:

```zsh
# Instead of always adding cargo bin:
# export PATH="$HOME/.cargo/bin:$PATH"

# Add on first use of cargo/rustc:
_lazy_cargo() {
  unfunction cargo rustc rustup 2>/dev/null
  export PATH="$HOME/.cargo/bin:$PATH"
  "$0" "$@"
}
alias cargo='_lazy_cargo'
alias rustc='_lazy_cargo'
alias rustup='_lazy_cargo'
```

**Recommendation:** Always use `typeset -U`. Lazy PATH additions are only worth it if you have many language toolchains that are rarely used.

---

### 5. compinit Once-Daily Check

**Confidence:** HIGH (classic optimisation, widely adopted)

```zsh
autoload -Uz compinit

# Only regenerate .zcompdump once per day
if [[ -n "$HOME/.zcompdump"(#qN.mh+24) ]]; then
  compinit
  zcompile "$HOME/.zcompdump"
else
  compinit -C
fi
```

The `(#qN.mh+24)` glob qualifier checks if the file is older than 24 hours. `-C` skips the security check and uses the cached dump directly.

**Estimated savings:** 20-50ms on subsequent startups within the same day.

---

## Differentiators

Features that go beyond basic optimisation. Not expected, but provide extra polish.

| Feature | Value Proposition | Complexity | Confidence |
|---------|-------------------|------------|------------|
| Startup time self-monitoring | Log startup time to detect regressions | Low | HIGH |
| Background cache warming | Pre-generate caches after tool updates | Medium | MEDIUM |
| Conditional loading by context | Skip dev tools in non-dev directories | Medium | LOW |

### Startup Time Self-Monitoring

```zsh
# At the very top of .zshenv:
_zsh_start_time=$EPOCHREALTIME

# At the very end of .zshrc:
_zsh_startup_time=$(( EPOCHREALTIME - _zsh_start_time ))
if (( _zsh_startup_time > 0.3 )); then
  printf '\033[33mWarning: shell startup took %.0fms (target: <300ms)\033[0m\n' \
    $(( _zsh_startup_time * 1000 ))
fi
```

---

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Async prompt (for oh-my-posh) | oh-my-posh doesn't support it; eval caching makes it unnecessary | Eval cache oh-my-posh init output |
| zinit Turbo mode | Adds plugin manager dependency; zsh-defer is lighter | Use zsh-defer standalone |
| Lazy loading every single alias/function | Overhead of wrapper functions exceeds loading cost for small files | Only lazy-load expensive inits |
| zcompile all config files | Marginal benefit for small files, adds maintenance burden | Only zcompile .zcompdump and cache files |
| Custom async framework | Over-engineering; zsh-defer already solves this | Use zsh-defer |
| Replacing oh-my-posh with starship | Starship has similar eval cost; caching solves the root cause | Cache the init output |

---

## Feature Dependencies

```
typeset -U PATH       (no dependencies, do first)
       |
eval caching function (no dependencies, define early in .zshrc)
       |
       +--- oh-my-posh cache (must be sync, before prompt renders)
       +--- mise cache (before any tool binary usage)
       +--- zoxide cache  \
       +--- atuin cache    }-- can be deferred with zsh-defer
       +--- carapace cache /
       |
zsh-defer setup (source the plugin)
       |
       +--- deferred: ssh-add keychain
       +--- deferred: carapace (cached + deferred)
       +--- deferred: zoxide (cached + deferred)
       +--- deferred: atuin (cached + deferred)
       |
compinit once-daily check (after all completion setup)
       |
zcompile .zcompdump (after compinit)
```

---

## MVP Recommendation (Phase 1 Performance)

Implement in this order for maximum impact with minimum risk:

1. **Eval caching function** -- Custom `_cached_eval` with version-aware invalidation (~25 lines)
2. **Cache oh-my-posh init** -- Biggest single win (50-200ms saved)
3. **Cache mise, zoxide, atuin, carapace** -- Collective ~80-200ms saved
4. **`typeset -U PATH`** -- One line, prevents PATH bloat
5. **compinit once-daily** -- Well-understood pattern, 20-50ms saved

**Projected result from MVP alone: ~300-500ms saved, bringing 870ms to ~370-570ms**

### Phase 2 (if MVP doesn't hit <300ms)

6. **zsh-defer for non-critical tools** -- ssh-add, carapace, zoxide, atuin
7. **zcompile .zcompdump** -- Additional ~10-20ms
8. **Startup time monitoring** -- Catch regressions

**Projected result with Phase 2: additional ~80-150ms saved, bringing total to ~220-420ms**

---

## Sources

- [mroth/evalcache](https://github.com/mroth/evalcache) -- Eval caching plugin source code (HIGH confidence)
- [QuarticCat/zsh-smartcache](https://github.com/QuarticCat/zsh-smartcache) -- Auto-invalidating eval cache (MEDIUM confidence)
- [romkatv/zsh-defer](https://github.com/romkatv/zsh-defer) -- Deferred execution plugin (HIGH confidence)
- [romkatv/zsh-bench](https://github.com/romkatv/zsh-bench) -- ZSH benchmarking tool (HIGH confidence)
- [Santacloud: Optimizing ZSH Startup to Under 70ms](http://santacloud.dev/posts/optimizing-zsh-startup-performance/) -- Real-world optimisation walkthrough (MEDIUM confidence)
- [Josh Yin: Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh) -- Community patterns (MEDIUM confidence)
- [mise activate docs](https://mise.jdx.dev/cli/activate.html) -- Official mise documentation (HIGH confidence)
- [mise shims docs](https://mise.jdx.dev/dev-tools/shims.html) -- Official shims documentation (HIGH confidence)
- [oh-my-posh lazy segments issue #6094](https://github.com/JanDeDobbeleer/oh-my-posh/issues/6094) -- Async prompt status (MEDIUM confidence)
- [oh-my-posh FAQ](https://ohmyposh.dev/docs/faq) -- Official performance guidance (HIGH confidence)
- [compinit once-daily pattern](https://gist.github.com/ctechols/ca1035271ad134841284) -- Classic optimisation gist (HIGH confidence)
- [Dave Dribin: Improving Zsh Performance](https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/) -- zcompile analysis (MEDIUM confidence)
- [Mariano Zunino: Speeding Up zsh Startup with zprof and zsh-defer](https://mzunino.com.uy/til/2025/03/speeding-up-zsh-startup-with-zprof-and-zsh-defer/) -- zsh-defer walkthrough (MEDIUM confidence)
- [black7375/zsh-lazyenv](https://github.com/black7375/zsh-lazyenv) -- Lazy loading environments (LOW confidence)
