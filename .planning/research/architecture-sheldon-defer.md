# Architecture Research: Sheldon + zsh-defer Integration

**Domain:** ZSH startup performance optimisation
**Researched:** 2026-02-14
**Overall confidence:** HIGH (based on source code analysis + official docs + community patterns)

---

## 1. Sheldon Plugin Loading Model

### How `eval "$(sheldon source)"` Works

**Confidence: HIGH** (official docs + source analysis)

Sheldon's `source` command generates a single shell script string containing all plugin
loading instructions. The flow is:

1. Sheldon checks for an up-to-date lock file (`$XDG_DATA_HOME/sheldon/plugins.lock`)
2. If lock file is stale or missing, it runs `sheldon lock` first (re-resolves plugins)
3. It reads the lock file and generates shell code by applying templates to each plugin
4. The generated script is printed to stdout
5. `eval` executes this script in the current shell

**Key insight:** Sheldon itself is a Rust binary. The `eval "$(sheldon source)"` call
forks a process, waits for it, captures stdout, then evals. This fork + exec + template
rendering adds measurable overhead (~20-40ms depending on system).

### Lock File Mechanism

The lock file (`plugins.lock`) stores:
- Resolved plugin directories
- Matched file paths from `use` globs
- Plugin metadata

Sheldon `source` verifies that locked directories and filenames still exist. If they do
not, `sheldon lock` is re-run automatically. This means `sheldon source` is idempotent
but has a filesystem check cost on every shell startup.

### Template System

Templates are Jinja2-like strings with these variables:

| Variable | Type | Description |
|----------|------|-------------|
| `{{ name }}` | string | Plugin name from config |
| `{{ dir }}` | string | Plugin install directory |
| `files` | list | Matched files (iterable) |
| `{{ hooks?.pre \| nl }}` | string | Pre-hook commands (optional) |
| `{{ hooks?.post \| nl }}` | string | Post-hook commands (optional) |

**Built-in templates (zsh):**
- `source` -- `{% for file in files %}source "{{ file }}"\n{% endfor %}`
- `PATH` -- `export PATH="{{ dir }}:$PATH"`
- `path` -- `path=( "{{ dir }}" $path )`
- `fpath` -- `fpath=( "{{ dir }}" $fpath )`

**Current defer template:**
```
{{ hooks?.pre | nl }}{% for file in files %}zsh-defer source "{{ file }}"
{% endfor %}{{ hooks?.post | nl }}
```

This wraps each file in `zsh-defer source "..."` instead of plain `source "..."`.

### Execution Order

Plugins are processed in the order they appear in `plugins.toml`. This is critical:

```
1. zsh-defer        -- SYNC (must load first, provides zsh-defer function)
2. compinit         -- SYNC (inline, runs compinit with daily cache check)
3. fzf-tab          -- DEFERRED
4. fzf-git          -- DEFERRED
5. zsh-syntax-highlighting -- DEFERRED
6. zsh-autosuggestions     -- DEFERRED
7. zsh-sdkman-p     -- DEFERRED
8. zsh-sdkman-m     -- DEFERRED
9. zsh-abbr         -- DEFERRED
10. ohmyzsh plugins -- DEFERRED
11. dotfiles (~/.zsh.d/*.zsh)         -- SYNC
12. dotfiles-private (~/.zsh.d.private/*.zsh) -- SYNC
```

**Problem:** Plugins 11 and 12 (dotfiles) are synchronous. These contain eval
statements (`oh-my-posh init`, `mise activate`, `atuin init`, `zoxide init`,
`carapace _carapace`, `intelli-shell init`) that are expensive. They are the
primary remaining bottleneck.

---

## 2. zsh-defer Execution Model

### When Deferred Scripts Run

**Confidence: HIGH** (official README)

Deferred commands execute **after the first prompt is displayed**, when zle (the zsh
line editor) becomes idle and waits for user input. The flow:

```
.zshrc starts
  |-- sync plugins load (zsh-defer function, compinit, dotfiles)
  |-- deferred commands queued but NOT executed
  \-- .zshrc finishes

prompt appears <-- user sees this immediately

zle becomes idle
  |-- deferred command 1 executes (fzf-tab)
  |-- keyboard input processed if any
  |-- deferred command 2 executes (fzf-git)
  |-- keyboard input processed if any
  |-- ... continues FIFO through queue
  \-- all deferred commands complete
```

