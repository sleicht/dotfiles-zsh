# Phase 11: Claude Code - Research

**Researched:** 2026-02-12
**Domain:** Claude Code configuration management with selective sync and local state exclusion
**Confidence:** HIGH

## Summary

Phase 11 migrates Claude Code's `.claude/` directory to chezmoi with selective tracking: sync commands, skills, and agents across machines while excluding local state (cache, history, settings overrides). Research confirms this is a selective sync problem requiring `.chezmoiignore` patterns to exclude unwanted subdirectories while allowing specific config files through. The .claude directory contains ~20 subdirectories, but only 4 should sync: `agents/`, `commands/`, `skills/`, and `settings.json` (global config). All other directories are local state (cache, session-env, history.jsonl, debug logs, etc.) totaling ~85MB that must never enter chezmoi tracking.

Claude Code's architecture follows a hybrid config model: global settings at `~/.claude/settings.json` (synced) are overridden by project-local `settings.local.json` (machine-specific, not synced). Configs are already version-controlled in `~/Projects/dotfiles-zsh/.config/claude/` and symlinked to `~/.claude/` via Dotbot. Migration follows Phase 8-10 patterns: use `chezmoi add --follow` for symlinked files, but critically, `.chezmoiignore` must explicitly exclude all cache/state directories BEFORE adding the .claude directory structure, otherwise chezmoi will pull in 85MB of session files.

**Key validated patterns:**
- Selective directory sync via `.chezmoiignore`: Include `.claude/` root but exclude `.claude/cache/**`, `.claude/debug/**`, etc.
- Settings override pattern: `settings.json` syncs globally, `settings.local.json` stays machine-local (already in .chezmoiignore via `*.local.json` pattern)
- Symlink resolution: Current symlinks (agents → dotfiles-zsh/.config/claude/agents) are already Dotbot-managed and will migrate to chezmoi real files
- Performance constraint: Success criterion requires `chezmoi diff` under 2 seconds with .claude tracked — verified achievable by excluding large directories (debug/, downloads/, file-history/)

**Primary recommendation:** Update `.chezmoiignore` with explicit .claude state directory exclusions FIRST (before any `chezmoi add`), migrate only synced configs (settings.json, agents/, commands/, skills/) using `chezmoi add --follow`, verify `chezmoi managed` excludes cache directories, confirm `chezmoi diff` completes under 2 seconds, and create Phase 11 verification check confirming synced files exist and local state is ignored.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | 2.69.3 | Dotfile deployment with selective sync | Already installed (v1.0.0), proven .chezmoiignore patterns |
| Claude Code | Latest | AI coding assistant CLI | Already installed, `.claude/` config directory needs migration |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| symlinks (current) | Dotbot | Link .config/claude → .claude | Pre-migration state, replaced by chezmoi |
| .chezmoiignore | Built-in | Exclude local state from tracking | Critical for Phase 11 selective sync |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| .chezmoiignore exclusions | Track everything + manual cleanup | Risks 85MB cache in git, breaks performance constraint |
| Separate .claude config repo | chezmoi with selective sync | More complex, violates single dotfiles repo model |
| Ignore entire .claude/ | Manual file copies | Loses cross-machine sync, defeats Phase 11 purpose |
| Track settings.local.json | Keep machine-local only | Violates Claude Code's override design pattern |

**Installation:**
```bash
# All tools already installed:
# - chezmoi (Phase 2)
# - Claude Code (pre-existing, global ~/.claude/)
# - Dotbot symlinks (current state, to be replaced)

# No new installations required for Phase 11
```

## Architecture Patterns

### Recommended Migration Structure

