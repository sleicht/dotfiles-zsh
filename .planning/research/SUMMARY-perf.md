# Performance Research Summary

**Project:** ZSH dotfiles startup performance optimisation
**Domain:** Shell startup latency (870ms -> <300ms target)
**Researched:** 2026-02-14
**Confidence:** HIGH

## Executive Summary

The current 870ms ZSH startup is dominated by six `eval "$(tool init zsh)"` calls that fork subprocesses on every shell open, even though their output is static between tool upgrades. Eval caching alone (replacing fork+exec with file source) should save 200-400ms. A secondary layer of deferred execution via zsh-defer moves non-prompt-critical work after the first prompt, reducing perceived startup to ~30-50ms. A third layer -- caching Sheldon's own output and removing duplicate plugin loads -- recovers another ~50-70ms.

The recommended approach is a three-layer strategy: (1) eval caching for all static init commands, (2) sync/defer split of the zsh.d dotfiles via Sheldon plugin groups, and (3) Sheldon output caching + zcompile. oh-my-posh init MUST remain synchronous (cached but not deferred) to avoid flash-of-unstyled-prompt. mise needs a shims-in-zprofile fallback so tools are on PATH immediately.

The key risks are stale eval caches after tool upgrades (mitigate by keying on binary mtime), fzf-tab/compinit ordering violations when deferring completion plugins (mitigate by keeping fzf-tab sync or first-in-queue), and mise tools missing from PATH during the defer window (mitigate with `--shims` in `.zprofile`). All risks are well-understood and have documented mitigations.

## Top Bottlenecks (Ranked by Estimated Savings)

| Rank | Bottleneck | Current Cost | Strategy | Savings | Detail |
|------|-----------|-------------|----------|---------|--------|
| 1 | `mise activate zsh` | 100-200ms | evalcache + defer | 100-200ms | [FEATURES-perf.md](FEATURES-perf.md) sec 2 |
| 2 | `oh-my-posh init zsh` | 50-200ms | evalcache (sync) | 48-198ms | [FEATURES-perf.md](FEATURES-perf.md) sec 2 |
| 3 | Duplicate plugin loads (autosuggestions + syntax-highlighting) | 50-100ms | Remove from hooks.zsh | 50-100ms | [PITFALLS-lazy-loading.md](PITFALLS-lazy-loading.md) sec 1 |
| 4 | `carapace _carapace` | 20-50ms | evalcache + defer | 20-50ms | [STACK-perf.md](STACK-perf.md) sec 2.3 |
| 5 | `atuin init zsh` | 10-50ms | evalcache + defer | 10-50ms | [FEATURES-perf.md](FEATURES-perf.md) sec 2 |
| 6 | `sheldon source` binary invocation | 20-40ms | Cache to file + zcompile | 17-35ms | [architecture-sheldon-defer.md](architecture-sheldon-defer.md) sec 3 |
| 7 | `zoxide init zsh` | 15-30ms | evalcache + defer | 10-22ms | [STACK-perf.md](STACK-perf.md) sec 2.3 |
| 8 | Ruby SSH config parsing | 15-25ms | Replace with pure-zsh | 15-25ms | [architecture-sheldon-defer.md](architecture-sheldon-defer.md) sec 9 |
| 9 | `intelli-shell init zsh` | 10-20ms | evalcache + defer | 10-20ms | [architecture-sheldon-defer.md](architecture-sheldon-defer.md) sec 5 |
| 10 | `command -v` guards (6+) | 6-12ms | Replace with `$+commands[]` | 5-10ms | [PITFALLS-lazy-loading.md](PITFALLS-lazy-loading.md) sec 13 |
| 11 | .zcompdump parsing | 5-15ms | zcompile in background | 5-15ms | [STACK-perf.md](STACK-perf.md) sec 3 |

**Total addressable overhead: ~350-700ms.** Target is achievable.

## Recommended Tools

| Tool | Purpose | Status | Notes |
|------|---------|--------|-------|
| **evalcache** (mroth) | Cache static `eval` output to files | Add via Sheldon | Use for oh-my-posh, zoxide, carapace, atuin, intelli-shell. NOT for mise (use defer). |
| **zsh-defer** (romkatv) | Deferred execution after first prompt | Already installed | Queue non-critical work for idle time |
| **zsh-bench** (romkatv) | User-perceived latency measurement | Install (`git clone`) | Acceptance test: first_prompt_lag <50ms, first_command_lag <150ms |
| **hyperfine** | Statistical A/B benchmarking | Already installed | Quick iteration: `hyperfine --warmup 5 'zsh -lic "exit"'` |
| **EPOCHREALTIME** | Line-level section timing | Built-in (zsh/datetime) | Identify bottlenecks within .zshrc |
| **zprof** | Function-level profiling | Built-in | First-pass identification only; cannot profile deferred code |

**Not recommended:** zsh-smartcache (over-engineered for this use case), zinit turbo (would replace Sheldon), zsh-lazyenv (overkill).

## Proposed Architecture

### Sync/Defer Split

