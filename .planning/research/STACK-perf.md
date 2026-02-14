# Stack: ZSH Profiling and Eval Caching Tools

**Project:** ZSH dotfiles performance optimisation (0.87s -> <300ms target)
**Researched:** 2026-02-14
**Overall confidence:** HIGH

---

## 1. Profiling Tools

### Recommended: Layered approach (zprof + EPOCHREALTIME + zsh-bench + hyperfine)

Each tool answers a different question. Use all four in sequence.

### 1.1 zprof (built-in) -- Function-level bottleneck identification

| Attribute | Detail |
|-----------|--------|
| What | Built-in ZSH profiler (`zsh/zprof` module) |
| Measures | Wall-clock time per function call (not CPU time) |
| Confidence | HIGH -- built-in, universally documented |

**Usage:**
```zsh
# Add to TOP of .zshrc:
zmodload zsh/zprof

# Add to BOTTOM of .zshrc:
zprof
```

**Strengths:**
- Zero dependencies, always available
- Shows function-level call counts and cumulative time
- Good for identifying which functions dominate startup

**Limitations:**
- Only profiles function calls, NOT inline code (e.g. bare `eval` or `source` statements outside functions do not appear)
- Cannot distinguish between "time spent in this function" and "time spent in functions called by this function" without reading the "self" column carefully
- Adding zprof itself adds ~2-5ms overhead

**When to use:** First pass. Run zprof to identify which functions are slow, then use EPOCHREALTIME for inline code.

### 1.2 EPOCHREALTIME -- Line-level timing for inline code

| Attribute | Detail |
|-----------|--------|
| What | ZSH `zsh/datetime` module variable, microsecond precision |
| Measures | Wall-clock elapsed time between arbitrary points |
| Confidence | HIGH -- built-in ZSH module |

**Usage:**
```zsh
zmodload zsh/datetime

# Wrap a section:
local t0=$EPOCHREALTIME
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"
local t1=$EPOCHREALTIME
printf '%.1fms oh-my-posh init\n' $(( (t1 - t0) * 1000 ))
```

**Full startup profiler pattern:**
```zsh
# At TOP of .zshrc:
zmodload zsh/datetime
typeset -g __zshrc_start=$EPOCHREALTIME
typeset -g __t=$EPOCHREALTIME
__ts() {
  local now=$EPOCHREALTIME
  printf '%6.1fms (+%5.1fms) %s\n' \
    $(( (now - __zshrc_start) * 1000 )) \
    $(( (now - __t) * 1000 )) \
    "$1"
  __t=$now
}

# Before each section:
__ts "before sheldon"
eval "$(sheldon source)"
__ts "after sheldon"

# etc.
```

Run 5 times, take the median of each section.

**IMPORTANT -- macOS caveat:** `date +%s%N` does NOT work on macOS (BSD date lacks `%N`). Use `$EPOCHREALTIME` instead. If you need GNU date, install coreutils and use `gdate +%s%N`, but `$EPOCHREALTIME` is simpler and faster (no fork).

**When to use:** Second pass. After zprof identifies slow areas, wrap specific sections with EPOCHREALTIME to pinpoint inline `eval` and `source` statements.

### 1.3 zsh-bench (romkatv) -- User-experience latency measurement

