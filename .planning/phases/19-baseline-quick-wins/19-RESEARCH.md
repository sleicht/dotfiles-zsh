# Phase 19: Baseline & Quick Wins - Research

**Researched:** 2026-02-14
**Domain:** ZSH shell startup performance profiling and optimisation
**Confidence:** HIGH

## Summary

Phase 19 establishes performance measurement baselines and implements low-risk optimisations targeting ~100-150ms improvement. The phase uses a three-stage profiling methodology (hyperfine for external timing, EPOCHREALTIME for internal profiling, zsh-bench for comprehensive analysis) to measure the impact of quick wins: removing duplicate plugin loads, replacing external command calls with pure-zsh implementations, and applying zsh-specific optimisations.

Research confirms that external command invocations (Ruby, Python) during shell startup add measurable overhead (typically 20-100ms+ per invocation), whilst zsh built-in parameter expansion and array operations are nearly instant. The duplicate loading issue in hooks.zsh is verified: zsh-autosuggestions and zsh-syntax-highlighting are already loaded via Sheldon with defer, making the synchronous loads in hooks.zsh pure waste. The `(( $+commands[tool] ))` pattern is documented as the idiomatic zsh approach for command existence checks, leveraging the built-in $commands hash table rather than spawning subshells.

**Primary recommendation:** Implement three-stage baseline first, then apply quick wins sequentially with re-measurement after each change to validate savings. The combination of eliminating duplicate plugin loads (~50-100ms) and replacing Ruby SSH parsing (~20-50ms) provides high-confidence, zero-risk improvements.

## Standard Stack

### Core Tools

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| zsh-bench | latest (git) | Interactive zsh latency measurement | Created by romkatv (author of powerlevel10k), measures user-visible latency via virtual TTY |
| hyperfine | v1.18+ | External startup time benchmarking | Industry-standard command-line benchmarking tool with statistical analysis and outlier detection |
| zsh/datetime | Built-in | Internal profiling via EPOCHREALTIME | Native zsh module, zero dependencies, microsecond precision |
| zsh/zprof | Built-in | Function-level profiling | Native zsh profiler, shows function call counts and wall-clock time |
| zsh/parameter | Built-in | Access to $commands hash table | Provides associative array of command paths, enables fast existence checks |

### Supporting Tools

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| /usr/bin/time | System default | Basic timing measurements | Quick validation, CI/CD environments |
| zsh-defer | romkatv/zsh-defer | Deferred plugin loading | Already installed via Sheldon, enables async loading |

### Installation

```bash
# zsh-bench (manual clone required)
git clone https://github.com/romkatv/zsh-bench ~/zsh-bench

# hyperfine (via Homebrew, likely already installed)
brew install hyperfine

# Built-in modules (no installation needed)
# zsh/datetime, zsh/zprof, zsh/parameter ship with zsh
```

## Architecture Patterns

### Three-Stage Profiling Methodology

**What:** Measure shell startup from three perspectives to build complete picture of performance.

**When to use:** Establishing baselines, validating optimisations, diagnosing startup issues.

**Why three stages:**
1. **hyperfine** - External observer, measures total startup time including process spawning, measures statistical distribution
2. **EPOCHREALTIME** - Internal instrumentation, line-by-line profiling, identifies specific bottlenecks
3. **zsh-bench** - User-visible latency, measures interactive responsiveness (first prompt, command lag, input lag)

**Example workflow:**

```bash
# Stage 1: External timing with hyperfine
hyperfine --warmup 3 --runs 10 'zsh -i -c exit'

# Stage 2: Internal profiling with EPOCHREALTIME
# Add to top of ~/.zshrc:
zmodload zsh/datetime
setopt PROMPT_SUBST
PS4='+$EPOCHREALTIME %N:%i> '
exec 3>&2 2>/tmp/zsh_profile.$$
setopt xtrace prompt_subst

# Add to bottom of ~/.zshrc:
unsetopt xtrace
exec 2>&3 3>&-

# Run and analyse:
zsh -i -c exit
awk '{if (prev) print $1-prev, $0; prev=$1}' /tmp/zsh_profile.$$ | sort -n -r | head -20

# Stage 3: Interactive latency with zsh-bench
~/zsh-bench/zsh-bench
```

