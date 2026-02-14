# Pitfalls: ZSH Lazy Loading and Deferral

**Domain:** ZSH dotfiles performance optimisation (0.87s -> <300ms target)
**Researched:** 2026-02-14
**Overall confidence:** HIGH (based on zsh-defer documentation, community reports, and analysis of current config)

---

## Critical Pitfalls

These will cause visible breakage or silent misbehaviour if not handled correctly.

### 1. Double-Loading of zsh-autosuggestions and zsh-syntax-highlighting

**What goes wrong:** Both plugins are loaded TWICE -- once via Sheldon's deferred plugins and once synchronously in `hooks.zsh` (lines 19-20). This means:
- The synchronous load negates the performance benefit of deferring
- The deferred load then re-initialises the plugin, potentially resetting configuration
- zsh-syntax-highlighting is particularly sensitive: loading it twice can cause widget-wrapping conflicts

**Current code in `hooks.zsh`:**
```zsh
# Line 19 - synchronous load from Homebrew
if [ -r "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/..." ]; then source ...; fi
# Line 20 - synchronous load from Homebrew
if [ -r "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/..." ]; then source ...; fi
```

**And in `plugins.toml`:**
```toml
[plugins.zsh-syntax-highlighting]
github = "zsh-users/zsh-syntax-highlighting"
apply = ["defer"]

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"
apply = ["defer"]
```

**Consequences:**
- ~50-100ms wasted on redundant synchronous loading
- Potential widget conflicts (zsh-syntax-highlighting wraps ZLE widgets; doing it twice is undefined)
- ZSH_HIGHLIGHT_MAXLENGTH and other config may be set between loads, causing inconsistent state

**Prevention:**
- Remove the synchronous sources from `hooks.zsh` entirely
- Keep ONLY the Sheldon deferred versions
- If you need them synchronous (e.g. for immediate syntax highlighting), remove from Sheldon and keep only the Homebrew source

**Detection:** Run `zsh -xc exit 2>&1 | grep -c "zsh-autosuggestions.zsh"` -- if it shows 2, you have double loading.

**Confidence:** HIGH -- directly observed in the codebase.

---

### 2. fzf-tab Must Load AFTER compinit but BEFORE Widget-Wrapping Plugins

**What goes wrong:** fzf-tab hooks into the ZSH completion system and must be sourced after `compinit` runs. It also must load before plugins that wrap ZLE widgets (zsh-autosuggestions, zsh-syntax-highlighting). The current Sheldon config defers fzf-tab, which creates a timing dependency.

**Current ordering in `plugins.toml`:**
```
1. zsh-defer (sync)
2. compinit (sync, inline)
3. fzf-tab (DEFERRED)
4. fzf-git (deferred)
5. zsh-syntax-highlighting (deferred)
6. zsh-autosuggestions (deferred)
7. dotfiles/*.zsh (sync)       <-- carapace.zsh runs here, also needs compinit
```

**The actual execution order is:**
```
SYNC:  zsh-defer -> compinit -> dotfiles/*.zsh (includes carapace, hooks, completions)
DEFER: fzf-tab -> fzf-git -> zsh-syntax-highlighting -> zsh-autosuggestions -> ...
```

This means:
- fzf-tab deferred load happens after compinit (good -- ordering preserved)
- BUT carapace.zsh runs synchronously and calls `source <(carapace _carapace)` which registers completions
- When fzf-tab loads deferred, it may override or conflict with carapace's completion registrations
- Tab completion may be inconsistent for the first few seconds

**The critical ordering requirement from fzf-tab's README:**
> "fzf-tab needs to be loaded after compinit, but before plugins which will wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting."

In the current deferred queue, the order IS correct (fzf-tab before zsh-syntax-highlighting). But the gap between compinit (sync) and fzf-tab (deferred) means that during that gap, standard completion is active without fzf-tab.

**Consequences:**
- Tab completion may not use fzf-tab for the first command typed quickly
- Carapace completions registered synchronously may be partially overridden when fzf-tab loads