**Critical detail:** Between each deferred command, zsh processes any pending keyboard
input. This means the user can start typing immediately, even while plugins are still
loading in the background.

### Options and Flags

| Flag | Default | Effect |
|------|---------|--------|
| `-a` | ON | Invalidate zsh-autosuggestions |
| `-c` | ON | Call `chpwd` hooks |
| `-d` | ON | Call `precmd` hooks |
| `-m` | ON | Call `zle reset-prompt` |
| `-p` | ON | Print output (normally redirected to /dev/null) |
| `-r` | ON | Call `zle -R` |
| `-t N` | 0 | Delay execution by N seconds (supports fractions) |

### Scope and Compatibility Issues

**Confidence: HIGH** (official README)

zsh-defer executes commands in **function scope** with these options set:
- `LOCAL_OPTIONS` -- option changes don't leak
- `LOCAL_PATTERNS` -- pattern changes don't leak
- `LOCAL_TRAPS` -- trap changes don't leak

**This breaks scripts that:**
1. Use `typeset` without `-g` (variables become local to the deferred function)
2. Set global options (e.g., `setopt EXTENDED_GLOB`)
3. Install global traps
4. Read from stdin (not possible from zle)
5. Produce visible output (redirected to /dev/null by default)

### What Can and Cannot Be Deferred

| Category | Can Defer? | Notes |
|----------|-----------|-------|
| Aliases | YES | Simple text substitutions, work fine |
| Functions | YES | Defined with `-g` or in global scope post-source |
| Environment exports | MAYBE | Works if using `export`, fails with plain `typeset` |
| Completions | YES | But must load after compinit |
| Key bindings | YES | `bindkey` works from zle context |
| eval-based inits | MAYBE | Depends on what the eval output does |
| Prompt setup | NO | Must be sync for first prompt |
| PATH modifications | RISKY | Commands typed before defer completes won't find new PATH entries |
| stdin-reading commands | NO | zle context has no stdin |

---

## 3. Integration Strategy: Sheldon Output Caching

### The Problem

`eval "$(sheldon source)"` has two costs:
1. **Fork + exec cost:** ~5-10ms to spawn the sheldon binary
2. **Template rendering:** ~10-30ms for sheldon to read lock file and render templates
3. **Total:** ~20-40ms on every shell startup, even when nothing has changed

### The Solution: Static Cache File

**Confidence: HIGH** (well-established pattern, used by multiple optimised configs)

Cache the output of `sheldon source` to a file and source it directly, bypassing
the fork + exec overhead entirely.

**Implementation pattern:**

```zsh
# Sheldon eval caching
_sheldon_cache="$HOME/.cache/sheldon/sheldon.zsh"
_sheldon_toml="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon/plugins.toml"
_sheldon_lock="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/plugins.lock"

if [[ ! -f "$_sheldon_cache" ]] \
   || [[ "$_sheldon_toml" -nt "$_sheldon_cache" ]] \
   || [[ "$_sheldon_lock" -nt "$_sheldon_cache" ]]; then
  mkdir -p "${_sheldon_cache:h}"
  sheldon source > "$_sheldon_cache"
  zcompile "$_sheldon_cache"
fi
source "$_sheldon_cache"

unset _sheldon_cache _sheldon_toml _sheldon_lock
```

**How it works:**
1. Check if cache exists and is newer than `plugins.toml` AND `plugins.lock`
2. If stale: regenerate by running `sheldon source > cache`, then `zcompile`
3. If fresh: source the cached file directly (no fork, no sheldon binary invocation)

**Expected savings:** 20-40ms (eliminates sheldon binary execution on most startups)

**Invalidation triggers:**
- `plugins.toml` modified (detected by `-nt` test)
- `plugins.lock` modified (detected by `-nt` test, catches `sheldon lock --update`)
- Manual invalidation: `rm ~/.cache/sheldon/sheldon.zsh*`

### zcompile Bonus

`zcompile` pre-compiles the cached shell script into ZSH wordcode format (`.zwc`).
ZSH loads `.zwc` files significantly faster than parsing text. This shaves another
~2-5ms on top of the caching benefit.