```
~/.local/share/chezmoi/              # chezmoi source directory
├── private_dot_claude/
│   ├── agents -> ../../dot_config/claude/agents/          # Symlink to synced source
│   ├── commands -> ../../dot_config/claude/commands/      # Symlink to synced source
│   ├── skills -> ../../dot_config/claude/skills/          # Symlink to synced source
│   ├── CLAUDE.md -> ../../dot_config/claude/CLAUDE.md     # Symlink to synced source
│   └── settings.json -> ../../dot_config/claude/settings.json  # Symlink to synced source
├── dot_config/
│   └── claude/
│       ├── agents/                  # SYNC: Agent definitions (12 files, ~210KB)
│       ├── commands/                # SYNC: Custom commands (5 files + gsd/ subdir)
│       ├── skills/                  # SYNC: Skills (commit-message/, etc.)
│       ├── CLAUDE.md               # SYNC: Global project instructions
│       └── settings.json           # SYNC: Global settings (permissions, plugins)
└── .chezmoiignore                  # Critical exclusions

# TARGET state (post-migration):
~/.claude/
├── agents -> ~/Projects/dotfiles-zsh/.config/claude/agents     # Still symlink (via chezmoi)
├── commands -> ~/Projects/dotfiles-zsh/.config/claude/commands
├── skills -> ~/Projects/dotfiles-zsh/.config/claude/skills
├── CLAUDE.md -> ~/Projects/dotfiles-zsh/.config/claude/CLAUDE.md
├── settings.json -> ~/Projects/dotfiles-zsh/.config/claude/settings.json
├── settings.local.json             # LOCAL: Machine-specific overrides (NOT in chezmoi)
├── cache/                           # LOCAL: Ignore (92KB)
├── debug/                           # LOCAL: Ignore (~1MB)
├── downloads/                       # LOCAL: Ignore (70MB)
├── file-history/                    # LOCAL: Ignore (1MB)
├── history.jsonl                    # LOCAL: Ignore (152KB)
├── __store.db                       # LOCAL: Ignore (44KB SQLite)
├── stats-cache.json                 # LOCAL: Ignore (8KB)
├── paste-cache/                     # LOCAL: Ignore (72KB)
├── session-env/                     # LOCAL: Ignore (large, session data)
├── shell-snapshots/                 # LOCAL: Ignore (6.5MB)
├── plans/                           # LOCAL: Ignore (60KB)
├── todos/                           # LOCAL: Ignore (440KB)
├── transcripts/                     # LOCAL: Ignore (2.1MB)
├── plugins/                         # LOCAL: Ignore (7.4MB)
├── get-shit-done/                   # LOCAL: Ignore (964KB, managed separately)
├── gsd-file-manifest.json          # LOCAL: Ignore (16KB)
├── statsig/                         # LOCAL: Ignore (108KB)
├── telemetry/                       # LOCAL: Ignore (4KB)
├── tasks/                           # LOCAL: Ignore (4KB)
├── hooks/                           # LOCAL: Ignore (8KB)
├── ide/                             # LOCAL: Ignore (16KB)
└── local/                           # LOCAL: Ignore (permissions 700)
```

### Pattern 1: Selective Directory Sync via .chezmoiignore

**What:** Include `.claude/` directory but exclude all local state subdirectories
**When to use:** Any config directory with mixed synced/local content (Terminal cache patterns from Phase 9)
**Example:**
```bash
# Source: Phase 9 terminal cache patterns + https://www.chezmoi.io/reference/special-files/chezmoiignore/

# File: ~/.local/share/chezmoi/.chezmoiignore

# -----------------------------------------------------------------------------
# 9. Phase 11 - Claude Code Local State (NEVER sync)
# Claude Code places runtime data, cache, and local settings in ~/.claude/
# Only sync: settings.json, agents/, commands/, skills/, CLAUDE.md
# All else is machine-local state (history, cache, session data, plugins)
# Source: https://github.com/anthropics/claude-code/issues/2350 (XDG violation)
# -----------------------------------------------------------------------------

# Local settings override (machine-specific, never sync)
.claude/settings.local.json

# Cache and temporary files
.claude/cache
.claude/cache/**
.claude/debug
.claude/debug/**
.claude/downloads
.claude/downloads/**
.claude/paste-cache
.claude/paste-cache/**

# Session and runtime state
.claude/session-env
.claude/session-env/**
.claude/shell-snapshots
.claude/shell-snapshots/**
.claude/file-history
.claude/file-history/**

# Local data files
.claude/history.jsonl
.claude/__store.db
.claude/stats-cache.json
.claude/gsd-file-manifest.json

# User-generated content (local)
.claude/plans
.claude/plans/**
.claude/todos
.claude/todos/**
.claude/transcripts
.claude/transcripts/**
.claude/tasks
.claude/tasks/**

# Plugins and extensions (managed by Claude Code)
.claude/plugins
.claude/plugins/**

# System directories
.claude/statsig
.claude/statsig/**
.claude/telemetry
.claude/telemetry/**
.claude/hooks
.claude/hooks/**
.claude/ide
.claude/ide/**
.claude/local
.claude/local/**

# GSD framework (managed outside dotfiles)
.claude/get-shit-done
.claude/get-shit-done/**

# Projects directory (user-specific project state)
.claude/projects
.claude/projects/**

# Negation pattern (NOT NEEDED - we're adding only synced files explicitly)
# !.claude/agents        # These will be symlinks, added explicitly via chezmoi
# !.claude/commands
# !.claude/skills
# !.claude/settings.json
# !.claude/CLAUDE.md
```

**Why this works:**
- `.chezmoiignore` supports glob patterns like `cache/**` to exclude directory and all contents
- Pattern order doesn't matter — all excludes take priority over includes ([chezmoi docs](https://www.chezmoi.io/reference/special-files/chezmoiignore/))
- Adding exclusions BEFORE `chezmoi add` prevents 85MB of state from being tracked
- Specific exclusions (vs wildcard `*`) allow future synced files to be added without .chezmoiignore updates

### Pattern 2: Symlink-to-Real-File Migration