The core architectural change is splitting the monolithic `[plugins.dotfiles]` Sheldon entry into two groups:

```
.zshrc
  |-- source cached sheldon output (~3ms)
  |     |-- [SYNC] zsh-defer, evalcache
  |     |-- [SYNC] compinit -C (~15ms)
  |     |-- [SYNC] dotfiles-sync: variables.zsh, FZF exports, zstyles, prompt.zsh (oh-my-posh cached)
  |     |-- [QUEUE] fzf-tab, fzf-git, syntax-highlighting, autosuggestions
  |     |-- [QUEUE] dotfiles-defer: aliases, functions, keybinds, ssh, atuin, carapace, zoxide, mise, intelli-shell
  |     \-- [QUEUE] dotfiles-private
  \-- prompt appears (~30-50ms)
        |-- deferred queue drains (~200ms, invisible to user)
```

### Caching Layer

```
sheldon source -> ~/.cache/sheldon/sheldon.zsh (invalidate on plugins.toml/lock change)
evalcache      -> ~/.zsh-evalcache/ (invalidate on binary mtime change)
.zcompdump     -> .zcompdump.zwc (background compile in .zlogin)
```

### File Refactoring Required

- Split `hooks.zsh` into `prompt.zsh` (sync: oh-my-posh only) and remove duplicate plugin loads
- Split `external.zsh` into `external-sync.zsh` (FZF exports) and `external-defer.zsh` (zoxide, mise, FZF bindings)
- Split `completions.zsh` into sync (zstyles) and defer (SSH hosts, autoloads) portions
- Replace Ruby SSH parsing with pure-zsh: `_cache_hosts=(${${${(M)${(f)"$(< ~/.ssh/config)"}:#Host *}#Host }// /\n})`

Full architecture detail: [architecture-sheldon-defer.md](architecture-sheldon-defer.md)

## Key Risks and Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Stale eval caches** after `brew upgrade` | MEDIUM | Key cache on binary mtime (`[[ "$_bin" -nt "$_cache" ]]`). Automate clear via chezmoi `run_onchange_`. |
| **Flash of unstyled prompt** if oh-my-posh deferred | HIGH | Never defer oh-my-posh. Cache only (sync source of cached file ~2ms). |
| **mise tools not on PATH** during defer window | MEDIUM | Add `mise activate --shims` to `.zprofile` for immediate PATH. Defer full activate for hooks. |
| **fzf-tab ordering violation** | MEDIUM | Keep fzf-tab sync (~5ms cost) or ensure it is first in defer queue after compinit. |
| **zsh-defer scope trap** (typeset without -g) | MEDIUM | Audit all deferred files. Use `export` or `typeset -g`. Test each file individually. |
| **Keybinding conflicts** (atuin vs keybinds.zsh) | LOW | Set `ATUIN_NOBIND=true`, manually bind desired keys after atuin loads. |
| **zprof blind spot** for deferred code | LOW | Use zsh-bench for acceptance testing, EPOCHREALTIME for per-section timing. |

## Projected Timeline: 870ms to <300ms

| Step | Action | Cumulative (est.) | Confidence |
|------|--------|-------------------|------------|
| Baseline | Current state | 870ms | Measured |
| Step 1 | Remove duplicate plugin loads from hooks.zsh | ~770ms | HIGH |
| Step 2 | evalcache oh-my-posh (sync) | ~620ms | HIGH |
| Step 3 | evalcache mise, zoxide, atuin, carapace, intelli-shell | ~380ms | HIGH |
| Step 4 | Cache sheldon source output + zcompile | ~350ms | HIGH |
| Step 5 | Defer non-critical tools (mise, zoxide, atuin, carapace, ssh-add, intelli-shell) | ~200ms (perceived) | MEDIUM |
| Step 6 | Split dotfiles sync/defer + replace Ruby SSH parsing | ~170ms (perceived) | MEDIUM |
| Step 7 | zcompile .zcompdump + simplify compinit | ~160ms (perceived) | HIGH |
| Step 8 | Replace `command -v` with `$+commands[]` | ~150ms (perceived) | HIGH |

**Steps 1-4 alone should hit ~350ms (eval caching without deferral).**
**Steps 5-6 push perceived startup to ~170ms, well under the 300ms target.**
**Steps 7-8 are polish.**

## Implementation Order (Highest Impact, Lowest Risk First)

### Phase 1: Quick Wins (no architecture change)

**Rationale:** Zero-risk changes that do not alter plugin loading structure.
**Estimated savings:** ~250ms
**Research needed:** None -- standard patterns.

1. Remove duplicate zsh-autosuggestions + zsh-syntax-highlighting from `hooks.zsh`
2. Replace Ruby SSH parsing with pure-zsh in `completions.zsh`
3. Replace `command -v` guards with `(( $+commands[tool] ))`
4. Add `typeset -U PATH path FPATH fpath`

### Phase 2: Eval Caching Layer

**Rationale:** Largest single optimisation. Low risk because behaviour is identical -- only the source changes from subprocess to file.
**Estimated savings:** ~250-400ms
**Research needed:** None -- evalcache is well-documented.

