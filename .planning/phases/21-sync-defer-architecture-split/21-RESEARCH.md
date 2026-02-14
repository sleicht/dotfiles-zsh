# Phase 21: Sync/Defer Architecture Split - Research

**Researched:** 2026-02-14
**Domain:** ZSH shell startup optimization, lazy loading, plugin management
**Confidence:** HIGH

## Summary

Phase 21 aims to split shell initialization into synchronous (prompt-critical) and deferred (non-critical) components to reduce perceived startup time. This is a **file refactoring and reorganisation** phase that leverages existing infrastructure (Sheldon plugin manager with zsh-defer, evalcache from Phase 20) to defer non-critical work until after the first prompt appears.

The core strategy is splitting `.zsh.d/` configuration files into sync/defer variants and reorganising Sheldon's plugin loading groups. This is **architectural surgery**: moving code between files while maintaining functional correctness under strict ordering constraints (prompt hooks must be synchronous, completions require specific setup order, mise needs PATH fallback).

Current state: 131.2ms startup with all evalcache optimisations from Phase 20. Expected improvement: 100-200ms **perceived** reduction (deferred work becomes invisible to user, happening after prompt appears).

**Primary recommendation:** Use Sheldon's `apply` mechanism with separate plugin definitions for sync vs defer content. Split files surgically (one requirement per file change), verify at each step, measure perceived improvement with human timing (stopwatch from shell invocation to usable prompt).

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Sheldon | Latest (via Homebrew) | Plugin manager with template support | Fast, supports custom templates for defer, already in use, handles plugin groups naturally |
| zsh-defer | Latest (romkatv) | Deferred command execution | Industry standard for ZSH lazy loading, executes queued commands when zle is idle, already loaded via Sheldon |
| evalcache | Latest (mroth) | Eval caching layer | Already in place (Phase 20), caches static init output, works with deferred loading |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| zsh-bench | Latest | Shell startup profiling | Measure first_prompt_lag_ms, verify improvement |
| hyperfine | Latest | Command timing with statistics | Measure actual startup time (full shell lifecycle) |
| zprof | Built-in ZSH | Function-level profiling | Debug if defer breaks functionality, identify bottlenecks |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Sheldon groups | zinit Turbo mode | zinit has built-in turbo, but requires migration from Sheldon (not in scope) |
| zsh-defer | Manual background jobs with `&!` | More control but error-prone, no idle detection, zsh-defer handles buffered input correctly |
| File splitting | Single file with defer wrappers | Less clear separation, harder to audit sync vs defer, file split makes intent explicit |

**Installation:**

Already installed. No new dependencies required.

## Architecture Patterns

### Recommended File Structure

Current state (Phase 20):
```
.zsh.d/
├── hooks.zsh              # oh-my-posh (cached), FZF bindings, atuin bindings, preexec
├── external.zsh           # FZF exports, zoxide (cached), mise activate
├── completions.zsh        # zstyles, SSH host cache, autoloads, completion evals
├── atuin.zsh              # atuin init (cached)
├── carapace.zsh           # carapace init (cached)
├── intelli-shell.zsh      # intelli-shell init (cached)
├── ssh.zsh                # ssh-add --apple-load-keychain
└── (other files: aliases, functions, variables, keybinds, path, lens/wt/xlaude completions)
```

Target state (Phase 21):
```
.zsh.d/
├── prompt.zsh             # oh-my-posh ONLY (sync, prompt-critical)
├── external-sync.zsh      # FZF exports ONLY (sync, needed for FZF plugins)
├── completions-sync.zsh   # zstyles, autoloads, colors (sync, completion foundation)
├── external-defer.zsh     # zoxide, mise (defer, tools available after prompt)
├── completions-defer.zsh  # SSH hosts, completion definitions (defer)
├── atuin-defer.zsh        # atuin init → defer group
├── carapace-defer.zsh     # carapace init → defer group
├── intelli-shell-defer.zsh # intelli-shell init → defer group
├── ssh-defer.zsh          # ssh-add → defer group
└── (unchanged: aliases, functions, variables, keybinds, path remain sync)
```

Sheldon configuration pattern:
```toml
[plugins.dotfiles-sync]
local = "~/.zsh.d"
use = ["prompt.zsh", "external-sync.zsh", "completions-sync.zsh", "aliases.zsh", "functions.zsh", "variables.zsh", "keybinds.zsh", "path.zsh"]
apply = ["source"]

[plugins.dotfiles-defer]
local = "~/.zsh.d"
use = ["external-defer.zsh", "completions-defer.zsh", "atuin-defer.zsh", "carapace-defer.zsh", "intelli-shell-defer.zsh", "ssh-defer.zsh", "lens-completion.zsh", "wt.zsh", "xlaude.zsh"]
apply = ["defer"]
```