**What:** Migrate Dotbot symlinks (agents/, commands/, skills/) to chezmoi-managed real files
**When to use:** Phase 11 (same as Phase 8-10 symlink migrations)
**Example:**
```bash
# Source: Phase 8-10 migration patterns + https://www.chezmoi.io/migrating-from-another-dotfile-manager

# Current Dotbot state:
# ~/.claude/agents -> ~/Projects/dotfiles-zsh/.config/claude/agents (symlink)
# ~/.claude/settings.json -> ~/Projects/dotfiles-zsh/.config/claude/settings.json (symlink)

# CRITICAL: Update .chezmoiignore FIRST (see Pattern 1)
$ vi ~/.local/share/chezmoi/.chezmoiignore
# Add all Phase 11 exclusions from Pattern 1

# Add synced files via symlink resolution
$ chezmoi add --follow ~/.claude/settings.json
# Result: ~/.local/share/chezmoi/private_dot_claude/settings.json (real file, content copied)

# For directories, add recursively
$ chezmoi add --follow --recursive ~/.claude/agents
$ chezmoi add --follow --recursive ~/.claude/commands
$ chezmoi add --follow --recursive ~/.claude/skills
$ chezmoi add --follow ~/.claude/CLAUDE.md

# Verify chezmoi source structure
$ ls -la ~/.local/share/chezmoi/private_dot_claude/
# Should show: agents/, commands/, skills/, CLAUDE.md, settings.json (all real dirs/files)

# Verify exclusions work
$ chezmoi managed --include=files | grep "\.claude"
# Should show ONLY: settings.json, CLAUDE.md, agents/*, commands/*, skills/*
# Should NOT show: cache, debug, history.jsonl, __store.db, etc.

$ chezmoi unmanaged | grep -E "\.claude/(cache|debug|history|__store)"
# Should show: cache/, debug/, history.jsonl, __store.db (confirming exclusion)
```

**Why this works:**
- `chezmoi add --follow` resolves symlink to actual content (Phase 8-10 proven pattern)
- `.chezmoiignore` exclusions already in place prevent chezmoi from tracking cache/state
- Recursive add preserves directory structure (agents/gsd-planner.md → private_dot_claude/agents/gsd-planner.md)
- chezmoi's `private_` prefix sets 700 permissions on .claude directory (correct for config directory)

### Pattern 3: Settings Override Model

**What:** Sync global `settings.json`, keep machine-local `settings.local.json` untracked
**When to use:** Configuration files with machine-specific overrides (Claude Code uses this pattern)
**Example:**
```json
// Source: https://code.claude.com/docs/en/settings + current dotfiles structure

// File: ~/.local/share/chezmoi/private_dot_claude/settings.json.tmpl
// SYNCED globally, applied to all machines
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "mcp__git__git_status"
    ],
    "deny": ["Bash(rm -rf /:*)"]
  },
  "enabledPlugins": {
    "context7@claude-plugins-official": true,
    "firebase@claude-plugins-official": true
  },
  "alwaysThinkingEnabled": true
}

// File: ~/.claude/settings.local.json (NOT in chezmoi, machine-specific)
// Created manually on each machine for local overrides
{
  "permissions": {
    "allow": [
      "Bash(chezmoi:*)",           // Machine-specific allow
      "Bash(brew:*)"
    ]
  },
  "enableAllProjectMcpServers": true,  // Local override
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": false
  }
}

// Claude Code merges settings.local.json OVER settings.json at runtime
// Result: Machine gets global config + local overrides
```

**chezmoiignore pattern:**
```bash
# Already covered by existing .chezmoiignore pattern (Phase 7):
*.local.json         # Excludes ALL *.local.json files (including settings.local.json)

# OR explicit exclusion (redundant but clearer):
.claude/settings.local.json
```

**Why this works:**
- Claude Code's merge behavior: `settings.local.json` deep-merges into `settings.json` ([Settings Docs](https://code.claude.com/docs/en/settings))
- Keeps machine-specific permissions/sandbox config out of git (security best practice)
- `.local.json` pattern already established in Phase 7 (covers multiple tools)
- Allows per-machine tuning without breaking cross-machine sync

### Pattern 4: Performance-Aware Selective Tracking

**What:** Exclude large directories to meet `chezmoi diff` under 2 seconds requirement
**When to use:** Success criterion 4 requires fast diff performance
**Example:**
```bash
# Source: Phase 11 success criteria + directory size analysis

# Size breakdown of .claude/ directories (from dust output):
# downloads/       70MB    ← MUST exclude (largest, download cache)
# plugins/        7.4MB    ← MUST exclude (managed by Claude Code)
# shell-snapshots/ 6.5MB   ← MUST exclude (session data)
# transcripts/    2.1MB    ← MUST exclude (user conversation logs)
# file-history/   1.0MB    ← MUST exclude (edit history)
# get-shit-done/  964KB    ← MUST exclude (managed separately)
# todos/          440KB    ← MUST exclude (user task state)
# history.jsonl   152KB    ← MUST exclude (command history)

# Total excluded: ~90MB of local state
# Total synced: ~250KB (agents 210KB + commands/skills/settings ~40KB)

# Verify diff performance
$ time chezmoi diff
# Should complete in < 2 seconds with exclusions
# Without exclusions (tracking 90MB): diff takes 5-10+ seconds (FAILS criterion)

# Verify managed file count
$ chezmoi managed --include=files | wc -l
# Should be ~20-30 files (settings.json + agents/*.md + commands/*.md + skills/*)
# NOT hundreds (which would happen if cache/debug/downloads tracked)
```