**Prevention:**
- Keep fzf-tab synchronous (it is lightweight, ~5ms) -- best approach
- Or accept that tab completion has a brief degraded period
- Ensure carapace loads AFTER fzf-tab if both are deferred

**Confidence:** HIGH -- fzf-tab README explicitly states this ordering requirement.

**Source:** [fzf-tab README](https://github.com/Aloxaf/fzf-tab)

---

### 3. oh-my-posh Deferral Causes Flash of Unstyled Prompt (FOUP)

**What goes wrong:** If `eval "$(oh-my-posh init zsh ...)"` is deferred, the prompt appears as a plain `%` or default PS1 until the deferred command executes. This is visually jarring and makes the terminal feel broken for ~50-200ms.

**Current code in `hooks.zsh`:**
```zsh
if command -v oh-my-posh > /dev/null; then
  eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json)"
fi
```

This runs synchronously via the `[plugins.dotfiles]` block. If moved to deferred loading, the prompt will flash.

**Why this matters for the optimisation project:**
- oh-my-posh init is one of the slower evals (~40-80ms)
- Temptation to defer it is high
- But deferring it creates visible regression that users notice immediately

**Consequences:**
- Plain/broken prompt for the first ~100ms
- Prompt re-renders when deferred init completes, causing visual jump
- If user types during this window, prompt may redraw mid-typing

**Prevention strategies (ordered by recommendation):**

1. **Cache the oh-my-posh init output** -- run `oh-my-posh init zsh --config ...` once, save to a file, source the file on startup. Invalidate when config or binary changes.
   ```zsh
   _omp_cache="$XDG_CACHE_HOME/oh-my-posh-init.zsh"
   if [[ ! -f "$_omp_cache" ]] || [[ ~/.config/oh-my-posh.omp.json -nt "$_omp_cache" ]]; then
     oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json > "$_omp_cache"
   fi
   source "$_omp_cache"
   ```

2. **Do NOT defer oh-my-posh** -- keep it synchronous but cached.

3. **Set a temporary PS1** before deferring to reduce visual disruption (still not recommended -- the jump when the real prompt loads is noticeable).

**Note:** Powerlevel10k solved this with "instant prompt" (renders a cached prompt image immediately). oh-my-posh has no equivalent feature.

**Confidence:** HIGH -- this is a well-known issue with any prompt theme that requires init.

---

### 4. mise Deferral Breaks Tool Availability During Startup

**What goes wrong:** `eval "$(mise activate zsh)"` modifies PATH to include mise-managed tool versions. If deferred, any tool managed by mise (node, python, java, etc.) will not be on PATH when other startup scripts run or when the user types their first command quickly.

**Current code in `external.zsh`:**
```zsh
eval "$(mise activate zsh)"
```

**Specific breakage scenarios:**
- `completions.zsh` runs `command -v phantom > /dev/null` -- if phantom is mise-managed, this fails
- `hooks.zsh` calls tools that may depend on mise-managed runtimes
- User types `node --version` as first command -- gets "command not found"
- Scripts in `~/.zsh.d.private/*.zsh` may depend on mise-managed tools

**Additional subtlety:** mise activate installs a `precmd` hook that updates PATH on every prompt. If deferred, this hook is not installed until after the first prompt, meaning the first command runs without mise-managed tools.

**Performance impact:** Users report 100-200ms from `eval "$(mise activate zsh)"` alone.

**Prevention (officially recommended approach):**

1. **Use `mise activate --shims` in `.zprofile`** (non-interactive, one-time PATH setup) combined with `mise activate zsh` in `.zshrc` (interactive, removes shims from PATH and uses real paths):
   ```zsh
   # .zprofile -- runs once per login shell
   eval "$(mise activate --shims)"

   # .zshrc -- can be deferred since shims already provide fallback PATH
   zsh-defer eval "$(mise activate zsh)"
   ```
   This way, shims ensure tools are always available (even before deferred activate runs), while the full activate provides per-directory version switching.

2. **Cache the mise activate output** -- but beware: mise's output changes per-directory (it is context-aware), so caching is less straightforward than for static tools.

3. **Keep synchronous but cached** -- use evalcache or similar for the static parts.

**Confidence:** HIGH -- mise documentation explicitly discusses shims vs activate tradeoffs.

**Sources:**
- [mise shims documentation](https://mise.jdx.dev/dev-tools/shims.html)
- [mise activate documentation](https://mise.jdx.dev/cli/activate.html)
- [mise Discussion #4821](https://github.com/jdx/mise/discussions/4821) -- 100-200ms delay reported

---

### 5. zsh-defer Function Scope Breaks typeset and Options

**What goes wrong:** zsh-defer executes commands in function scope with `LOCAL_OPTIONS`, `LOCAL_PATTERNS`, and `LOCAL_TRAPS` set. This means:
- `typeset` without `-g` creates local variables (invisible outside the deferred function)
- `setopt` changes revert after the deferred function returns
- Traps installed by deferred scripts are removed after execution

**Concrete examples in this codebase:**

- If `completions.zsh` were deferred, the `zstyle` calls would work (they are global), but `autoload -Uz colors; colors` would load colour variables locally -- they would vanish after the deferred function returns
- If `variables.zsh` were deferred, `export` commands would work (export implies global), but any plain `typeset` would be local
- If `keybinds.zsh` were deferred, `bindkey` commands would work (they modify the global keymap)

**What is safe to defer:**
| Operation | Safe? | Why |
|-----------|-------|-----|
| `export VAR=value` | Yes | export is always global |
| `bindkey` | Yes | modifies global ZLE keymap |
| `zstyle` | Yes | modifies global style database |
| `alias` | Yes | aliases are global |
| `source <(tool init)` | Depends | depends on what the init script does internally |
| `typeset VAR=value` (no -g) | **NO** | creates local variable |
| `setopt`/`unsetopt` | **NO** | reverts when deferred function returns |
| `trap` | **NO** | removed when deferred function returns |
| stdin-reading commands | **NO** | zsh-defer cannot provide stdin |

**Prevention:**
- Audit every file before deferring it
- Test with: `zsh-defer -c 'source file.zsh'; echo $EXPECTED_VAR` to verify globals survive
- Use `typeset -g` explicitly in any script that may be deferred
- Check for `setopt` calls in init scripts -- these will silently fail when deferred

**Confidence:** HIGH -- documented in zsh-defer README.

**Source:** [zsh-defer README](https://github.com/romkatv/zsh-defer)

---

## Moderate Pitfalls

### 6. carapace Completion Timing and compinit Dependency

**What goes wrong:** `carapace.zsh` runs `source <(carapace _carapace)` synchronously (via `[plugins.dotfiles]`). This works because compinit has already run. However, if carapace is moved to deferred loading:
- It must still run after compinit
- Other completion sources (bun, phantom from `completions.zsh`) may conflict
- Tab pressing before carapace loads will use incomplete completions

**Current behaviour:** Works correctly because the ordering is: compinit (sync) -> carapace.zsh (sync via dotfiles).

**Prevention:**
- If optimising carapace, cache `carapace _carapace` output to a file instead of using process substitution
- Do NOT defer carapace unless you accept degraded first-command completions
- If deferring, ensure it runs after compinit and after fzf-tab

**Confidence:** HIGH -- carapace documentation states compinit must run first.

**Source:** [carapace setup docs](https://carapace-sh.github.io/carapace-bin/setup.html)

---

### 7. ssh-add Deferral Causes First Git Operation to Prompt

**What goes wrong:** `ssh.zsh` runs `ssh-add --apple-load-keychain` synchronously. This loads SSH keys from macOS Keychain into the agent. If deferred:
- First `git push/pull/clone` over SSH will prompt for passphrase
- Any script that runs git commands during startup will fail silently or hang

**Current code:**
```zsh
ssh-add --apple-load-keychain &> /dev/null
```

**Performance impact:** This command takes ~10-30ms. Deferring saves little but risks annoying passphrase prompts.

**Prevention options (ordered by recommendation):**

1. **macOS LaunchAgent** -- run ssh-add at login, not shell startup:
   ```xml
   <!-- ~/Library/LaunchAgents/com.user.ssh-add.plist -->
   <plist version="1.0">
     <dict>
       <key>Label</key>
       <string>com.user.ssh-add</string>
       <key>ProgramArguments</key>
       <array>
         <string>ssh-add</string>
         <string>--apple-load-keychain</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
     </dict>
   </plist>
   ```
   This runs once at macOS login, not per-shell. Best approach.

2. **SSH config** -- add `UseKeychain yes` and `AddKeysToAgent yes` to `~/.ssh/config`. Keys are loaded on first use and cached by the agent.

3. **Defer with zsh-defer** -- acceptable if you do not use SSH in the first ~200ms. Most users will not notice.

**Confidence:** HIGH -- standard macOS SSH behaviour.

---

### 8. Eval Cache Staleness After Tool Upgrades

**What goes wrong:** Caching `eval "$(tool init zsh)"` output to a file is the primary optimisation strategy. But the cached output becomes stale when:
- The tool is upgraded (e.g. `brew upgrade oh-my-posh`)
- The tool's configuration changes
- ZSH is upgraded (init scripts may reference ZSH internals)

**Staleness scenarios by tool:**

| Tool | Init changes on upgrade? | Config-dependent? | Risk level |
|------|--------------------------|-------------------|------------|
| oh-my-posh | Rarely | Yes (theme file) | Low |
| mise | Sometimes (hook changes) | Yes (per-directory) | **High** |
| atuin | Rarely | No | Low |
| zoxide | Rarely | No | Low |
| carapace | Sometimes (new completions) | Yes (bridges config) | Medium |
| intelli-shell | Rarely | No | Low |

**Consequences of stale cache:**
- Missing new features from upgraded tools
- Broken hooks if internal API changed
- Subtle bugs where old init code conflicts with new binary

**Prevention:**

1. **Key the cache on binary mtime** (recommended -- fast and reliable):
   ```zsh
   _bin=$(command -v oh-my-posh)
   _cache="$XDG_CACHE_HOME/eval-cache/oh-my-posh.zsh"
   if [[ ! -f "$_cache" ]] || [[ "$_bin" -nt "$_cache" ]]; then
     mkdir -p "${_cache:h}"
     oh-my-posh init zsh --config ~/.config/oh-my-posh.omp.json > "$_cache"
   fi
   source "$_cache"
   ```

2. **Key on binary version** (slower but more explicit):
   ```zsh
   _tool_version=$(oh-my-posh version 2>/dev/null)
   _cache_file="$XDG_CACHE_HOME/eval-cache/oh-my-posh-${_tool_version}.zsh"
   if [[ ! -f "$_cache_file" ]]; then
     oh-my-posh init zsh --config ... > "$_cache_file"
   fi
   source "$_cache_file"
   ```

3. **Use zsh-smartcache** instead of evalcache -- it auto-detects staleness and regenerates.

**Why NOT evalcache (`mroth/evalcache`):** It never auto-invalidates. You must manually run `_evalcache_clear` after every tool upgrade. This is a maintenance footgun.

**Confidence:** MEDIUM -- behaviour varies by tool; invalidation strategies are well-documented but tool-specific staleness patterns are based on community reports.

**Sources:**
- [evalcache](https://github.com/mroth/evalcache)
- [zsh-smartcache](https://github.com/QuarticCat/zsh-smartcache)

---

### 9. Atuin Init Overwrites Key Bindings

**What goes wrong:** `atuin init zsh` registers keybindings for history search (Ctrl+R, Up arrow, etc.). If atuin is deferred but `keybinds.zsh` runs synchronously, the synchronous keybindings are set first, then atuin overwrites them when the deferred init runs. Conversely, if keybinds.zsh is deferred after atuin, the custom keybindings override atuin's.

**Current setup:**
- `atuin.zsh` runs synchronously: `eval "$(atuin init zsh)"`
- `hooks.zsh` sources `atuin-keybindings.zsh` synchronously
- `keybinds.zsh` sets `bindkey '^[[A' up-line-or-search` synchronously

**Ordering conflict:** Atuin wants to own Up/Down arrows and Ctrl+R. Custom keybindings in `keybinds.zsh` also bind Up/Down. The last one to load wins.

**Prevention:**
- Decide who owns each keybinding and load them in the correct order
- If deferring atuin, ensure its keybindings are applied AFTER `keybinds.zsh`
- Consider `ATUIN_NOBIND=true` (currently commented out in `atuin.zsh`) and manually binding only the keys you want atuin to handle

**Confidence:** HIGH -- keybinding conflicts are deterministic based on load order.

---

### 10. zprof Cannot Profile Deferred Plugins

**What goes wrong:** The standard profiling approach (`zmodload zsh/zprof` at top, `zprof` at bottom of .zshrc) only captures synchronous execution. Deferred plugins run after `.zshrc` completes, so zprof's report will show them as taking 0ms. This makes debugging deferred performance issues extremely difficult.

**Consequences:**
- You think startup is fast because zprof says so, but perceived latency is still high
- Cannot identify which deferred plugin is slow
- Cannot measure the impact of caching vs deferring

**Prevention strategies:**

1. **Use `zsh-bench` instead of zprof** for measuring perceived startup time:
   ```bash
   # Measures time to first prompt AND time to first command responsiveness
   git clone https://github.com/romkatv/zsh-bench
   ./zsh-bench/zsh-bench
   ```

2. **Temporarily make plugins synchronous** to profile them with zprof, then defer once measured.

3. **Add manual timing around deferred blocks:**
   ```zsh
   zsh-defer -c '
     local start=$EPOCHREALTIME
     source expensive-plugin.zsh
     print "plugin loaded in $(( EPOCHREALTIME - start ))s" >&2
   '
   ```

4. **Use `REPORTTIME=0`** in zshrc to see execution time of every command, including deferred inits.

**Confidence:** HIGH -- this is a well-known limitation of zprof.

**Source:** [zsh-bench deferred loading strategies](https://deepwiki.com/romkatv/zsh-bench/7.6-deferred-loading-strategies)

---

## Minor Pitfalls

### 11. Process Substitution in Deferred Context

**What goes wrong:** `source <(carapace _carapace)` uses process substitution. Within zsh-defer, process substitution works correctly, but the subshell for `<()` runs when the defer executes, which means it blocks the deferred queue. If the binary is slow (~20ms for carapace), it delays all subsequent deferred commands.

**Prevention:** Cache the output to a file instead of using process substitution. This also avoids forking a subprocess on every shell startup.

**Confidence:** MEDIUM -- process substitution within zsh-defer is not explicitly documented as problematic, but caching is strictly better.

---

### 12. Sheldon `eval "$(sheldon source)"` is Itself Expensive

**What goes wrong:** `eval "$(sheldon source)"` in `.zshrc` must:
1. Fork a subprocess to run `sheldon source`
2. Sheldon reads `plugins.toml`, resolves all plugins
3. Generates a shell script containing all plugin sources
4. ZSH evaluates the generated script

This takes ~30-50ms. Sheldon supports pre-generation:
```bash
sheldon lock  # generates ~/.config/sheldon/plugins.lock
```

Then in `.zshrc`, use the lock file for faster loading:
```zsh
eval "$(sheldon source)"  # automatically uses lock file if present
```

**Prevention:** Run `sheldon lock` after any changes to `plugins.toml`. Consider adding this to a post-`chezmoi apply` hook.

**Confidence:** MEDIUM -- based on Sheldon documentation; actual timing depends on number of plugins.

**Source:** [Sheldon docs](https://sheldon.cli.rs/Examples.html)

---

### 13. `command -v` Checks Add Up

**What goes wrong:** Multiple files use `command -v TOOL > /dev/null` guards:
- `hooks.zsh`: oh-my-posh
- `carapace.zsh`: carapace
- `atuin.zsh`: atuin
- `intelli-shell.zsh`: intelli-shell
- `completions.zsh`: phantom
- `keybinds.zsh`: abbr

Each `command -v` is a PATH search (~1-2ms each). With 6+ checks, this adds ~6-12ms.

**Prevention:**
- If you know a tool is always installed, remove the guard
- Use `(( $+commands[tool] ))` instead of `command -v` -- it uses ZSH's internal hash table and is ~10x faster
- Batch checks where possible

**Confidence:** HIGH -- `$+commands` is a well-documented ZSH optimisation.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Eval caching | Stale caches after brew upgrade | Key cache on binary mtime or version string |
| Deferring plugins | fzf-tab ordering violation | Keep fzf-tab synchronous or very carefully order deferred queue |
| Deferring oh-my-posh | Flash of unstyled prompt | Cache init output, never defer the source |
| Deferring mise | Tools not on PATH for first command | Use `--shims` in .zprofile as fallback |
| Deferring completions | Tab completion broken for first command | Accept degraded first-command or keep sync |
| Removing double-loads | Accidentally removing wrong copy | Verify which source provides the correct version |
| Deferring ssh-add | Passphrase prompt on first git op | Use LaunchAgent or SSH config instead |
| Profiling deferred code | zprof shows 0ms for deferred work | Use zsh-bench, manual timing, or temporary sync |
| Deferring keybinds | Wrong plugin owns Up/Ctrl+R | Explicitly set ATUIN_NOBIND and rebind manually |

---

## Top 5 Mistakes When Optimising ZSH Startup

1. **Deferring everything blindly** -- some things MUST be synchronous (prompt, PATH setup, compinit). Defer only what is safe.

2. **Not measuring correctly** -- using `time zsh -ic exit` only measures synchronous time. Use `zsh-bench` to measure perceived latency including deferred work.

3. **Caching without invalidation** -- cached eval output goes stale silently. Always key caches on binary version or mtime.

4. **Ignoring double-loading** -- plugins sourced both by plugin manager AND manually. Each extra source is 20-50ms wasted.

5. **Breaking completion ordering** -- compinit -> fzf-tab -> completion registrations -> widget-wrapping plugins. Getting this wrong causes subtle, intermittent tab-completion failures.

---

## Sync vs Defer Decision Matrix

| Tool/Plugin | Recommendation | Rationale |
|-------------|---------------|-----------|
| oh-my-posh init | **SYNC (cached)** | FOUP is unacceptable; cache eliminates the perf cost |
| mise activate | **SYNC (with shims fallback)** | Tools must be on PATH immediately; use --shims in .zprofile |
| compinit | **SYNC** | Everything depends on it |
| fzf-tab | **SYNC** | Fast (~5ms) and has strict ordering requirements |
| carapace | **SYNC (cached)** | Completions should work on first tab press |
| atuin init | **DEFER** | History search not needed for first prompt render |
| zoxide init | **DEFER or CACHE** | `z` command not needed in first 200ms |
| intelli-shell init | **DEFER** | Not needed immediately |
| zsh-autosuggestions | **DEFER** | Cosmetic; first few chars without suggestions is fine |
| zsh-syntax-highlighting | **DEFER** | Cosmetic; must load LAST (wraps all widgets) |
| fzf completions/keybindings | **DEFER** | Not needed for first command |
| fzf-git | **DEFER** | Git keybindings not needed for first command |
| ssh-add | **DEFER or LaunchAgent** | 10-30ms savings; first SSH use unlikely immediate |
| ohmyzsh plugins | **DEFER** | Convenience aliases, not critical path |
| zsh-abbr | **DEFER** | Abbreviation expansion not needed for first prompt |
| zsh-sdkman | **DEFER** | SDK management not needed immediately |

---

## Testing Strategy for Lazy Loading

### Automated smoke test
```zsh
#!/usr/bin/env zsh
# test-shell-startup.zsh -- run after making deferral changes

errors=0

# Test 1: Prompt renders correctly (not plain %)
prompt_output=$(zsh -ic 'print -P "$PROMPT"' 2>/dev/null)
if [[ "$prompt_output" == *"%"* ]] && [[ ${#prompt_output} -lt 5 ]]; then
  echo "FAIL: Prompt appears unstyled"
  ((errors++))
fi

# Test 2: mise tools on PATH
zsh -ic 'command -v node' >/dev/null 2>&1 || { echo "FAIL: node not on PATH"; ((errors++)); }

# Test 3: No double-loading
count=$(zsh -xc 'exit' 2>&1 | grep -c 'zsh-autosuggestions.zsh')
if [[ $count -gt 1 ]]; then
  echo "FAIL: zsh-autosuggestions loaded $count times"
  ((errors++))
fi

# Test 4: Completions initialised
zsh -ic 'whence -w _complete' 2>/dev/null | grep -q function || {
  echo "FAIL: completion system not initialised"
  ((errors++))
}

echo "Tests complete: $errors failures"
```

### Manual verification checklist
- [ ] Open new terminal -- prompt appears styled immediately (no flash)
- [ ] Type `node --version` immediately -- works (mise tools on PATH)
- [ ] Press Tab on first command -- completions appear (compinit + carapace working)
- [ ] Press Ctrl+R -- atuin history search opens (may need ~200ms delay)
- [ ] Run `git push` -- no passphrase prompt (if keys were in keychain)
- [ ] Type a command -- syntax highlighting appears (may need ~200ms delay)
- [ ] Start typing -- autosuggestions appear (may need ~200ms delay)
- [ ] Run `zsh-bench` -- check first_prompt_lag_ms and command_lag_ms

### Measuring correctly
```bash
# WRONG: only measures synchronous startup
time zsh -ic exit

# RIGHT: measures perceived latency including deferred work
git clone https://github.com/romkatv/zsh-bench /tmp/zsh-bench
/tmp/zsh-bench/zsh-bench
```

---

## Sources

- [zsh-defer README and caveats](https://github.com/romkatv/zsh-defer)
- [fzf-tab ordering requirements](https://github.com/Aloxaf/fzf-tab)
- [mise shims documentation](https://mise.jdx.dev/dev-tools/shims.html)
- [mise activate documentation](https://mise.jdx.dev/cli/activate.html)
- [mise Discussion #4821 - 100-200ms delay](https://github.com/jdx/mise/discussions/4821)
- [carapace setup docs](https://carapace-sh.github.io/carapace-bin/setup.html)
- [evalcache](https://github.com/mroth/evalcache)
- [zsh-smartcache](https://github.com/QuarticCat/zsh-smartcache)
- [zsh-bench deferred loading strategies](https://deepwiki.com/romkatv/zsh-bench/7.6-deferred-loading-strategies)
- [Sheldon documentation](https://sheldon.cli.rs/Examples.html)
- [Speeding Up Zsh - Josh Yin](https://www.joshyin.cc/blog/speeding-up-zsh)
- [Speeding Up zsh Startup - Mariano Zunino](https://mzunino.com.uy/til/2025/03/speeding-up-zsh-startup-with-zprof-and-zsh-defer/)
- [Speed Matters: ZSH Under 70ms - Santacloud](http://santacloud.dev/posts/optimizing-zsh-startup-performance/)
- [Fixing Zsh Tab Completion - Tanner Bleakley](https://blog.tannerb.dev/blog/zsh-tab-completion-fix)
- [Improving Zsh Performance - Dave Dribin](https://www.dribin.org/dave/blog/archives/2024/01/01/zsh-performance/)