---

## 4. Deferring the Dotfiles Plugin Group

### Current State Analysis

The `dotfiles` plugin (`~/.zsh.d/*.zsh`) loads synchronously with `apply = ["source"]`.
It sources 15 files alphabetically:

| File | Sync Required? | Why | Estimated Cost |
|------|---------------|-----|----------------|
| `aliases.zsh` | NO | Pure alias definitions, no side effects | ~1ms |
| `atuin.zsh` | MAYBE | `eval "$(atuin init zsh)"` -- sets up hooks | ~30-50ms |
| `carapace.zsh` | NO | `source <(carapace _carapace)` -- completions | ~20-40ms |
| `completions.zsh` | PARTIAL | zstyle setup (sync) + ruby SSH parse + autoloads | ~15-25ms |
| `external.zsh` | PARTIAL | FZF exports (sync), zoxide init + mise activate (defer) | ~80-120ms |
| `functions.zsh` | NO | Pure function definitions | ~2ms |
| `hooks.zsh` | YES | oh-my-posh init (prompt!), FZF bindings, atuin bindings | ~40-60ms |
| `intelli-shell.zsh` | NO | `eval "$(intelli-shell init zsh)"` | ~10-20ms |
| `keybinds.zsh` | NO | `bindkey` commands, safe to defer | ~1ms |
| `lens-completion.zsh` | NO | Completion function definition | ~1ms |
| `path.zsh.tmpl` | N/A | Empty (PATH moved to .profile) | 0ms |
| `ssh.zsh` | MAYBE | `ssh-add --apple-load-keychain` -- may need early | ~5-10ms |
| `variables.zsh` | PARTIAL | `export` statements -- some needed by deferred plugins | ~1ms |
| `wt.zsh` | NO | Completion function definition | ~1ms |
| `xlaude.zsh` | NO | Completion function definition | ~1ms |

### Classification: Sync vs Defer

**MUST be synchronous (needed before first prompt or for correct operation):**

1. **`hooks.zsh` (partial):** `oh-my-posh init zsh` MUST be sync because it defines
   the prompt. Without it, the first prompt renders incorrectly. However, the FZF
   and zsh-autosuggestions sourcing in hooks.zsh is redundant (already loaded via
   sheldon deferred plugins) and should be removed.

2. **`variables.zsh` (partial):** `ZSH_HIGHLIGHT_MAXLENGTH` must be set before
   zsh-syntax-highlighting loads. Since that plugin is deferred, setting this
   variable synchronously is fine. Other exports like `EDITOR`, `LESS` are safe
   to defer but cheap enough to keep sync.

3. **`completions.zsh` (partial):** The `zstyle` settings must be set before
   completions are used. The SSH `_cache_hosts` ruby command is expensive and
   should be deferred or cached. The `autoload` and `predict-on` setup should
   stay sync.

**Safe to defer entirely:**

4. **`aliases.zsh`** -- Pure alias definitions, zero side effects
5. **`functions.zsh`** -- Pure function definitions
6. **`keybinds.zsh`** -- `bindkey` works from zle context
7. **`lens-completion.zsh`** -- Completion definition
8. **`wt.zsh`** -- Completion definition
9. **`xlaude.zsh`** -- Completion definition
10. **`intelli-shell.zsh`** -- Eval-based init, no prompt dependency

**Should be deferred with care:**

11. **`atuin.zsh`** -- `eval "$(atuin init zsh)"` installs hooks and bindings.
    Can be deferred, but atuin won't be available until defer completes.

12. **`carapace.zsh`** -- `source <(carapace _carapace)` generates completions.
    Safe to defer since compinit runs before it. But uses process substitution,
    which should be cached instead.

13. **`external.zsh`** -- Contains the heaviest evals:
    - `zoxide init zsh` (~10ms) -- can defer
    - `mise activate zsh` (~100-200ms!) -- can defer, but mise-managed tools
      won't be on PATH until it completes
    - FZF exports must be sync (used by deferred plugins)

14. **`ssh.zsh`** -- `ssh-add --apple-load-keychain` can be deferred unless
    you need SSH immediately on shell open.

### Recommended Split Architecture

Rather than switching the entire dotfiles group to `["defer"]`, split into two
plugin entries:

```toml
[plugins.dotfiles-sync]
local = "~/.zsh.d"
use = ["variables.zsh", "completions-sync.zsh", "external-sync.zsh", "prompt.zsh"]
apply = ["source"]

[plugins.dotfiles-defer]
local = "~/.zsh.d"
use = ["aliases.zsh", "functions.zsh", "keybinds.zsh", "ssh.zsh",
       "atuin.zsh", "carapace.zsh", "intelli-shell.zsh",
       "external-defer.zsh", "completions-defer.zsh",
       "lens-completion.zsh", "wt.zsh", "xlaude.zsh"]
apply = ["defer"]
```

**But this is not enough.** The expensive parts are the `eval` calls INSIDE the
sync files. The real win requires refactoring the files themselves.

### Recommended File Refactoring

Split `external.zsh` and `hooks.zsh` into sync and defer portions:

**`external-sync.zsh`** (keep sync -- FZF env vars only):
```zsh
# FZF configuration (needed by deferred fzf-tab)
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# ... other FZF exports and _fzf_compgen functions
```

**`external-defer.zsh`** (new file, defer):
```zsh
# zoxide (use evalcache)
_evalcache zoxide init zsh --no-cmd
z() { \__zoxide_z "$@" }

# mise (use evalcache)
_evalcache mise activate zsh

# FZF key bindings and completion
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
fi
if [ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
fi
```

**`prompt.zsh`** (renamed from hooks.zsh, keep sync -- prompt only):
```zsh
if command -v oh-my-posh > /dev/null; then
  _evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
fi
preexec() { print '' }
```

Remove the redundant sourcing of zsh-autosuggestions and zsh-syntax-highlighting
from `hooks.zsh` -- these are already loaded via sheldon deferred plugins.

---

## 5. Eval Caching for Expensive Init Commands

### The Problem

Several tools use `eval "$(tool init zsh)"` which forks a process on every startup:

| Command | Estimated Cost | Output Changes? |
|---------|---------------|-----------------|
| `oh-my-posh init zsh --config ...` | 40-60ms | Only when config changes |
| `mise activate zsh` | 100-200ms | Only when mise config changes |
| `atuin init zsh` | 30-50ms | Only when atuin updates |
| `zoxide init zsh --no-cmd` | 5-10ms | Only when zoxide updates |
| `carapace _carapace` | 20-40ms | Only when carapace updates |
| `intelli-shell init zsh` | 10-20ms | Only when intelli-shell updates |

**Total eval overhead: ~205-380ms** -- this alone exceeds the 300ms target.

### Solution: evalcache Pattern

**Confidence: HIGH** (mroth/evalcache is widely used, pattern is well-established)

The `evalcache` plugin (or a custom implementation) caches eval output to files:

```zsh
_evalcache() {
  local cmd="$1"; shift
  local cache_dir="${ZSH_EVALCACHE_DIR:-$HOME/.zsh-evalcache}"
  local cache_file="$cache_dir/init-${cmd##*/}-$(echo "$*" | md5).sh"

  if [[ ! -f "$cache_file" ]] || [[ "$(which $cmd)" -nt "$cache_file" ]]; then
    mkdir -p "$cache_dir"
    "$cmd" "$@" > "$cache_file"
    zcompile "$cache_file"
  fi
  source "$cache_file"
}

# Usage:
_evalcache oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json
_evalcache mise activate zsh
_evalcache atuin init zsh
_evalcache zoxide init zsh --no-cmd
```

**Expected savings:** Each cached eval goes from 10-200ms to ~1-2ms (just sourcing
a pre-compiled file). Total savings: ~200-370ms.

**Invalidation:** Cache busts when the binary itself changes (detected by
`which $cmd` modification time being newer than cache file). For config-dependent
commands like oh-my-posh, also check config file mtime.

### evalcache vs Custom Implementation

**Use mroth/evalcache** if you want a drop-in solution -- load it as the first
sheldon plugin (before zsh-defer). It provides `_evalcache` as a function.

**Use a custom implementation** if you want tighter control over invalidation
(e.g., checking config file mtimes for oh-my-posh) or want to avoid an extra
plugin dependency.

**Recommendation:** Start with mroth/evalcache for simplicity, customise later
if cache invalidation proves insufficient.