| Attribute | Detail |
|-----------|--------|
| What | Benchmark tool that measures real interactive shell latency via virtual TTY |
| Measures | First prompt lag, first command lag, command lag, input lag |
| Confidence | HIGH -- authored by powerlevel10k maintainer, adopted as standard by zcomet |
| Source | [github.com/romkatv/zsh-bench](https://github.com/romkatv/zsh-bench) |

**Usage:**
```bash
git clone https://github.com/romkatv/zsh-bench ~/zsh-bench
~/zsh-bench/zsh-bench
```

**Key metrics and thresholds (imperceptible to users):**
| Metric | Threshold | Description |
|--------|-----------|-------------|
| First prompt lag | 50ms | Time until prompt appears |
| First command lag | 150ms | Time until first command can execute |
| Command lag | 10ms | Time from Enter to next prompt |
| Input lag | 20ms | Time from keypress to character display |

**Why it matters:** `time zsh -lic "exit"` measures something different from actual user experience. zsh-bench measures what users actually perceive. A shell can appear fast (low first-prompt lag from deferred loading) while having high first-command lag.

**When to use:** Before and after optimisation to validate user-perceived improvement. This is the "acceptance test" for the <300ms target.

### 1.4 hyperfine -- Statistical benchmarking for A/B comparison

| Attribute | Detail |
|-----------|--------|
| What | Command-line benchmarking tool with statistical analysis |
| Already installed | Yes (via Homebrew) |
| Confidence | HIGH -- well-known tool |

**Usage for shell startup:**
```bash
# Warm cache (typical use):
hyperfine --warmup 3 --runs 20 --shell=none 'zsh -lic "exit"'

# Cold cache (after system restart):
hyperfine --prepare 'sync; sudo purge' --runs 10 'zsh -lic "exit"'

# A/B comparison:
hyperfine --warmup 3 \
  'zsh -lic "exit"' \
  'ZSH_EVALCACHE_DISABLE=true zsh -lic "exit"'
```

**Key flags:**
- `--warmup N` -- run N times before measuring (eliminates cold-cache noise)
- `--prepare CMD` -- run before each measurement (for cold-cache testing)
- `--runs N` -- minimum 10 for reliable statistics (default)
- `--export-markdown FILE` -- export results table

**Caveat:** `zsh -lic "exit"` does NOT fully represent interactive startup (see zsh-bench above). Use hyperfine for quick A/B comparisons; use zsh-bench for absolute measurements.

**When to use:** Comparing before/after for specific changes. Quick iteration feedback loop.

---

## 2. Eval Caching Libraries

### Recommendation: evalcache (mroth) -- Use for oh-my-posh, zoxide, carapace

**Do NOT use evalcache for mise.** mise's output is NOT static (it includes hooks that react to directory changes). Use zsh-defer for mise instead.

### 2.1 evalcache (mroth/evalcache)

| Attribute | Detail |
|-----------|--------|
| What | Caches output of `eval "$(cmd)"` to a file, sources file on subsequent startups |
| Cache location | `$ZSH_EVALCACHE_DIR` (default: `~/.zsh-evalcache/`) |
| Invalidation | Manual only (`_evalcache_clear`) |
| Confidence | HIGH -- 1.3k+ stars, simple and proven |
| Source | [github.com/mroth/evalcache](https://github.com/mroth/evalcache) |

**Measured savings (from evalcache README):**

| Command | Without cache | With cache | Savings |
|---------|--------------|------------|---------|
| rbenv init | ~65ms | ~8ms | 88% |
| hub alias | ~30ms | ~6ms | 80% |
| scmpuff init | ~24ms | ~10ms | 58% |

**Integration with Sheldon:**
```toml
# In plugins.toml -- MUST load before any plugin that uses _evalcache:
[plugins.evalcache]
github = "mroth/evalcache"
```

**Usage -- replace `eval` with `_evalcache`:**
```zsh
# BEFORE (in hooks.zsh / external.zsh):
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"
eval "$(zoxide init zsh --no-cmd)"

# AFTER:
_evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
_evalcache zoxide init zsh --no-cmd
```

**For carapace:**
```zsh
# BEFORE:
eval "$(carapace _carapace)"

# AFTER:
_evalcache carapace _carapace
```

**Invalidation strategy:**
- Run `_evalcache_clear` after upgrading any cached tool (oh-my-posh, zoxide, carapace)
- Consider a chezmoi `run_onchange_` script that clears the cache when tool versions change
- Set `ZSH_EVALCACHE_DISABLE=true` for debugging

### 2.2 zsh-smartcache (QuarticCat) -- Alternative with auto-invalidation

| Attribute | Detail |
|-----------|--------|
| What | Like evalcache but auto-detects stale caches in the background |
| Invalidation | Automatic (background check after sourcing cache) |
| Confidence | MEDIUM -- smaller community, fewer stars |
| Source | [github.com/QuarticCat/zsh-smartcache](https://github.com/QuarticCat/zsh-smartcache) |

**Why NOT recommended:** The auto-invalidation is nice but adds complexity. evalcache is simpler, more proven, and manual invalidation is fine for tools that change infrequently (oh-my-posh, zoxide). The cache-clear step can be automated via chezmoi.

### 2.3 Which eval commands to cache vs defer

| Command | Strategy | Rationale |
|---------|----------|-----------|
| `oh-my-posh init zsh` | **evalcache** | Output is static (shell functions + hooks). ~40-80ms savings. |
| `zoxide init zsh` | **evalcache** | Output is static (shell functions). ~15-30ms savings. |
| `carapace _carapace` | **evalcache** | Output is static (completion registrations). ~20-40ms savings. |
| `mise activate zsh` | **zsh-defer** (NOT evalcache) | Output includes directory-change hooks that must be dynamic. Caching would break `mise` version switching. ~100-200ms savings by deferring. |
| `sheldon source` | **Cache to file** | See section 2.4 below. |

### 2.4 Caching `sheldon source` output

`eval "$(sheldon source)"` runs sheldon (a Rust binary) to generate shell script. This takes ~15-30ms. The output changes only when `plugins.toml` changes.

**Pattern: Cache sheldon output to a file, re-generate on config change:**
```zsh
# In .zshrc, replace:
#   eval "$(sheldon source)"
# With:
_sheldon_cache="$HOME/.cache/sheldon/source.zsh"
_sheldon_config="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
if [[ ! -f "$_sheldon_cache" || "$_sheldon_config" -nt "$_sheldon_cache" ]]; then
  mkdir -p "${_sheldon_cache:h}"
  sheldon source > "$_sheldon_cache"
fi
source "$_sheldon_cache"
unset _sheldon_cache _sheldon_config
```

This auto-invalidates when `plugins.toml` is modified (file timestamp comparison). No manual cache clearing needed.

**Expected savings:** ~15-30ms (eliminating the sheldon binary invocation).

---

## 3. zcompile

### Recommendation: Compile .zcompdump and sheldon cache only. Skip individual .zsh files.

| Attribute | Detail |
|-----------|--------|
| What | Pre-compiles .zsh files to .zwc (wordcode) format for faster parsing |
| Confidence | HIGH -- well-documented, romkatv tested extensively |

### 3.1 Where zcompile helps

**Compiling .zcompdump -- YES, worthwhile:**
```zsh
# Add to .zlogin (runs after .zshrc, in background):
{
  zcompdump="$HOME/.zcompdump"
  if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    zcompile "$zcompdump"
  fi
} &!
```
Expected saving: ~5-15ms on compinit load. The `.zcompdump` file is large (thousands of lines of completion definitions), so compilation matters here.

**Compiling sheldon cache file -- YES, if using the cached source pattern:**
```zsh
# After generating sheldon cache:
if [[ ! -f "${_sheldon_cache}.zwc" || "$_sheldon_cache" -nt "${_sheldon_cache}.zwc" ]]; then
  zcompile "$_sheldon_cache"
fi
```

### 3.2 Where zcompile does NOT help

**Individual .zsh files in zsh.d/ -- NOT worthwhile:**

romkatv's testing (zsh4humans issue #8) showed "no significant improvement" from zcompiling sourced scripts. The reason: ZSH already reads and parses these files very quickly. The bottleneck is the `eval` subshells and external commands, not file parsing.

With ~15 files averaging ~200 lines each, total parsing overhead is likely <5ms. zcompile would save <2ms -- not worth the complexity of managing .zwc files and cache invalidation.

### 3.3 zcompile summary

| Target | Compile? | Expected savings | Complexity |
|--------|----------|-----------------|------------|
| `.zcompdump` | YES | 5-15ms | Low (background in .zlogin) |
| Sheldon cache file | YES | 2-5ms | Low (alongside cache generation) |
| Individual `zsh.d/*.zsh` files | NO | <2ms total | Not worth it |
| `.zshrc` itself | NO | <1ms, breaks modification tracking | Avoid |

---

## 4. Benchmarking Methodology

### Recommended protocol for reliable, reproducible results

#### 4.1 Pre-requisites
- Close all terminal emulators except one
- Quit resource-intensive applications
- Wait 30s after system wake from sleep (for disk cache stabilisation)
- Ensure no background updates running (Homebrew, App Store, Spotlight indexing)

#### 4.2 Three-stage measurement

**Stage 1: Baseline with hyperfine (quick, statistical)**
```bash
# Warm-cache baseline (most common scenario):
hyperfine --warmup 5 --runs 30 --shell=none 'zsh -lic "exit"' \
  --export-markdown /tmp/baseline.md

# Record the mean and standard deviation
```

**Stage 2: Section timing with EPOCHREALTIME (identify bottlenecks)**
```zsh
# Temporarily add timing to .zshrc:
zmodload zsh/datetime
typeset -g __zshrc_start=$EPOCHREALTIME
typeset -g __t=$EPOCHREALTIME
__ts() {
  local now=$EPOCHREALTIME
  printf '%6.1fms (+%5.1fms) %s\n' \
    $(( (now - __zshrc_start) * 1000 )) \
    $(( (now - __t) * 1000 )) \
    "$1"
  __t=$now
}
```

Run 5 times, take the median of each section.

**Stage 3: Validate with zsh-bench (acceptance test)**
```bash
~/zsh-bench/zsh-bench
```

The target is:
- First prompt lag: <50ms (green)
- First command lag: <150ms (green, this maps to <300ms wall-clock with deferred loading)

#### 4.3 A/B testing protocol

When comparing before/after a specific change:
```bash
# 1. Measure "before" with hyperfine
hyperfine --warmup 5 --runs 30 --shell=none 'zsh -lic "exit"' \
  --export-json /tmp/before.json

# 2. Apply the change

# 3. Measure "after"
hyperfine --warmup 5 --runs 30 --shell=none 'zsh -lic "exit"' \
  --export-json /tmp/after.json

# 4. Or do both at once with env var toggling:
hyperfine --warmup 5 --runs 20 \
  'zsh -lic "exit"' \
  'ZSH_EVALCACHE_DISABLE=true zsh -lic "exit"'
```

#### 4.4 Cold vs warm start

| Scenario | When to test | How |
|----------|-------------|-----|
| Warm start | Normal usage (most important) | `hyperfine --warmup 5` |
| Cold start | After reboot, new machine setup | `hyperfine --prepare 'sync; sudo purge'` |

Focus on warm starts. Cold starts matter only for first-launch experience.

#### 4.5 Common measurement mistakes to avoid

1. **Using `time zsh -lic "exit"` alone** -- lacks statistical rigour, single measurement is noisy
2. **Forgetting `--warmup`** -- first few runs are always slower (disk cache, binary loading)
3. **Using `date +%s%N` on macOS** -- does not work (BSD date). Use `$EPOCHREALTIME`
4. **Measuring with zprof AND EPOCHREALTIME simultaneously** -- zprof adds overhead that skews EPOCHREALTIME readings. Use one at a time
5. **Not controlling for background processes** -- Spotlight indexing, Homebrew updates, etc. can add 50-100ms variance

---

## 5. Expected Impact Analysis

### Current estimated breakdown (based on typical macOS ZSH setups)

| Component | Estimated time | Optimisation | Expected after |
|-----------|---------------|-------------|----------------|
| `sheldon source` (binary invocation) | ~20-30ms | Cache to file | ~2-5ms |
| `oh-my-posh init zsh` | ~40-80ms | evalcache | ~5-8ms |
| `mise activate zsh` | ~100-200ms | zsh-defer | ~0ms (deferred) |
| `zoxide init zsh` | ~15-30ms | evalcache | ~5-8ms |
| `carapace _carapace` | ~20-40ms | evalcache | ~5-8ms |
| `compinit` | ~30-50ms | Already cached (24h) | ~15-20ms (+ zcompile) |
| `sheldon source` (eval overhead) | ~5-10ms | Eliminated by file cache | ~0ms |
| Plugin sourcing (12 deferred) | ~0ms sync | Already deferred | ~0ms |
| `zsh.d/*.zsh` sourcing (15 files) | ~10-20ms | No change needed | ~10-20ms |
| `fzf` shell scripts | ~5-10ms | No change needed | ~5-10ms |
| ZSH itself + .zshenv/.zprofile | ~10-15ms | No change possible | ~10-15ms |
| **TOTAL** | **~270-500ms** | | **~57-94ms** |

The 0.87s current measurement likely includes additional overhead not listed (ruby for ssh config parsing in completions.zsh, source commands in hooks.zsh for syntax-highlighting and autosuggestions which duplicate sheldon's deferred loading, etc.).

**The biggest wins are:**
1. **Deferring `mise activate zsh`** (~100-200ms saved)
2. **Caching `oh-my-posh init zsh`** (~35-72ms saved)
3. **Caching `sheldon source` output** (~15-25ms saved)
4. **Caching `zoxide init` and `carapace _carapace`** (~25-52ms saved combined)

---

## 6. Recommended Stack for Performance Optimisation

### Tools to add

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| evalcache | latest | Cache static eval output | Sheldon plugin (`github = "mroth/evalcache"`) |
| zsh-bench | latest | Acceptance testing | `git clone` to `~/zsh-bench` |

### Tools already in place (no changes)

| Tool | Purpose | Status |
|------|---------|--------|
| zsh-defer (romkatv) | Deferred plugin loading | Already loaded via Sheldon |
| hyperfine | Statistical benchmarking | Already installed via Homebrew |
| zprof | Function-level profiling | Built into ZSH |

### Tools NOT recommended

| Tool | Why not |
|------|---------|
| zsh-smartcache | More complex than evalcache, smaller community, auto-invalidation adds background work |
| zinit turbo mode | Would require replacing Sheldon entirely. Not worth it -- Sheldon + zsh-defer achieves similar results |
| zsh-lazyenv | Overkill for 4 eval commands. evalcache is simpler |
| multi-evalcache | Niche fork, not maintained |

---

## 7. Important Caveats

### evalcache + mise -- DO NOT COMBINE

`mise activate zsh` produces output that includes a `_mise_hook` precmd function which checks the current directory and activates appropriate tool versions. This is NOT static output -- it depends on runtime state. Caching it would break mise's directory-based version switching.

**Correct approach for mise:** Defer with `zsh-defer`:
```zsh
zsh-defer eval "$(mise activate zsh)"
```

Or defer with `zsh-defer -c`:
```zsh
zsh-defer -c 'eval "$(mise activate zsh)"'
```

### evalcache invalidation

After upgrading any cached tool, run `_evalcache_clear`. Automate this with a chezmoi `run_onchange_` script keyed on tool version hashes.

### Duplicate plugin loading in hooks.zsh

The current `hooks.zsh` sources zsh-autosuggestions and zsh-syntax-highlighting from Homebrew paths, but these are ALSO loaded (deferred) via Sheldon's `plugins.toml`. This means they load twice -- once sync (in hooks.zsh) and once deferred (via Sheldon). Removing the duplicates from `hooks.zsh` should provide immediate savings.

### Ruby in completions.zsh

`completions.zsh` line 16 runs `ruby -ne ...` to parse SSH config. This forks a Ruby interpreter on every shell startup. Replace with a pure-ZSH or `awk` equivalent for ~20-50ms savings.

---

## Sources

- [romkatv/zsh-bench](https://github.com/romkatv/zsh-bench) -- Benchmark methodology and thresholds
- [romkatv/zsh-bench README](https://github.com/romkatv/zsh-bench/blob/master/README.md) -- Deferred loading strategies, zcompile findings
- [mroth/evalcache](https://github.com/mroth/evalcache) -- Eval caching plugin, benchmarks
- [QuarticCat/zsh-smartcache](https://github.com/QuarticCat/zsh-smartcache) -- Auto-invalidating alternative
- [romkatv/zsh-defer](https://github.com/romkatv/zsh-defer) -- Deferred execution
- [romkatv/zsh4humans#8](https://github.com/romkatv/zsh4humans/issues/8) -- zcompile performance testing
- [sharkdp/hyperfine](https://github.com/sharkdp/hyperfine) -- Benchmarking methodology
- [mise discussion #4821](https://github.com/jdx/mise/discussions/4821) -- mise activate 100-200ms delay
- [sheldon docs](https://sheldon.cli.rs/) -- Lock file and source command
- [oh-my-posh #6043](https://github.com/JanDeDobbeleer/oh-my-posh/issues/6043) -- oh-my-posh startup slowness
- [Optimizing Zsh Init with ZProf](https://www.mikekasberg.com/blog/2025/05/29/optimizing-zsh-init-with-zprof.html) -- Profiling methodology
- [Speeding Up Zsh (Josh Yin)](https://www.joshyin.cc/blog/speeding-up-zsh) -- evalcache + zsh-defer combination
- [zimfw/zimfw#547](https://github.com/zimfw/zimfw/discussions/547) -- zcompile discussion
- [Speed Matters: Optimised ZSH Under 70ms](http://santacloud.dev/posts/optimizing-zsh-startup-performance/) -- Real-world optimisation case study