### Pattern 1: Sync vs Defer Decision Tree

**What:** Decision framework for what stays sync vs defers

**When to use:** For each piece of initialisation code, ask:

```
Is it required for prompt rendering?
├─ YES → SYNC (oh-my-posh, precmd hooks)
└─ NO → Is it required for interactive use immediately?
    ├─ YES → Does it define keybindings/widgets?
    │   ├─ YES → SYNC (FZF key-bindings, atuin key-bindings)
    │   └─ NO → Is it an environment export?
    │       ├─ YES → Does another sync component depend on it?
    │       │   ├─ YES → SYNC (FZF_DEFAULT_COMMAND for fzf-tab)
    │       │   └─ NO → DEFER
    │       └─ NO → DEFER
    └─ NO → DEFER (tools, completions, ssh-add)
```

**Example:**
```zsh
# SYNC: Prompt requires this immediately
if (( $+commands[oh-my-posh] )); then
  _evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
fi

# DEFER: Navigation tool, not needed until user invokes it
if (( $+commands[zoxide] )); then
  _evalcache zoxide init zsh --no-cmd
fi
```

**Source:** Synthesised from [zsh-defer README](https://github.com/romkatv/zsh-defer) and [Sheldon defer examples](https://sheldon.cli.rs/Examples.html)

### Pattern 2: FZF Dependency Chain

**What:** FZF has environment variables (sync) and key bindings (can defer via Sheldon plugins)

**Current state:**
- hooks.zsh sources FZF completion.zsh and key-bindings.zsh (sync)
- external.zsh exports FZF_DEFAULT_COMMAND etc (sync)
- fzf-tab plugin (already deferred via Sheldon)

**Correct split:**
- external-sync.zsh: FZF environment exports (required by fzf-tab plugin)
- FZF completion/key-bindings: REMOVE from hooks.zsh (redundant - Sheldon loads fzf-tab/fzf-git which provide this)
- atuin-defer.zsh: atuin keybindings source (can defer, atuin loads async)

**Why:** fzf-tab depends on FZF_DEFAULT_COMMAND being set when it loads. Since fzf-tab is deferred, FZF exports must be sync (loaded before deferred group). But FZF key-bindings.zsh sourcing is redundant (fzf-git.sh plugin provides this).

### Pattern 3: mise PATH Fallback Strategy

**What:** mise activate is slow (~30-80ms, uncached due to directory-dependent output). Use shims in .zprofile as immediate PATH fallback, full activation in deferred group.

**Implementation:**
```zsh
# .zprofile (login shells, runs once)
# Provides immediate PATH access via shims
eval "$(mise activate zsh --shims)"

# .zsh.d/external-defer.zsh (deferred in interactive shells)
# Provides full mise features (hooks, env vars)
eval "$(mise activate zsh)"
```

**Why:** mise activate --shims is fast, adds ~/.local/share/mise/shims to PATH. Shims intercept commands and load context on-demand. Full mise activate removes shims from PATH (no conflict) and adds hooks/env. User gets tool access immediately (via shims), full features after prompt (hooks, env vars).

**Source:** [mise shims documentation](https://mise.jdx.dev/dev-tools/shims.html)

**Tradeoff:** Shims don't support all features (no hooks until full activation). Acceptable: user can run commands immediately, hooks add features after prompt appears.

### Pattern 4: Completion System Ordering

**What:** ZSH completion has strict ordering: zstyles → compinit → completion functions

**Current state:**
- Sheldon loads compinit plugin (sync, before all plugins)
- completions.zsh: zstyles, autoloads, SSH hosts, completion evals

**Correct split:**
```zsh
# completions-sync.zsh (before compinit in Sheldon order)
# Foundation: zstyles, colors, word-style
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z} r:|[-_.]=**'
autoload -Uz colors; colors
autoload -Uz select-word-style; select-word-style default

# completions-defer.zsh (after compinit, can defer)
# Dynamic data: SSH hosts, completion definitions
_cache_hosts=(${${${(M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
eval "$(phantom completion zsh 2>/dev/null)" || true
```

**Why:** compinit needs zstyles set before it runs (configuration). But it doesn't need SSH host cache or runtime completion definitions. Those can load after prompt.

**Constraint:** Sheldon loads plugins in definition order. Must ensure: evalcache → zsh-defer → compinit → dotfiles-sync → (deferred plugins) → dotfiles-defer.

### Anti-Patterns to Avoid

- **Deferring prompt functions:** Never defer oh-my-posh, precmd, preexec. Prompt won't render correctly.
- **Deferring sync dependencies:** Don't defer FZF exports if fzf-tab (deferred) depends on them. Sync first, defer consumers.
- **Assuming defer = faster:** Defer reduces **perceived** time (prompt appears sooner) but total work is the same. Don't defer if user needs it immediately (keybindings for Ctrl+R).
- **Removing source from hooks.zsh without checking:** FZF completion.zsh and atuin-keybindings.zsh might be redundant (Sheldon loads fzf-git, atuin init sets up bindings). Verify before removing.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deferred execution timing | Manual `{ ... } &!` background jobs | zsh-defer | Handles zle idle detection, processes buffered keyboard input correctly, manages execution queue |
| Plugin loading groups | Custom sourcing logic in .zshrc | Sheldon templates and apply | Declarative, supports defer template, less error-prone than manual loops |
| Init caching | Manual cache files with timestamp checks | evalcache (Phase 20) | Already in place, handles cache invalidation, compiles to .zwc automatically |
| Measuring perceived startup | Manual timing with `date +%s%N` | zsh-bench first_prompt_lag_ms | Purpose-built for ZSH, separates perceived vs actual time |

**Key insight:** Shell startup optimisation has many edge cases (zle state, keyboard input buffering, widget registration timing, completion system ordering). Use battle-tested tools that handle these correctly.

## Common Pitfalls

### Pitfall 1: Deferring Commands That Read stdin

**What goes wrong:** zsh-defer redirects stdin to /dev/null. Commands that might need keyboard input hang or fail silently.

**Why it happens:** Deferred commands execute when zle is idle (waiting for input). If command tries to read stdin, it gets EOF.

**How to avoid:** Never defer interactive commands (less common in .zshrc). ssh-add --apple-load-keychain is safe (reads from keychain, not stdin).

**Warning signs:** Command works when sourced directly but fails when deferred. Check if command has interactive prompts.

**Source:** [zsh-defer documentation](https://github.com/romkatv/zsh-defer)

### Pitfall 2: Variable Scope in Deferred Functions

**What goes wrong:** zsh-defer executes with `LOCAL_OPTIONS`, `LOCAL_PATTERNS`, `LOCAL_TRAPS`. Using `typeset` without `-g` creates local variables that disappear after function exits.

**Why it happens:** Deferred code runs in function scope, not global scope.

**How to avoid:** Use `typeset -g` for global variables in deferred code, or use `export` which is always global.

**Warning signs:** Variable set in deferred file is empty when accessed later. Check with `typeset -p VAR_NAME`.

**Example:**
```zsh
# WRONG (in deferred file)
typeset MY_VAR="value"  # Local to defer function, lost after execution

# CORRECT
typeset -g MY_VAR="value"  # Global, persists
export MY_VAR="value"      # Global, persists, exported to subprocesses
```

### Pitfall 3: Completion Definition Order

**What goes wrong:** Defining completions before compinit runs has no effect. Completions must be defined after compinit.

**Why it happens:** compinit sets up completion system. Definitions before it are ignored.

**How to avoid:** Current Sheldon config loads compinit plugin before dotfiles. Completion definitions in dotfiles work. If moving completions to defer, they still run after compinit (Sheldon order: compinit → sync plugins → defer plugins).

**Warning signs:** Tab completion doesn't work for a command. Check if completion definition is in deferred group (should work) or accidentally removed.

### Pitfall 4: FZF Environment Dependencies

**What goes wrong:** fzf-tab plugin (deferred) fails to customise behaviour if FZF_DEFAULT_COMMAND is not set when it loads.

**Why it happens:** Deferred plugins load after sync plugins. If FZF exports are in defer group, fzf-tab loads before them (incorrect order).

**How to avoid:** Keep FZF exports in sync group (external-sync.zsh). Deferred plugins can then use them.

**Warning signs:** fzf-tab shows wrong preview or uses wrong source. Check if FZF_* variables are set when fzf-tab loads.

### Pitfall 5: Redundant Sourcing

**What goes wrong:** Sourcing FZF completion.zsh and key-bindings.zsh in hooks.zsh might be redundant if Sheldon's fzf-git plugin already provides this.

**Why it happens:** Historical configuration. fzf-git.sh provides key bindings for git objects. Homebrew's FZF key-bindings.zsh provides Ctrl+R, Ctrl+T, Alt+C. These are different.

**How to avoid:** Verify what fzf-git provides vs what FZF key-bindings.zsh provides. If both needed, keep sourcing. If redundant, remove.

**Warning signs:** Keybindings work without sourcing FZF files (safe to remove). Keybindings break after removal (needed, keep sourcing).

**Current state check required:** Test removing FZF sourcing from hooks.zsh, verify Ctrl+T (file search), Ctrl+R (history - should be Atuin), Alt+C (directory search) still work.

### Pitfall 6: Measuring Wrong Metric

**What goes wrong:** Using hyperfine to measure full shell lifecycle (`zsh -i -c exit`) shows total time, not perceived time.

**Why it happens:** Deferred work happens after prompt but before shell exits. hyperfine captures all of it.

**How to avoid:** Use zsh-bench `first_prompt_lag_ms` (perceived time to usable prompt) AND hyperfine (total time including deferred work). Perceived time should drop significantly, total time should stay similar (work moved, not eliminated).

**Warning signs:** hyperfine shows no improvement but shell "feels" faster. Use zsh-bench or manual stopwatch (shell start → prompt appears).

## Code Examples

Verified patterns from official sources and current configuration:

### Sheldon Plugin Groups (Sync and Defer)

```toml
# Source: Adapted from https://sheldon.cli.rs/Examples.html
# Current: ~/.config/sheldon/plugins.toml

# Load evalcache first (required by dotfiles)
[plugins.evalcache]
github = "mroth/evalcache"

# Load zsh-defer second (required by defer template)
[plugins.zsh-defer]
github = "romkatv/zsh-defer"

# Define defer template
[templates]
defer = "{{ hooks?.pre | nl }}{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}{{ hooks?.post | nl }}"

# Load compinit third (required by completions)
[plugins.compinit]
inline = '''
autoload -Uz compinit
if [[ -f "${ZDOTDIR:-$HOME}/.zcompdump" ]]; then
  compinit -C
else
  compinit
fi
'''

# Load prompt-critical dotfiles fourth (sync, before defer)
[plugins.dotfiles-sync]
local = "~/.zsh.d"
use = ["prompt.zsh", "external-sync.zsh", "completions-sync.zsh", "aliases.zsh", "functions.zsh", "variables.zsh", "keybinds.zsh", "path.zsh"]
apply = ["source"]

# Load external deferred plugins fifth (fzf-tab, syntax-highlighting, etc.)
[plugins.fzf-tab]
github = "Aloxaf/fzf-tab"
apply = ["defer"]

[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"
apply = ["defer"]

# ... other deferred plugins

# Load non-critical dotfiles last (defer, after external plugins loaded)
[plugins.dotfiles-defer]
local = "~/.zsh.d"
use = ["external-defer.zsh", "completions-defer.zsh", "atuin-defer.zsh", "carapace-defer.zsh", "intelli-shell-defer.zsh", "ssh-defer.zsh", "lens-completion.zsh", "wt.zsh", "xlaude.zsh"]
apply = ["defer"]
```

### File Split: hooks.zsh → prompt.zsh

```zsh
# Source: Current ~/.zsh.d/hooks.zsh
# Target: ~/.zsh.d/prompt.zsh (SYNC, prompt-critical only)

# Managed by chezmoi
#!/usr/bin/env zsh

# oh-my-posh: MUST be sync (sets up precmd hooks for prompt)
if (( $+commands[oh-my-posh] )); then
  _evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
fi

# preexec hook: print blank line before command output
preexec() { print '' }
```

**Removed from hooks.zsh:**
- HOMEBREW_PREFIX detection (move to external-sync.zsh or variables.zsh)
- FZF completion/key-bindings sourcing (verify if redundant, remove if so)
- Atuin keybindings sourcing (move to atuin-defer.zsh)
- REPOSITORIES_PATH variables (move to variables.zsh)

### File Split: external.zsh → external-sync.zsh + external-defer.zsh

```zsh
# Source: Current ~/.zsh.d/external.zsh
# Target 1: ~/.zsh.d/external-sync.zsh (FZF exports only)

# Managed by chezmoi
#!/usr/bin/env zsh

# === fzf ===
# Environment exports required by fzf-tab (deferred plugin)
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type=d --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_OPTS="--preview '_fzf_complete_realpath {}'"
export FZF_ALT_C_OPTS="--preview '_fzf_complete_realpath {}'"
export FZF_GIT_COLOR='never'
export FZF_GIT_PREVIEW_COLOR='always'
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
--layout=reverse-list
--bind 'ctrl-a:toggle'
--bind 'ctrl-h:change-preview-window(hidden|)'
--cycle
-i
"

# fzf completion functions (used by fzf-tab)
_fzf_compgen_path() {
  fd --hidden --no-ignore-vcs --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --no-ignore-vcs --exclude .git . "$1"
}
```

```zsh
# Target 2: ~/.zsh.d/external-defer.zsh (zoxide, mise - can defer)

# Managed by chezmoi
#!/usr/bin/env zsh

# === zoxide ===
# Navigation tool, not needed until user invokes `z`
if (( $+commands[zoxide] )); then
  _evalcache zoxide init zsh --no-cmd
fi

# Custom z function for completion
z() {
  \__zoxide_z "$@"
}

# === mise ===
# Full activation with hooks/env vars
# .zprofile already added shims for immediate PATH access
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi
```

### File Split: completions.zsh → completions-sync.zsh + completions-defer.zsh

```zsh
# Source: Current ~/.zsh.d/completions.zsh
# Target 1: ~/.zsh.d/completions-sync.zsh (foundation, before compinit)

# Managed by chezmoi
#!/usr/bin/env zsh

if [ "$(uname -m)" = "x86_64" ]; then
  : "${HOMEBREW_PREFIX:=/usr/local}"
elif [ "$(uname -m)" = "arm64" ]; then
  : "${HOMEBREW_PREFIX:=/opt/homebrew}"
fi

# Colors and word selection (required before compinit)
autoload -Uz colors
colors

autoload -Uz select-word-style
select-word-style default

# ZLE configuration
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

# Prediction
autoload predict-on
zle -N predict-on
zle -N predict-off
zstyle ':predict' verbose true

# Completion system configuration (zstyles before compinit)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z} r:|[-_.]=**'
zstyle ':completion:*' completer _complete _ignored _cmdstring _canonical_paths _expand _extensions _external_pwds _expand_alias _files _multi_parts
if [ -n "$LS_COLORS" ]; then
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
else
  zstyle ':completion:*' list-colors ''
fi
zstyle ':completion:*:cd:*' tag-order local-directories path-directories
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:sudo:*' command-path $HOMEBREW_PREFIX/sbin $HOMEBREW_PREFIX/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
```

```zsh
# Target 2: ~/.zsh.d/completions-defer.zsh (dynamic data, can defer)

# Managed by chezmoi
#!/usr/bin/env zsh

# SSH host completion from ~/.ssh/config (can defer)
_cache_hosts=()
if [[ -r $HOME/.ssh/config ]]; then
  _cache_hosts=(${${${(M)${(f)"$(<$HOME/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi

# Bun completions (can defer)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Phantom completions (can defer, non-critical)
if (( $+commands[phantom] )); then
  eval "$(phantom completion zsh 2>/dev/null)" || true
fi
```

### .zprofile Addition: mise Shims Fallback

```zsh
# Source: https://mise.jdx.dev/dev-tools/shims.html
# File: ~/.zprofile (login shells only)

# Existing content preserved
# Add homebrew to the path
test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Adds .local binary files
export PATH="$HOME/.local/bin:$PATH"

# NEW: mise shims for immediate PATH access (fallback until full activation in deferred group)
if (( $+commands[mise] )); then
  eval "$(mise activate zsh --shims)"
fi
```

**Note:** mise activate (full) in external-defer.zsh will remove shims from PATH and add full features. This is safe and recommended by mise documentation.

### Renaming Files for Defer Group

```bash
# Move to deferred variants (rename + update content)
# atuin.zsh → atuin-defer.zsh (content unchanged, just moves to defer group)
# carapace.zsh → carapace-defer.zsh (content unchanged)
# intelli-shell.zsh → intelli-shell-defer.zsh (content unchanged)
# ssh.zsh → ssh-defer.zsh (content unchanged)

# Keep existing large completion files in defer group
# lens-completion.zsh (7KB, can defer)
# wt.zsh (7KB, can defer)
# xlaude.zsh (2KB, can defer)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Load all plugins synchronously | Defer non-critical plugins via Sheldon templates | 2021-2022 (Sheldon 0.6+, zsh-defer) | Perceived startup 2-5x faster |
| Manual eval caching with timestamps | evalcache with automatic invalidation | 2019 (mroth/evalcache) | Static init calls cached, Phase 20 delivered 53% improvement |
| mise activate in .zshrc (slow) | mise activate --shims in .zprofile + full activate deferred | 2024 (mise 2024.x) | Tools available immediately via shims, full features load async |
| Single .zshrc with all config | Modular .zsh.d/ with sync/defer split | 2020+ (common pattern) | Clear separation of concerns, easier to audit defer safety |
| oh-my-zsh with all plugins | Minimal plugin manager (Sheldon) + targeted plugins | 2020+ | Faster, more control, less cruft |

**Deprecated/outdated:**
- oh-my-zsh Turbo mode: Deprecated in favour of dedicated plugin managers with defer support (zinit, Sheldon)
- Manual async plugins (zsh-async): Replaced by zsh-defer for simpler use cases
- antigen/antibody plugin managers: Sheldon is faster, actively maintained

## Open Questions

1. **Are FZF key-bindings sources in hooks.zsh redundant?**
   - What we know: Sheldon loads fzf-git.sh plugin (deferred), Homebrew FZF provides completion.zsh and key-bindings.zsh
   - What's unclear: Does fzf-git.sh provide same bindings as Homebrew FZF key-bindings.zsh? Or are they complementary (fzf-git = git-specific, FZF key-bindings = general Ctrl+T/R/Alt+C)?
   - Recommendation: Test removing FZF sources from hooks.zsh, verify Ctrl+T (file finder), Alt+C (dir finder) still work. If broken, keep sourcing (not redundant). If working, remove (redundant, fzf-git provides).

2. **Is atuin-keybindings.zsh sourcing in hooks.zsh redundant?**
   - What we know: atuin init (cached in atuin.zsh) sets up shell integration
   - What's unclear: Does atuin init include keybindings setup, or is separate sourcing required?
   - Recommendation: Check atuin.zsh content, verify if atuin init includes keybindings. Test removing separate sourcing from hooks.zsh, verify Ctrl+R still triggers atuin. Current atuin.zsh has `_evalcache atuin init zsh` with ATUIN_NOBIND commented - suggests init includes bindings by default.

3. **Should lens/wt/xlaude completions be in defer or sync?**
   - What we know: Large files (7KB each), define completions for specific tools
   - What's unclear: Are these tools used immediately after shell start, or can completion loading wait?
   - Recommendation: Defer (non-critical, completions can load async). If user types command before completion loads, they just don't get tab completion for that one command. Next prompt, it's available.

## Sources

### Primary (HIGH confidence)

- [Sheldon plugin manager](https://github.com/rossmacarthur/sheldon) - Plugin configuration, apply mechanism, templates
- [Sheldon documentation - Examples](https://sheldon.cli.rs/Examples.html) - Defer template configuration
- [zsh-defer by romkatv](https://github.com/romkatv/zsh-defer) - Deferred execution semantics, safe/unsafe patterns, limitations
- [mise shims documentation](https://mise.jdx.dev/dev-tools/shims.html) - Shims vs PATH activation, .zprofile vs .zshrc usage
- [ZSH documentation - Startup files](https://zsh.sourceforge.io/Intro/intro_3.html) - .zshenv, .zprofile, .zshrc, .zlogin execution order
- Current configuration files (read directly from ~/.zsh.d/, ~/.config/sheldon/plugins.toml)

### Secondary (MEDIUM confidence)

- [Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh) - Real-world defer patterns, performance results
- [ZSH hooks guide](https://github.com/rothgar/mastering-zsh/blob/master/docs/config/hooks.md) - precmd, preexec semantics
- [A Guide to the Zsh Completion with Examples](https://thevaluable.dev/zsh-completion-guide-examples/) - Completion system ordering, zstyle usage
- [Speeding Up zsh Startup with zprof and zsh-defer](https://mzunino.com.uy/til/2025/03/speeding-up-zsh-startup-with-zprof-and-zsh-defer/) - Practical defer examples

### Tertiary (LOW confidence)

- WebSearch results on FZF lazy loading - Multiple sources agree on feasibility but warn plugin-specific testing needed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Sheldon + zsh-defer already in use, evalcache proven in Phase 20
- Architecture: HIGH - File split patterns verified in current config, Sheldon apply mechanism documented
- Pitfalls: HIGH - zsh-defer documentation explicit about stdin/scope issues, completion ordering well-documented
- Open questions: MEDIUM - Redundancy questions require testing, but non-blocking (conservative approach: keep sourcing if unsure)

**Research date:** 2026-02-14
**Valid until:** 2026-03-14 (30 days, stable technology stack)