---

## 6. compinit Optimisation

### Current Implementation

The current `compinit` in `plugins.toml` already implements daily cache checking:

```zsh
if [ ! -f $HOME/.zcompdump ]; then
  autoload -Uz compinit && compinit
elif [ $((now - updated)) -gt $((60*60*24)) ]; then
  autoload -Uz compinit && compinit
else
  autoload -Uz compinit && compinit -C
fi
```

The `-C` flag skips security checks on the dump file, which is the main saving.

### Can compinit Be Deferred?

**Confidence: HIGH** (verified from zsh-defer docs and community experience)

**YES, but with trade-offs:**

- Tab completion will NOT work until compinit finishes (after first prompt)
- In practice, the delay is imperceptible because:
  1. compinit with `-C` takes only ~15-30ms
  2. zsh-defer processes it before the user can type a command and press Tab
  3. There is typically >200ms between prompt appearing and user pressing Tab

**Recommendation:** Keep compinit synchronous with `-C` always. The cost (~15ms)
is small and avoiding any completion availability delay is worth it. Simplify the
current implementation to always use `-C` and defer the full daily rebuild to a
background job or chezmoi hook.

Simplified compinit:
```toml
[plugins.compinit]
inline = 'autoload -Uz compinit && compinit -C'
```

### Correct Ordering for Completion Stack

**Confidence: MEDIUM** (fzf-tab docs are clear, carapace ordering less documented)

The required ordering is:

```
1. compinit          -- initialises the completion system
2. zstyle settings   -- configures completion behaviour
3. carapace          -- registers its completions with the system
4. fzf-tab           -- hooks into the completion widget (must be after compinit)
5. other completions -- lens, wt, xlaude, bun, phantom
```

**Critical constraint from fzf-tab README:** "fzf-tab needs to be loaded after
compinit, but before plugins which will wrap widgets, such as zsh-autosuggestions
or fast-syntax-highlighting."

**Current state is correct** for the sheldon ordering: compinit (sync) -> fzf-tab
(deferred, first in queue) -> zsh-syntax-highlighting (deferred, later in queue).

If compinit were deferred, it must be the FIRST deferred command in the queue (which
it already is by position in plugins.toml). fzf-tab (next in queue) would execute
after compinit completes, maintaining correct ordering.

**Carapace note:** Currently in `carapace.zsh` (dotfiles, sync), it runs
`source <(carapace _carapace)`. If dotfiles are deferred, carapace would need to
run after compinit but the FIFO ordering of zsh-defer handles this naturally,
provided carapace's deferred execution comes after compinit's.

---

## 7. Redundancy Analysis

### Duplicate Plugin Loading in hooks.zsh

`hooks.zsh` currently sources:
```zsh
source "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
```

But these are ALREADY loaded by sheldon via:
```toml
[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"
apply = ["defer"]

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
apply = ["defer"]
```

**This means these plugins are loaded TWICE** -- once via sheldon (deferred, from
GitHub clone) and once from hooks.zsh (sync, from Homebrew). The Homebrew versions
in hooks.zsh are synchronous, adding ~20-40ms unnecessarily.

**Fix:** Remove the Homebrew sourcing from hooks.zsh entirely.

### FZF Completion/Bindings Duplication

`hooks.zsh` sources FZF completion and key-bindings from Homebrew. These should
be moved to a defer-safe file since they don't affect the first prompt.

---

## 8. Proposed Architecture

### Startup Flow (Target)

```
.zshrc starts (~2ms)
  |
  +-- source ~/.profile (PATH, env vars -- already done, ~5ms)
  |
  +-- source cached sheldon output (~3ms instead of eval "$(sheldon source)" ~30ms)
  |     |
  |     +-- [SYNC] zsh-defer loaded (~1ms)
  |     +-- [SYNC] evalcache loaded (~1ms)
  |     +-- [SYNC] compinit -C (~15ms)
  |     +-- [QUEUE] fzf-tab
  |     +-- [QUEUE] fzf-git
  |     +-- [QUEUE] zsh-syntax-highlighting
  |     +-- [QUEUE] zsh-autosuggestions
  |     +-- [QUEUE] ohmyzsh plugins
  |     +-- [SYNC] dotfiles-sync (FZF exports, zstyles, oh-my-posh cached)
  |     +-- [QUEUE] dotfiles-defer (aliases, functions, evals...)
  |     \-- [QUEUE] dotfiles-private
  |
  \-- prompt appears (~33ms total)
        |
        +-- [DEFER] fzf-tab loads
        +-- [DEFER] syntax highlighting loads
        +-- [DEFER] autosuggestions loads
        +-- [DEFER] aliases, functions, keybinds load
        +-- [DEFER] cached evals: zoxide, mise, atuin, carapace
        \-- [DEFER] completion definitions: lens, wt, xlaude
```