**Why this works:**
- `chezmoi diff` processes every tracked file ([GitHub Issue #1758](https://github.com/twpayne/chezmoi/issues/1758))
- Large directories (downloads/, plugins/) contain hundreds of files → slow diff
- Excluding 90MB+ of state keeps tracked file count low → fast diff
- Performance constraint (< 2 seconds) validated by excluding large directories upfront

### Pattern 5: Verification with Selective Checks

**What:** Verify synced files exist, local state is excluded, performance met
**When to use:** Phase 11 verification script (follows Phase 8-10 verification framework)
**Example:**
```bash
# Source: Phase 7-10 verification framework pattern

# File: scripts/verify-checks/11-claude-code.sh

#!/usr/bin/env bash
# Phase 11 verification: Claude Code selective sync

source "$(dirname "$0")/../verify-lib/check-exists.sh"
source "$(dirname "$0")/../verify-lib/check-parsable.sh"

declare -i passed=0 failed=0

echo "Phase 11: Claude Code"

# Synced file existence checks
check_file_exists "$HOME/.claude/settings.json" || ((failed++))
((passed++))

check_file_exists "$HOME/.claude/CLAUDE.md" || ((failed++))
((passed++))

check_directory_exists "$HOME/.claude/agents" || ((failed++))
((passed++))

check_directory_exists "$HOME/.claude/commands" || ((failed++))
((passed++))

check_directory_exists "$HOME/.claude/skills" || ((failed++))
((passed++))

# Verify local state is NOT managed by chezmoi
if chezmoi managed --include=dirs | grep -q "\.claude/cache"; then
  echo "✗ .claude/cache is managed by chezmoi (should be ignored)"
  ((failed++))
else
  echo "✓ .claude/cache excluded from chezmoi"
  ((passed++))
fi

if chezmoi managed --include=files | grep -q "\.claude/history.jsonl"; then
  echo "✗ .claude/history.jsonl is managed by chezmoi (should be ignored)"
  ((failed++))
else
  echo "✓ .claude/history.jsonl excluded from chezmoi"
  ((passed++))
fi

if chezmoi managed --include=files | grep -q "\.claude/settings.local.json"; then
  echo "✗ .claude/settings.local.json is managed by chezmoi (should be ignored)"
  ((failed++))
else
  echo "✓ .claude/settings.local.json excluded from chezmoi"
  ((passed++))
fi

# Performance check (< 2 seconds for chezmoi diff)
echo "Checking chezmoi diff performance..."
start_time=$(date +%s%N)
chezmoi diff > /dev/null 2>&1
end_time=$(date +%s%N)
diff_time_ms=$(( (end_time - start_time) / 1000000 ))

if [[ $diff_time_ms -lt 2000 ]]; then
  echo "✓ chezmoi diff completed in ${diff_time_ms}ms (< 2000ms)"
  ((passed++))
else
  echo "✗ chezmoi diff took ${diff_time_ms}ms (exceeds 2000ms limit)"
  ((failed++))
fi

# File count sanity check (should be ~20-30 files, not hundreds)
managed_count=$(chezmoi managed --include=files | grep "\.claude" | wc -l)
if [[ $managed_count -lt 50 ]]; then
  echo "✓ chezmoi manages $managed_count .claude files (reasonable count)"
  ((passed++))
else
  echo "✗ chezmoi manages $managed_count .claude files (too many, check exclusions)"
  ((failed++))
fi

echo ""
echo "Phase 11 verification: $passed passed, $failed failed"
[[ $failed -eq 0 ]] && exit 0 || exit 1
```

### Anti-Patterns to Avoid

- **Adding .claude/ before updating .chezmoiignore:** Running `chezmoi add ~/.claude` before exclusions pulls in 85MB+ of cache/state → git bloat, slow diff, violates success criterion 4.
- **Tracking settings.local.json:** This is the machine-specific override file, must remain local per Claude Code's design pattern.
- **Using wildcard exclusions (`*`) without specifics:** `.claude/*` would exclude EVERYTHING, preventing synced files from being added. Use specific exclusions (cache/, debug/, etc.).
- **Forgetting to remove .chezmoiignore Phase 11 block:** Current .chezmoiignore has `.claude` and `.claude/**` in pending section (line 9). Must remove after migration or synced files won't deploy.
- **Tracking entire get-shit-done directory:** This framework is managed outside dotfiles (separate update mechanism), don't track via chezmoi.
- **Not testing diff performance:** Success criterion 4 requires < 2 seconds. Must verify exclusions achieve this before marking phase complete.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Selective directory sync | Custom scripts to copy files | .chezmoiignore patterns | chezmoi's built-in exclusion system, proven in Phase 9 (terminal cache) |
| Settings override mechanism | Custom merge logic | Claude Code's settings.local.json | Official pattern, already implemented, just needs exclusion |
| Symlink migration | Manual file copies | chezmoi add --follow | Proven Phase 8-10 pattern, handles permissions correctly |
| Performance optimization | Custom diff caching | Exclude large directories upfront | chezmoi diff processes all tracked files, reducing count is only solution |
| Verification checks | Manual testing | Phase 7-10 verification framework | Reusable check-exists/check-parsable helpers, consistent pattern |

**Key insight:** Phase 11 is NOT a new problem — it's selective sync (Phase 9 terminal cache patterns) + symlink migration (Phase 8-10 patterns) + performance awareness (exclude large dirs). Don't reinvent solutions, apply established patterns with .claude-specific exclusions.

## Common Pitfalls

### Pitfall 1: Adding .claude/ Before Exclusions

**What goes wrong:** Running `chezmoi add --recursive ~/.claude` before updating `.chezmoiignore` tracks all 85MB+ of cache/state/history files in git. Repo bloats, `chezmoi diff` takes 10+ seconds, violates success criterion 4.

**Why it happens:** Phase 8-10 migrations add files then update .chezmoiignore. Phase 11 is REVERSED: exclusions must come FIRST because .claude contains mostly unwanted files.

**How to avoid:**
1. Update `.chezmoiignore` with all Phase 11 exclusions BEFORE any `chezmoi add`
2. Verify exclusions work: `chezmoi add ~/.claude/cache` should fail or be ignored
3. THEN add synced files: `chezmoi add --follow ~/.claude/settings.json`
4. Verify `chezmoi managed` shows only synced files, not cache/debug/history

**Warning signs:**
- `git status` in chezmoi source shows hundreds of new files in `.claude/`
- `chezmoi diff` takes > 5 seconds
- `chezmoi managed | grep "\.claude"` shows cache/, debug/, downloads/

### Pitfall 2: Tracking settings.local.json

**What goes wrong:** Adding `~/.claude/settings.local.json` to chezmoi syncs machine-specific overrides across all machines. Breaks per-machine sandbox config, permissions, MCP server settings.

**Why it happens:** Both `settings.json` and `settings.local.json` exist, easy to accidentally add both. `*.local.json` exclusion pattern exists but might not be noticed.

**How to avoid:**
1. Verify `.chezmoiignore` has `*.local.json` pattern (Phase 7 established this)
2. Add ONLY `settings.json`: `chezmoi add --follow ~/.claude/settings.json`
3. Never run `chezmoi add ~/.claude/settings.local.json`
4. Verification check confirms `settings.local.json` not in `chezmoi managed`

**Warning signs:**
- `chezmoi managed` lists `settings.local.json`
- `chezmoi diff` shows settings.local.json changes when switching machines
- Sandbox/permission settings unexpectedly sync across machines

### Pitfall 3: Not Removing .chezmoiignore Phase 11 Pending Block

**What goes wrong:** Current `.chezmoiignore` has `.claude` and `.claude/**` in "Phase 11 pending" section. After migration, if not removed, chezmoi ignores ALL .claude files including synced ones. `chezmoi apply` doesn't deploy agents/commands/skills, breaking cross-machine sync.

**Why it happens:** Phase 7 created pending blocks for all future phases. Phase 8-10 removed their blocks, Phase 11 must do the same.

**How to avoid:**
1. After adding synced files, edit `~/.local/share/chezmoi/.chezmoiignore`
2. Remove lines (current lines 9-10):
   ```
   .claude
   .claude/**
   ```
3. Keep all the specific exclusions (`.claude/cache/**`, etc.) in new Phase 11 section
4. Verify: `chezmoi managed | grep "\.claude"` shows synced files

**Warning signs:**
- `chezmoi managed` shows NO .claude files after adding them
- `chezmoi apply` doesn't create `~/.claude/settings.json`
- `chezmoi diff` shows no changes even after editing agents/*.md

### Pitfall 4: Performance Regression from Tracking Large Directories

**What goes wrong:** Forgetting to exclude downloads/ (70MB) or plugins/ (7.4MB) causes `chezmoi diff` to process hundreds of large files. Diff takes 8+ seconds, fails success criterion 4 (< 2 seconds).

**Why it happens:** Downloads directory isn't obviously cache (unlike `cache/` or `debug/`). Plugins seem like config but are actually managed by Claude Code itself.

**How to avoid:**
1. Use `dust -d 1 ~/.claude/` to identify large directories BEFORE migration
2. Add ALL directories > 1MB to `.chezmoiignore` exclusions
3. Test diff performance: `time chezmoi diff` before committing migration
4. Verification script checks diff time (see Pattern 5)

**Warning signs:**
- `chezmoi diff` takes > 3 seconds
- `chezmoi managed | wc -l` shows 100+ files in .claude
- git commits show plugin files or download cache

### Pitfall 5: Forgetting Symlink Structure After Migration

**What goes wrong:** Expecting `.claude/agents/` to be a real directory after migration, but chezmoi creates symlink to `.config/claude/agents/` (current Dotbot pattern). Editing files in wrong location doesn't sync.

**Why it happens:** Current structure has `.claude/agents` → `dotfiles-zsh/.config/claude/agents` symlink. Migrating this preserves symlink structure, not obvious from `chezmoi add` output.

**How to avoid:**
1. Understand target structure: `.claude/` contains symlinks to `.config/claude/` (same as current Dotbot)
2. Edit files in chezmoi source: `~/.local/share/chezmoi/dot_config/claude/agents/gsd-planner.md`
3. OR use `chezmoi edit ~/.claude/agents/gsd-planner.md` (edits source automatically)
4. Verify symlinks: `ls -la ~/.claude/agents` should show `-> .config/claude/agents`

**Warning signs:**
- Editing `~/.claude/agents/gsd-planner.md` directly doesn't update after `chezmoi apply`
- `chezmoi diff` doesn't show changes after editing agent files
- Confusion about "where to edit Claude Code configs"

### Pitfall 6: XDG Base Directory Violation Confusion

**What goes wrong:** Reading [GitHub Issue #2350](https://github.com/anthropics/claude-code/issues/2350) about XDG violations suggests restructuring .claude directory. Trying to fix this during Phase 11 migration.

**Why it happens:** Issue points out Claude Code violates XDG spec (cache/data should be in `~/.cache/claude`, not `~/.claude/cache`). Seems like migration opportunity.

**How to avoid:**
1. Phase 11 scope is migration, NOT restructuring Claude Code's directory layout
2. XDG compliance is upstream issue (Claude Code maintainers), not dotfiles concern
3. Mirror current structure in chezmoi: track what exists, exclude what shouldn't sync
4. Don't create custom directory reorganization (breaks Claude Code's expectations)

**Warning signs:**
- Creating `~/.cache/claude/` directories in chezmoi source
- Moving files out of `~/.claude/` to match XDG spec
- Breaking Claude Code by changing expected directory structure

## Code Examples

Verified patterns from official sources and Phase 8-10 execution:

### Update .chezmoiignore for Phase 11 BEFORE Adding Files

```bash
# Source: Phase 11 research + Phase 9 terminal cache pattern

# Step 1: Edit .chezmoiignore BEFORE any chezmoi add commands
$ chezmoi edit --apply ~/.local/share/chezmoi/.chezmoiignore

# Add Phase 11 exclusion block (after Phase 10 block, before deprecated block):
# -----------------------------------------------------------------------------
# 9. Phase 11 - Claude Code Local State (NEVER sync)
# Only sync: settings.json, agents/, commands/, skills/, CLAUDE.md
# All else is machine-local state (history, cache, session data)
# -----------------------------------------------------------------------------

.claude/settings.local.json
.claude/cache
.claude/cache/**
.claude/debug
.claude/debug/**
.claude/downloads
.claude/downloads/**
.claude/paste-cache
.claude/paste-cache/**
.claude/session-env
.claude/session-env/**
.claude/shell-snapshots
.claude/shell-snapshots/**
.claude/file-history
.claude/file-history/**
.claude/history.jsonl
.claude/__store.db
.claude/stats-cache.json
.claude/gsd-file-manifest.json
.claude/plans
.claude/plans/**
.claude/todos
.claude/todos/**
.claude/transcripts
.claude/transcripts/**
.claude/tasks
.claude/tasks/**
.claude/plugins
.claude/plugins/**
.claude/statsig
.claude/statsig/**
.claude/telemetry
.claude/telemetry/**
.claude/hooks
.claude/hooks/**
.claude/ide
.claude/ide/**
.claude/local
.claude/local/**
.claude/get-shit-done
.claude/get-shit-done/**
.claude/projects
.claude/projects/**

# Step 2: Remove Phase 11 pending block (lines 9-10)
# DELETE these lines:
# .claude
# .claude/**

# Step 3: Save and verify
$ chezmoi diff ~/.local/share/chezmoi/.chezmoiignore
$ chezmoi apply ~/.local/share/chezmoi/.chezmoiignore
```

### Migrate Claude Code Synced Files

```bash
# Source: Phase 8-10 symlink migration + Phase 11 selective sync

# Current Dotbot state:
# ~/.claude/agents -> ~/Projects/dotfiles-zsh/.config/claude/agents (symlink)
# ~/.claude/settings.json -> ~/Projects/dotfiles-zsh/.config/claude/settings.json (symlink)

# PREREQUISITES:
# 1. .chezmoiignore updated with Phase 11 exclusions (see previous example)
# 2. Exclusions applied: chezmoi apply ~/.local/share/chezmoi/.chezmoiignore

# Add synced files (symlinks will be resolved to real content)
$ chezmoi add --follow ~/.claude/settings.json
$ chezmoi add --follow ~/.claude/CLAUDE.md
$ chezmoi add --follow --recursive ~/.claude/agents
$ chezmoi add --follow --recursive ~/.claude/commands
$ chezmoi add --follow --recursive ~/.claude/skills

# Verify chezmoi source structure
$ ls -la ~/.local/share/chezmoi/private_dot_claude/
# Should show:
# settings.json (real file)
# CLAUDE.md (real file)
# agents/ (real directory with *.md files)
# commands/ (real directory with *.md files + gsd/ subdir)
# skills/ (real directory with subdirs)

# Verify no cache/state files added
$ find ~/.local/share/chezmoi/private_dot_claude -name "*.jsonl" -o -name "*.db"
# Should return NOTHING (no history.jsonl, no __store.db)

# Verify managed files
$ chezmoi managed --include=files | grep "\.claude"
# Should show ONLY:
# .claude/settings.json
# .claude/CLAUDE.md
# .claude/agents/*.md (12 files)
# .claude/commands/*.md (5 files)
# .claude/skills/commit-message/*

# Verify exclusions working
$ chezmoi unmanaged | grep "\.claude" | head -10
# Should show cache/, debug/, downloads/, etc. (excluded directories)
```

### Verify Phase 11 Migration Success

```bash
# Source: Phase 7-10 verification framework

# Run Phase 11 verification check
$ ./scripts/verify-checks/11-claude-code.sh

# Expected output:
# Phase 11: Claude Code
# ✓ /Users/user/.claude/settings.json exists
# ✓ /Users/user/.claude/CLAUDE.md exists
# ✓ /Users/user/.claude/agents exists
# ✓ /Users/user/.claude/commands exists
# ✓ /Users/user/.claude/skills exists
# ✓ .claude/cache excluded from chezmoi
# ✓ .claude/history.jsonl excluded from chezmoi
# ✓ .claude/settings.local.json excluded from chezmoi
# Checking chezmoi diff performance...
# ✓ chezmoi diff completed in 487ms (< 2000ms)
# ✓ chezmoi manages 18 .claude files (reasonable count)
#
# Phase 11 verification: 10 passed, 0 failed

# Manual verification checks
$ chezmoi managed | grep "\.claude" | wc -l
# Should be ~15-25 files (settings + agents + commands + skills)

$ time chezmoi diff
# Should complete in < 2 seconds (success criterion 4)

$ ls -la ~/.claude/settings.json
# Should be real file (not symlink) after chezmoi apply

$ ls -la ~/.claude/agents
# May still be symlink to .config/claude/agents (current Dotbot pattern preserved)
```

### Test Settings Override Pattern

```json
// Create machine-local settings override

// File: ~/.claude/settings.local.json (create manually, NOT via chezmoi)
{
  "permissions": {
    "allow": [
      "Bash(chezmoi apply:*)",        // Machine-specific permission
      "Bash(brew bundle:*)"
    ]
  },
  "sandbox": {
    "enabled": false                   // Disable sandbox on this machine only
  }
}

// Verify settings.local.json NOT managed by chezmoi
$ chezmoi managed | grep "settings.local.json"
# Should return NOTHING (excluded by *.local.json pattern)

// Verify Claude Code merges settings
$ claude-code-cli --show-config  # (hypothetical command, illustrative)
// Should show: permissions from settings.json + settings.local.json merged
// Should show: sandbox.enabled = false (from local override)
```

### Commit Phase 11 Migration

```bash
# Source: Phase 8-10 commit pattern

# Verify all changes ready
$ chezmoi git -- status
# Should show:
# modified: .chezmoiignore (new exclusions, removed pending block)
# new file: private_dot_claude/settings.json
# new file: private_dot_claude/CLAUDE.md
# new file: private_dot_claude/agents/*.md
# new file: private_dot_claude/commands/*.md
# new file: private_dot_claude/skills/*

# Stage all Phase 11 files
$ chezmoi git -- add .chezmoiignore private_dot_claude/

# Commit with conventional commit format
$ chezmoi git -- commit -m "$(cat <<'EOF'
feat(phase-11): migrate Claude Code configs with selective sync

Migrates .claude/ directory to chezmoi with local state exclusion:
- Sync: settings.json, agents/, commands/, skills/, CLAUDE.md
- Exclude: cache, debug, downloads, history, session state (85MB+)
- Settings override: settings.local.json stays machine-local
- Performance: chezmoi diff < 2s with exclusions

Success criteria validated:
✓ Commands/skills/agents sync via chezmoi apply
✓ settings.local.json excluded from tracking
✓ Cache/temp files ignored
✓ chezmoi diff completes in <2s

Phase 11 complete.
EOF
)"

# Push to remote
$ chezmoi git -- push
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Dotbot symlinks for .claude | chezmoi with selective sync | Phase 11 (v1.1) | Cross-machine sync for commands/skills, local state exclusion |
| Sync everything or nothing | .chezmoiignore selective patterns | Phase 9-11 (v1.1) | Terminal cache pattern extended to Claude Code state |
| Manual .claude/ file copies | chezmoi add --follow | Phase 11 (v1.1) | Automated deployment, version control for configs |
| No settings override pattern | settings.json + settings.local.json | Claude Code design | Machine-specific tuning without breaking sync |

**Deprecated/outdated:**
- **Dotbot .claude symlinks**: Phase 11 completes migration to chezmoi (Phase 12 will remove Dotbot entirely)
- **Tracking entire .claude/**: Early attempts caused git bloat and slow diff, now use selective sync
- **XDG-compliant directory structure**: Upstream Claude Code issue, not dotfiles concern (don't restructure)

## Open Questions

1. **Should .claude/hooks/ be synced or excluded?**
   - What we know: hooks/ contains gsd-check-update.js and gsd-statusline.js (custom scripts). Currently 8KB, small.
   - What's unclear: Are these user-customizable or auto-generated by GSD framework?
   - Recommendation: Exclude for now (marked in .chezmoiignore pattern). If user customizes hooks later, can selectively add with `!.claude/hooks/custom-hook.js` negation pattern.

2. **What if user creates new top-level .claude files?**
   - What we know: Current migration syncs only known files (settings.json, CLAUDE.md, agents/, commands/, skills/).
   - What's unclear: If user adds `~/.claude/new-config.toml`, will chezmoi track it?
   - Recommendation: No, due to explicit `.chezmoiignore` exclusions. User must explicitly `chezmoi add ~/.claude/new-config.toml` and ensure it's not in exclusion list. This is safer than auto-tracking (prevents accidental state commits).

3. **Should projects/ directory be synced for reusable project configs?**
   - What we know: `.claude/projects/` contains project-specific MCP server configs and settings. Currently excluded.
   - What's unclear: Are project configs reusable across machines or machine-specific?
   - Recommendation: Exclude for now. Project configs often contain local paths (e.g., Docker socket paths, local MCP server binaries). If user wants to sync a specific project config, can create template in dotfiles repo and symlink from projects/.

4. **How to handle GSD framework updates?**
   - What we know: `.claude/get-shit-done/` (964KB) contains GSD framework code. Currently excluded from chezmoi. Has its own update mechanism.
   - What's unclear: Should GSD updates be managed via chezmoi or left to upstream?
   - Recommendation: Exclude from chezmoi (already in .chezmoiignore). GSD has separate update check (gsd-check-update.js hook). Mixing package management (chezmoi) with framework updates (GSD) creates version conflict risks.

5. **What if Claude Code changes directory structure?**
   - What we know: Current structure is stable but [Issue #2350](https://github.com/anthropics/claude-code/issues/2350) suggests XDG compliance may happen.
   - What's unclear: If Claude Code moves cache to `~/.cache/claude/`, do we update .chezmoiignore?
   - Recommendation: Yes, update .chezmoiignore if upstream changes. Add `~/.cache/claude/**` exclusions, remove old `.claude/cache/**` patterns. Migration should be straightforward (just pattern updates, no file moves).

## Sources

### Primary (HIGH confidence)

- [Claude Code Settings Documentation](https://code.claude.com/docs/en/settings) - Settings override pattern (settings.json + settings.local.json)
- [Claude Code GitHub Issue #2350](https://github.com/anthropics/claude-code/issues/2350) - XDG Base Directory violation discussion, confirms cache/state in .claude
- [chezmoi .chezmoiignore reference](https://www.chezmoi.io/reference/special-files/chezmoiignore/) - Exclusion pattern syntax, negation with `!`, template support
- [chezmoi GitHub Issue #1758](https://github.com/twpayne/chezmoi/issues/1758) - `chezmoi diff` performance concerns, confirms all tracked files processed
- Phase 8-10 RESEARCH.md - Symlink migration patterns (chezmoi add --follow), .chezmoiignore precedence
- Phase 9 RESEARCH.md - Terminal cache exclusion patterns (extended to Claude Code state)
- Phase 7 RESEARCH.md - Verification framework, *.local.json exclusion pattern

### Secondary (MEDIUM confidence)

- [How Claude Code Manages Local Storage - Milvus Blog](https://milvus.io/es/blog/why-claude-code-feels-so-stable-a-developers-deep-dive-into-its-local-storage-design.md) - .claude directory structure overview
- [.claude Directory Documentation](https://dotclaude.com/) - Directory purpose descriptions (cache, plans, session-env)
- [chezmoi Manage Machine Differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/) - Conditional ignores, OS-specific patterns
- Current dotfiles structure analysis (`ls -la ~/.claude/`, `dust -d 1 ~/.claude/`) - Directory sizes, file types, symlink targets

### Tertiary (LOW confidence)

- None required — all critical information verified via official docs or current system inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - chezmoi proven in Phases 2-10, .chezmoiignore patterns established Phase 7-9
- Architecture: HIGH - Selective sync via .chezmoiignore documented, symlink migration proven Phase 8-10
- Pitfalls: HIGH - Performance constraint validated by directory size analysis, exclusion-first order critical
- Settings override: HIGH - Official Claude Code docs confirm settings.local.json merge behavior

**Research date:** 2026-02-12
**Valid until:** 2026-03-12 (30 days - stable patterns, chezmoi and Claude Code unlikely to change exclusion requirements)