1. Add evalcache as first Sheldon plugin (before zsh-defer)
2. Cache oh-my-posh init (sync, prompt-critical)
3. Cache mise, zoxide, atuin, carapace, intelli-shell init
4. Cache sheldon source output to file + zcompile
5. zcompile .zcompdump in background (.zlogin)

### Phase 3: Sync/Defer Architecture Split

**Rationale:** Moves remaining latency off the critical path. Medium risk due to file refactoring and ordering constraints.
**Estimated savings:** ~100-200ms (perceived)
**Research needed:** Validate Sheldon `use` array ordering (does it respect list order or sort alphabetically?).

1. Split `hooks.zsh` -> `prompt.zsh` (sync) + remove rest
2. Split `external.zsh` -> `external-sync.zsh` + `external-defer.zsh`
3. Split `completions.zsh` -> sync zstyles + defer SSH hosts
4. Update `plugins.toml` with `dotfiles-sync` and `dotfiles-defer` groups
5. Add `mise activate --shims` to `.zprofile` as PATH fallback

### Phase 4: Monitoring and Hardening

**Rationale:** Prevent regressions. Low effort, high long-term value.
**Estimated savings:** 0ms (preventive)

1. Add startup time self-monitoring (warn if >300ms)
2. Add smoke test script (prompt styled, tools on PATH, no double-loads)
3. Add chezmoi `run_onchange_` hook to clear eval caches on tool version change
4. Document benchmarking methodology in CLAUDE.md

### Research Flags

- **Phase 3** needs validation: Sheldon `use` field ordering behaviour. Test with explicit file list before committing to the split.
- **Phases 1-2** are standard patterns -- skip research, proceed directly to implementation.
- **Phase 4** is operational -- no research needed.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (profiling + caching tools) | HIGH | Built-in ZSH modules + well-established community tools (evalcache 1.3k stars, zsh-bench by romkatv) |
| Features (lazy loading patterns) | HIGH | Extensively documented by romkatv, multiple real-world case studies achieving <100ms |
| Architecture (sheldon + zsh-defer) | HIGH | Based on Sheldon docs, zsh-defer README, and community configs. One gap: Sheldon `use` ordering. |
| Pitfalls | HIGH | Directly observed in the codebase (double-loading confirmed). All mitigations are documented. |

**Overall confidence:** HIGH

### Gaps to Address

- **Sheldon `use` array ordering:** Does Sheldon source files in the order listed in `use`, or alphabetically? If alphabetical, file naming must enforce correct ordering within each group. Test before Phase 3.
- **mise evalcache safety:** STACK.md says do NOT cache mise (dynamic output). FEATURES.md says cache is fine. Architecture research says cache with care. Recommendation: test `_evalcache mise activate zsh` and verify directory-change hooks still work. If they break, use defer-only for mise.
- **Actual baseline measurements:** The 870ms figure needs re-verification with the current config using the three-stage methodology (hyperfine -> EPOCHREALTIME -> zsh-bench). The actual breakdown may differ from estimates.

## Sources

### Primary (HIGH confidence)
- [romkatv/zsh-defer](https://github.com/romkatv/zsh-defer) -- deferred execution model, scope limitations
- [romkatv/zsh-bench](https://github.com/romkatv/zsh-bench) -- benchmarking methodology, thresholds
- [mroth/evalcache](https://github.com/mroth/evalcache) -- eval caching implementation, measured savings
- [Sheldon documentation](https://sheldon.cli.rs/Configuration.html) -- template system, plugin ordering
- [fzf-tab README](https://github.com/Aloxaf/fzf-tab) -- compinit ordering requirements
- [mise activate docs](https://mise.jdx.dev/cli/activate.html) -- shims vs activate tradeoffs

### Secondary (MEDIUM confidence)
- [mise Discussion #4821](https://github.com/jdx/mise/discussions/4821) -- 100-200ms delay reported
- [Santacloud: ZSH Under 70ms](http://santacloud.dev/posts/optimizing-zsh-startup-performance/) -- real-world case study
- [Josh Yin: Speeding Up Zsh](https://www.joshyin.cc/blog/speeding-up-zsh) -- evalcache + zsh-defer combination
- [Sheldon caching technique](https://zenn.dev/fuzmare/articles/zsh-plugin-manager-cache) -- static cache + zcompile

### Detailed Research Files
- [STACK-perf.md](STACK-perf.md) -- profiling tools, eval caching libs, zcompile, benchmarking methodology
- [FEATURES-perf.md](FEATURES-perf.md) -- lazy loading patterns, per-tool analysis, feature dependencies
- [architecture-sheldon-defer.md](architecture-sheldon-defer.md) -- sync/defer split, plugin ordering, target plugins.toml
- [PITFALLS-lazy-loading.md](PITFALLS-lazy-loading.md) -- 13 pitfalls ranked by severity, testing strategy

---
*Research completed: 2026-02-14*
*Ready for roadmap: yes*