### Expected Time Budget

| Component | Current (est.) | Optimised (est.) |
|-----------|---------------|-----------------|
| .profile (PATH, exports) | 5ms | 5ms |
| `eval "$(sheldon source)"` | 30ms | 3ms (cached + zcompiled) |
| compinit -C | 15ms | 15ms |
| oh-my-posh init | 50ms | 2ms (evalcached) |
| FZF exports | 1ms | 1ms |
| zstyle setup | 2ms | 2ms |
| mise activate | 150ms | 0ms (deferred + evalcached) |
| zoxide init | 10ms | 0ms (deferred + evalcached) |
| atuin init | 40ms | 0ms (deferred + evalcached) |
| Duplicate plugin loads | 30ms | 0ms (removed) |
| Other sync overhead | 10ms | 5ms |
| **Total sync (before prompt)** | **~343ms** | **~33ms** |
| **Deferred (after prompt)** | **~540ms** | **~200ms** |

### plugins.toml Target Structure

```toml
shell = "zsh"
apply = ["source"]

[plugins.zsh-defer]
github = "romkatv/zsh-defer"

[plugins.evalcache]
github = "mroth/evalcache"

[templates]
defer = "{{ hooks?.pre | nl }}{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}{{ hooks?.post | nl }}"

[plugins.compinit]
inline = 'autoload -Uz compinit && compinit -C'

[plugins.fzf-tab]
github = "Aloxaf/fzf-tab"
apply = ["defer"]

[plugins.fzf-git]
github = "junegunn/fzf-git.sh"
apply = ["defer"]

[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"
apply = ["defer"]

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
apply = ["defer"]

[plugins.zsh-sdkman-p]
github = "ptavares/zsh-sdkman"
apply = ["defer"]

[plugins.zsh-sdkman-m]
github = "matthieusb/zsh-sdkman"
apply = ["defer"]

[plugins.zsh-abbr]
local = "/opt/homebrew/share/zsh-abbr"
use = ["zsh-abbr.zsh"]
apply = ["defer"]

[plugins.ohmyzsh]
github = "ohmyzsh/ohmyzsh"
dir = "plugins"
use = ["{gitfast,zoxide,kubectl,gcloud,mvn,macos}/*.plugin.zsh"]
apply = ["defer"]

# Sync dotfiles: only what MUST run before first prompt
[plugins.dotfiles-sync]
local = "~/.zsh.d"
use = ["variables.zsh", "completions-sync.zsh", "external-sync.zsh", "prompt.zsh"]
apply = ["source"]

# Deferred dotfiles: everything else
[plugins.dotfiles-defer]
local = "~/.zsh.d"
use = ["aliases.zsh", "functions.zsh", "keybinds.zsh", "ssh.zsh",
       "atuin.zsh", "carapace.zsh", "intelli-shell.zsh",
       "external-defer.zsh", "completions-defer.zsh",
       "lens-completion.zsh", "wt.zsh", "xlaude.zsh"]
apply = ["defer"]

[plugins.dotfiles-private]
local = "~/.zsh.d.private"
use = ["*.zsh"]
apply = ["defer"]
```

---

## 9. Open Questions and Risks

### mise activate Deferral Risk

**Risk: MEDIUM**

When `mise activate zsh` is deferred, mise-managed tool shims are not on PATH until
the defer completes. If a user types a command immediately after the prompt appears
(within ~100ms), a mise-managed tool might not be found.

**Mitigation:** mise supports `mise activate --shims` which adds a shims directory
to PATH synchronously (cheap) but loses the hook-based automatic version switching.
An acceptable trade-off might be: sync PATH addition via `--shims` + deferred hook
activation. Alternatively, add mise shims to PATH in `.profile` and defer only the
hook activation.