### Pattern 1: Command Existence Checks

**What:** Use zsh built-in hash table instead of spawning subprocesses.

**When to use:** Any guard checking if a command exists before using it.

**Anti-pattern:**
```zsh
# SLOW - spawns subshell for each check
if command -v oh-my-posh > /dev/null; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"
fi
```

**Best practice:**
```zsh
# FAST - parameter expansion on built-in hash table
if (( $+commands[oh-my-posh] )); then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"
fi
```

**How it works:** The `$commands` associative array (from zsh/parameter module) maps command names to executable paths. The `${+name}` expansion returns 1 if parameter is set, 0 otherwise. The `(( ))` arithmetic evaluation treats non-zero as true.

**Source:** [Zsh Commands Hash Table](https://www.bashsupport.com/zsh/variables/commands/), [Zsh Parameter Expansion](https://zsh.sourceforge.io/Doc/Release/Expansion.html)

### Pattern 2: PATH Deduplication

**What:** Automatically prevent duplicate entries in PATH using zsh's typeset -U flag.

**When to use:** Early in shell initialisation, before PATH is modified.

**Implementation:**
```zsh
# Single line, typically in .zshenv or early in .zshrc
typeset -U PATH path FPATH fpath

# Explanation:
# -U = unique (automatic deduplication)
# -T = tied (scalar PATH ↔ array path, scalar FPATH ↔ array fpath)
# PATH/path are pre-tied by zsh, explicit -T not needed
# Lowercase variables are arrays, uppercase are colon-separated scalars
```

**Why this works:** Zsh ties `$PATH` (scalar string) to `$path` (array). Modifications to either are reflected in the other. The `-U` flag ensures uniqueness automatically, even when appending: `path+=(/duplicate)` silently ignores duplicates.

**Source:** [Remove Duplicates in $PATH](https://tech.serhatteker.com/post/2019-12/remove-duplicates-in-path-zsh/), [Zsh PATH Array Management](https://openillumi.com/en/en-zsh-path-array-management/)

### Pattern 3: Pure-Zsh Parsing

**What:** Replace external tools (Ruby, Python, awk, sed) with zsh built-in parameter expansion.

**When to use:** Simple text parsing during shell startup.

**Anti-pattern - SSH config parsing with Ruby:**
```zsh
# SLOW - spawns Ruby interpreter, parses file, 20-100ms overhead
_cache_hosts=(`ruby -ne 'if /^Host\s+(.+)$/; print $1.strip, "\n"; end' $HOME/.ssh/config`)
```

**Best practice - Pure zsh:**
```zsh
# FAST - pure zsh, no subprocess
_cache_hosts=()
if [[ -r $HOME/.ssh/config ]]; then
  # Read file, extract Host lines, split on whitespace
  _cache_hosts=(${${${(M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi

# Explanation of parameter expansion:
# $(<file)               - read entire file
# ${(f)...}              - split on newlines into array
# ${(M)...:#Host *}      - filter lines matching "Host *"
# ${...#Host }           - remove "Host " prefix
# ${...:#*[*?]*}         - exclude wildcard patterns (* and ?)
```

**Performance difference:** Ruby invocation adds 20-100ms, pure zsh is sub-millisecond.

**Sources:** [Faster ZSH](https://htr3n.github.io/2018/07/faster-zsh/), [Improving Zsh Performance](https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/)

### Pattern 4: Deferred Plugin Loading with Sheldon

**What:** Load plugins asynchronously after initial prompt to minimise first-prompt lag.

**When to use:** Plugins that don't need to be available before first prompt (syntax highlighting, autosuggestions, non-critical completions).

**Current configuration analysis:**
```toml
# .config/sheldon/plugins.toml
[plugins.zsh-defer]
github = "romkatv/zsh-defer"

[templates]
defer = "{{ hooks?.pre | nl }}{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}{{ hooks?.post | nl }}"

[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"
apply = ["defer"]

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
apply = ["defer"]
```

**Critical finding:** These plugins are ALREADY deferred via Sheldon, so synchronous loads in hooks.zsh are duplicates:

```zsh
# hooks.zsh lines 19-20 - DUPLICATES, to be removed
if [ -r "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then source "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh"; fi
if [ -r "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then source "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; fi
```

**Impact:** Removing these lines eliminates synchronous plugin loads (50-100ms), relying on Sheldon's deferred loading instead.

**Source:** [Sheldon Examples](https://sheldon.cli.rs/Examples.html)

### Anti-Patterns to Avoid

- **Never use `compinit -C` without date-based regeneration** - Skips security checks, can cause subtle bugs if new functions are added
- **Avoid hardcoding eval outputs without versioning** - `eval $(tool init)` overhead is real, but hardcoded output breaks on tool updates
- **Don't profile with warm caches only** - First startup (cold cache) often differs significantly from subsequent runs
- **Never optimise based on single measurements** - Statistical variance requires multiple runs (hyperfine does this automatically)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shell startup benchmarking | Custom `time` loops in bash | zsh-bench + hyperfine | zsh-bench measures user-visible latency via virtual TTY, hyperfine handles statistical analysis and outlier detection automatically |
| Line-by-line profiling | Manual timestamp insertion | EPOCHREALTIME + PS4 + xtrace | Built-in zsh capability, microsecond precision, automatic line numbering |
| Function-level profiling | Custom instrumentation | zsh/zprof | Native profiler, shows call counts and wall-clock time with zero setup |
| Command existence checks | Parsing `which` output | `(( $+commands[cmd] ))` | Built-in hash table lookup, no subprocess, handles aliases/functions/builtins correctly |
| SSH config parsing | Custom parser | zsh parameter expansion | Pattern matching, filtering, prefix removal all built-in, no external dependencies |

**Key insight:** Zsh has extremely powerful built-in capabilities for text processing, parameter manipulation, and profiling. External tools (Ruby, Python, awk) are slower during startup due to interpreter launch overhead. Modern benchmarking tools (zsh-bench, hyperfine) exist specifically for shell profiling and are maintained by experts.

## Common Pitfalls

### Pitfall 1: Profiling Without Representative Load

**What goes wrong:** Profiling an empty shell or shell without typical git repository context produces misleading results.

**Why it happens:** Many zsh features are git-aware (prompts, completions). Performance in non-git directory differs from typical usage.

**How to avoid:** zsh-bench automatically creates test environment with 1,000 directories and 10,000 files in git repo. For manual profiling, use typical working directory.

**Warning signs:** Benchmark shows <10ms first-prompt lag but interactive usage feels sluggish.

**Source:** [zsh-bench README](https://github.com/romkatv/zsh-bench)

### Pitfall 2: Confusing First-Prompt Lag with Command Lag

**What goes wrong:** Optimising the wrong metric - reducing command lag when first-prompt lag is the real bottleneck.

**Why it happens:** Different metrics measure different things:
- **first_prompt_lag_ms**: Time until you can type (affects new terminal windows)
- **command_lag_ms**: Time from Enter to next prompt (affects every command)
- **input_lag_ms**: Keystroke to character display (affects typing feel)

**How to avoid:** Measure all three with zsh-bench, prioritise based on usage patterns. For new terminals, first-prompt lag matters most. For long-running sessions, command/input lag matters more.

**Warning signs:** Fast startup time but slow interactive usage, or vice versa.

**Source:** [zsh-bench metrics](https://github.com/romkatv/zsh-bench)

### Pitfall 3: Over-Optimising with Unsafe Techniques

**What goes wrong:** Using `compinit -C` (skip security checks), compiling .zshrc to bytecode, or other fragile optimisations that break on updates.

**Why it happens:** These techniques show impressive benchmark improvements but create maintenance burden and subtle bugs.

**How to avoid:** Focus on architectural changes (deferred loading, eliminating external commands) rather than micro-optimisations. If using `compinit -C`, implement date-based regeneration (as current Sheldon config does).

**Warning signs:** Shell breaks after updating plugins, mysterious completion failures, security warnings.

**Source:** [Improving Zsh Performance](https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/)

### Pitfall 4: Double-Loading Plugins

**What goes wrong:** Plugin loaded both directly (via source in .zshrc) and via plugin manager (Sheldon/Oh-My-Zsh), causing conflicts, slowness, or duplicate functionality.

**Why it happens:** Historical accumulation - plugin added directly, then later added to plugin manager, but original source line never removed.

**How to avoid:** Single source of truth - if plugin manager handles a plugin, remove all manual source lines. Check for duplicates: `grep -r "zsh-autosuggestions" ~/.zshrc ~/.zsh.d/`

**Warning signs:**
- Plugins loaded twice in zprof output
- Conflicts between zsh-autosuggestions and zsh-syntax-highlighting
- Unexpectedly high first-prompt lag

**Current instance:** hooks.zsh lines 19-20 source zsh-autosuggestions and zsh-syntax-highlighting, but Sheldon config already defers these plugins.

**Source:** [zsh-autosuggestions Issue #483](https://github.com/zsh-users/zsh-autosuggestions/issues/483)

### Pitfall 5: Incorrect EPOCHREALTIME Arithmetic

**What goes wrong:** Getting confusing negative values or huge numbers when calculating time deltas.

**Why it happens:** EPOCHREALTIME is seconds.nanoseconds since Unix epoch. Direct subtraction works for deltas, but multiplication/conversion errors are common.

**How to avoid:**
```zsh
# Correct delta calculation:
start=$EPOCHREALTIME
# ... some work ...
end=$EPOCHREALTIME
delta_ms=$(( (end - start) * 1000 ))

# Common mistake - don't do this:
delta_wrong=$(( EPOCHREALTIME * 1000 - start ))  # Wrong - EPOCHREALTIME changed!
```

**Warning signs:** Negative time values, times in billions of milliseconds.

**Source:** [Profiling ZSH Startup](https://stevenvanbael.com/profiling-zsh-startup)

## Code Examples

Verified patterns from official sources and current codebase:

### Establishing Three-Stage Baseline

```bash
#!/usr/bin/env zsh
# baseline-measurement.zsh

echo "=== Stage 1: External timing with hyperfine ==="
hyperfine --warmup 3 --runs 10 --export-json /tmp/baseline-hyperfine.json \
  'zsh -i -c exit'

echo -e "\n=== Stage 2: Internal profiling with EPOCHREALTIME ==="

# Backup current .zshrc
cp ~/.zshrc ~/.zshrc.profiling-backup

# Add profiling instrumentation
cat > /tmp/profiling-header.zsh << 'EOF'
zmodload zsh/datetime
setopt PROMPT_SUBST
PS4='+$EPOCHREALTIME %N:%i> '
exec 3>&2 2>/tmp/zsh_profile.$$
setopt xtrace
EOF

cat > /tmp/profiling-footer.zsh << 'EOF'
unsetopt xtrace
exec 2>&3 3>&-
EOF

# Inject instrumentation
echo "# PROFILING HEADER" > ~/.zshrc.profiling
cat /tmp/profiling-header.zsh >> ~/.zshrc.profiling
echo "# ORIGINAL ZSHRC" >> ~/.zshrc.profiling
cat ~/.zshrc.profiling-backup >> ~/.zshrc.profiling
echo "# PROFILING FOOTER" >> ~/.zshrc.profiling
cat /tmp/profiling-footer.zsh >> ~/.zshrc.profiling

# Run profiled shell
ZDOTDIR=~ HOME=$HOME zsh -c 'cp ~/.zshrc.profiling ~/.zshrc && zsh -i -c exit'

# Find the latest profile
PROFILE=$(ls -t /tmp/zsh_profile.* | head -1)

# Analyse (convert to milliseconds, sort by duration)
echo "Top 20 slowest operations:"
awk 'NR>1 {if (prev) printf "%.2f ms - %s\n", ($1-prev)*1000, $0; prev=$1}' "$PROFILE" \
  | sort -n -r \
  | head -20

# Restore original .zshrc
mv ~/.zshrc.profiling-backup ~/.zshrc

echo -e "\n=== Stage 3: Interactive latency with zsh-bench ==="
~/zsh-bench/zsh-bench
```

**Source:** [EPOCHREALTIME Profiling](https://esham.io/2018/02/zsh-profiling), [zsh-bench Usage](https://github.com/romkatv/zsh-bench)

### Quick Win 1: Remove Duplicate Plugin Loads

```zsh
# Current state - hooks.zsh lines 19-20
if [ -r "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then source "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh"; fi
if [ -r "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then source "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; fi

# Action: DELETE these lines
# Rationale: Sheldon already loads these with apply = ["defer"]
# Expected saving: 50-100ms (synchronous load + duplicate initialisation)
```

### Quick Win 2: Replace Ruby SSH Config Parsing

```zsh
# Current state - completions.zsh line 16
_cache_hosts=(`ruby -ne 'if /^Host\s+(.+)$/; print $1.strip, "\n"; end' $HOME/.ssh/config`)

# Pure-zsh replacement:
_cache_hosts=()
if [[ -r $HOME/.ssh/config ]]; then
  _cache_hosts=(${${${(M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi

# Breakdown of parameter expansion:
# Step 1: $(<$HOME/.ssh/config)        - Read file into string
# Step 2: ${(f)"..."}                   - Split on newlines (f flag)
# Step 3: ${(M)...:#Host *}             - Match lines starting with "Host " (M flag + :# pattern)
# Step 4: ${...#Host }                  - Remove "Host " prefix (# pattern from start)
# Step 5: ${...:#*[*?]*}                - Exclude entries with wildcards (:\# negation)

# Expected saving: 20-50ms (Ruby interpreter startup)
```

**Source:** Parameter expansion based on [Zsh Expansion Guide](https://thevaluable.dev/zsh-expansion-guide-example/)

### Quick Win 3: Replace command -v with (( $+commands[tool] ))

```bash
#!/usr/bin/env zsh
# Script to replace all instances

# Files to update (from grep results):
files=(
  ~/.zsh.d/hooks.zsh
  ~/.zsh.d/intelli-shell.zsh
  ~/.zsh.d/functions.zsh
  ~/.zsh.d/completions.zsh
  ~/.zsh.d/carapace.zsh
  ~/.zsh.d/keybinds.zsh
  ~/.zsh.d/atuin.zsh
)

for file in $files; do
  # Pattern 1: if command -v tool > /dev/null; then
  sed -i.bak 's/if command -v \([a-z-]*\) > \/dev\/null; then/if (( $+commands[\1] )); then/g' "$file"

  # Pattern 2: if command -v tool >/dev/null 2>&1; then
  sed -i.bak 's/if command -v \([a-z-]*\) >\/dev\/null 2>&1; then/if (( $+commands[\1] )); then/g' "$file"

  # Pattern 3: command -v tool > /dev/null || alias
  sed -i.bak 's/command -v \([a-z-]*\) > \/dev\/null || /((! $+commands[\1] )) \&\& /g' "$file"
done

# Expected saving: Minor (5-10ms total), but more idiomatic zsh
```

**Note:** Aliases in aliases.zsh (lines 105, 108, 111) use `command -v` in alias definitions, not guards. These should remain unchanged as they're run-time checks, not startup-time.

### Quick Win 4: Add PATH Deduplication

```zsh
# Add to top of .zshenv (before any PATH modifications)
typeset -U PATH path FPATH fpath

# This ensures:
# - PATH automatically deduplicates when modified
# - FPATH automatically deduplicates when modified
# - No performance penalty (built-in feature)
# - Works even if PATH is modified multiple times

# Expected saving: Minimal direct impact, prevents future issues
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `command -v tool` | `(( $+commands[tool] ))` | Always available | Idiomatic zsh, no subprocess |
| Eval all tool inits | Defer non-critical inits | Sheldon 0.6+, zsh-defer 2020+ | 100-500ms improvement |
| Manual PATH dedup | `typeset -U PATH path` | Zsh 3.0+ (1996) | Automatic, no maintenance |
| Ruby/Python parsing | Pure zsh parameter expansion | Always available | 20-100ms per external call |
| Manual completion caching | Date-based compinit | Common pattern | Security + performance balance |
| Single measurement | Statistical benchmarking | hyperfine 1.0+ (2018) | Reliable results, outlier detection |
| `time` for profiling | zsh-bench | 2021+ (romkatv) | User-visible latency, not just startup time |

**Deprecated/outdated:**
- **Oh-My-Zsh default config**: Loads all plugins synchronously, 500ms-2s startup time. Modern alternative: Sheldon with deferred loading.
- **Antigen plugin manager**: Unmaintained since 2019. Modern alternative: Sheldon (Rust-based, fast).
- **compinit without caching**: Rebuilds completions every startup. Modern approach: date-based regeneration (current Sheldon config implements this correctly).
- **Manual `eval $(brew shellenv)`**: Ruby startup overhead. Modern approach: hardcode output (with version detection for updates).

## Open Questions

1. **What is the actual overhead of `ssh-add --apple-load-keychain`?**
   - What we know: It's in ssh.zsh, runs synchronously during startup
   - What's unclear: Whether it blocks (waits for keychain), how long it takes
   - Recommendation: Measure with EPOCHREALTIME profiling (Stage 2), consider backgrounding with `&` if slow

2. **Should large completion scripts (wt.zsh, lens-completion.zsh) be deferred?**
   - What we know: 214 lines each, currently loaded via Sheldon with apply=["source"]
   - What's unclear: Whether these completions are used frequently enough to justify synchronous load
   - Recommendation: Measure with zprof, consider moving to apply=["defer"] if they show up in top 10 functions

3. **What is the real impact of oh-my-posh and mise during startup?**
   - What we know: Startup analysis suggests 50-200ms (oh-my-posh) and 30-80ms (mise)
   - What's unclear: Whether these ranges are accurate for this specific configuration
   - Recommendation: EPOCHREALTIME profiling will provide precise measurements, but these are likely candidates for Phase 20 (major optimisations)

## Sources

### Primary (HIGH confidence)

- [zsh-bench GitHub](https://github.com/romkatv/zsh-bench) - Interactive zsh latency benchmarking
- [hyperfine GitHub](https://github.com/sharkdp/hyperfine) - Command-line benchmarking tool
- [Zsh Parameter Expansion Documentation](https://zsh.sourceforge.io/Doc/Release/Expansion.html) - Official zsh manual
- [Zsh Commands Hash Table](https://www.bashsupport.com/zsh/variables/commands/) - $commands associative array documentation
- [Sheldon Examples](https://sheldon.cli.rs/Examples.html) - Deferred loading patterns
- [Profiling ZSH with EPOCHREALTIME](https://esham.io/2018/02/zsh-profiling) - EPOCHREALTIME profiling guide
- [Improving Zsh Performance](https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/) - Avoiding external commands

### Secondary (MEDIUM confidence)

- [Remove Duplicates in $PATH](https://tech.serhatteker.com/post/2019-12/remove-duplicates-in-path-zsh/) - typeset -U usage
- [Faster ZSH](https://htr3n.github.io/2018/07/faster-zsh/) - Pure zsh vs external tools
- [Z-Shell Benchmarking Guide](https://wiki.zshell.dev/docs/guides/benchmark) - Multiple profiling approaches
- [Profiling ZSH Startup](https://stevenvanbael.com/profiling-zsh-startup) - EPOCHREALTIME examples
- [Speeding Up ZSH](https://scottspence.com/posts/speeding-up-my-zsh-shell) - Common optimisation patterns

### Tertiary (LOW confidence - general guidance)

- [You Probably Don't Need Oh My Zsh](https://rushter.com/blog/zsh-shell/) - Plugin management philosophy
- [Speeding Up Oh-My-Zsh](https://blog.jonlu.ca/posts/speeding-up-zsh) - Lazy loading patterns
- [Lightning Fast ZSH Performance](https://joshghent.com/zsh-speed/) - General optimisation tips

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools well-documented, actively maintained, widely used
- Architecture patterns: HIGH - Patterns verified in official documentation and current codebase
- Pitfalls: MEDIUM-HIGH - Based on documented issues and common mistakes, some inferred from best practices

**Research date:** 2026-02-14
**Valid until:** 2026-04-14 (60 days - stable ecosystem, slow-moving zsh development)

**Research completeness:**
- ✅ Three-stage profiling methodology documented with examples
- ✅ All quick wins verified against current codebase
- ✅ Performance patterns backed by official documentation
- ✅ Common pitfalls identified from community experience
- ✅ Code examples tested against zsh parameter expansion syntax
- ⚠️ Some performance numbers are ranges/estimates (precise numbers require measurement)
- ⚠️ Open questions about specific tools (ssh-add, oh-my-posh, mise) require profiling to answer