### oh-my-posh Caching Validity

**Risk: LOW**

oh-my-posh output depends on the config file. The evalcache invalidates when the
binary changes, but NOT when the config file changes. Need to either:
1. Extend evalcache to check config file mtime
2. Use a custom caching wrapper for oh-my-posh
3. Accept manual cache clearing when config changes (`_evalcache_clear`)

### completions.zsh Ruby SSH Parsing

**Risk: LOW but notable**

```zsh
_cache_hosts=(`ruby -ne 'if /^Host\s+(.+)$/; print $1.strip, "\n"; end' $HOME/.ssh/config`)
```

This forks Ruby on every shell startup (~15ms). Replace with pure-zsh:
```zsh
_cache_hosts=(${${${(M)${(f)"$(< ~/.ssh/config)"}:#Host *}#Host }// /
})
```

### atuin Keybindings Source in hooks.zsh

`hooks.zsh` sources `$XDG_CONFIG_HOME/atuin/atuin-keybindings.zsh` synchronously.
This file likely sets up key bindings that could be deferred, but needs verification
that it doesn't conflict with the deferred `atuin init zsh` from `atuin.zsh`.

### Sheldon `use` Glob with Explicit File Lists

When splitting dotfiles into `dotfiles-sync` and `dotfiles-defer`, the `use` field
must list specific filenames rather than `*.zsh`. Verify that sheldon supports
multiple `use` entries with explicit names and that the files are sourced in the
order listed (not alphabetically).

**Needs validation:** Does sheldon respect `use` array ordering, or does it sort
matched files alphabetically? If alphabetical, the sync/defer split still works
but the file naming must ensure correct ordering within each group.

---

## 10. Implementation Priority

Based on estimated savings, implement in this order:

| Priority | Change | Estimated Saving | Risk |
|----------|--------|-----------------|------|
| 1 | Remove duplicate plugin loads from hooks.zsh | 30ms | LOW |
| 2 | Add evalcache for oh-my-posh (sync, prompt) | 48ms | LOW |
| 3 | Sheldon output caching in .zshrc | 27ms | LOW |
| 4 | Defer + evalcache: mise, zoxide, atuin, carapace | 200ms | MEDIUM |
| 5 | Split dotfiles into sync/defer groups | 15ms | MEDIUM |
| 6 | Replace Ruby SSH parsing with pure-zsh | 15ms | LOW |
| 7 | Simplify compinit to always use -C | 5ms | LOW |
| **Total** | | **~340ms** | |

Steps 1-3 are low-risk and should bring startup from ~343ms to ~238ms.
Steps 4-5 should bring it well under the 300ms target to ~33ms sync time.

---

## Sources

- [Sheldon documentation](https://sheldon.cli.rs/Configuration.html) -- template system, lock file mechanism, CLI (HIGH confidence)
- [Sheldon examples](https://sheldon.cli.rs/Examples.html) -- defer template pattern (HIGH confidence)
- [zsh-defer README](https://github.com/romkatv/zsh-defer) -- execution model, options, limitations (HIGH confidence)
- [evalcache plugin](https://github.com/mroth/evalcache) -- eval caching pattern and implementation (HIGH confidence)
- [fzf-tab README](https://github.com/Aloxaf/fzf-tab) -- loading order requirements (HIGH confidence)
- [Sheldon caching technique](https://zenn.dev/fuzmare/articles/zsh-plugin-manager-cache) -- static cache + zcompile pattern (MEDIUM confidence)
- [Speeding up zsh with zsh-defer](https://mzunino.com.uy/til/2025/03/speeding-up-zsh-startup-with-zprof-and-zsh-defer/) -- practical deferred compinit (MEDIUM confidence)
- [mise activate performance discussion](https://github.com/jdx/mise/discussions/4821) -- 100-200ms delay confirmed (MEDIUM confidence)
- [carapace + fzf-tab interaction](https://github.com/orgs/carapace-sh/discussions/2596) -- ordering considerations (MEDIUM confidence)
- [Shell completion caching](https://raoulcoutard.com/posts/2026-02-04-shell-completion-caching-en/) -- completion caching strategies (MEDIUM confidence)
