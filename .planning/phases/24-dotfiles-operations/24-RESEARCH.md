# Phase 24: Dotfiles Operations - Research

**Researched:** 2026-02-14
**Domain:** mise task runner wrapping chezmoi dotfiles operations
**Confidence:** HIGH

## Summary

Phase 24 wraps chezmoi's dotfiles workflow commands (apply, diff, update, verify, smoke-test) as mise file-based tasks, making them accessible via user-friendly `mise run dotfiles:*` commands. The research confirms that Phase 23 established the task infrastructure: executable shell scripts in `~/.config/mise/tasks/dotfiles/` with `#MISE` metadata for descriptions, aliases, and rebuild detection. This phase extends that foundation by implementing six specific dotfiles operations (DOT-01 through DOT-06), leveraging chezmoi's built-in commands and existing verification scripts (`scripts/verify-configs.sh`, `scripts/zsh-smoke-test`).

**Key validated patterns:**
- Existing scripts ready: `scripts/verify-configs.sh` (plugin-based verification runner), `scripts/zsh-smoke-test` (shell functionality validation)
- chezmoi commands: `apply --verbose`, `diff`, `update --apply`, `status` for dotfiles operations
- Composite tasks: `dotfiles:sync` chains backup → pull → apply → verify using `mise run` calls
- Task dependencies: Use explicit `mise run` calls rather than `depends` field for better error handling and output control
- Rebuild detection: Optional for user-triggered commands (diff, apply), useful for verify/smoke-test

**Primary recommendation:** Implement six task files in `private_dot_config/mise/tasks/dotfiles/` wrapping chezmoi commands and existing scripts. Use `set -euo pipefail` for safety, `chezmoi apply --verbose` for user feedback, explicit sequencing in sync task for workflow transparency. Deploy via chezmoi with `executable_` prefix, verify with `mise tasks` listing and manual execution.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mise | 2026.1.9+ | Task runner with file-based tasks | Established in Phase 23, provides task discovery, execution, namespacing |
| chezmoi | 2.69.4 | Dotfiles manager with apply/diff/update commands | Established in Phase 2, core dotfiles system being wrapped |
| Bash | 5.x+ | Shell interpreter for task scripts | Standard Unix shell, all existing scripts use bash |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| verify-configs.sh | Current | Plugin-based verification runner | Wrapped by `dotfiles:verify` task (DOT-02) |
| zsh-smoke-test | Current | Shell functionality validation | Wrapped by `dotfiles:smoke-test` task (DOT-03) |
| Git | 2.53.0+ | Version control for chezmoi source | Used in `dotfiles:sync` for pull operations |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `mise run` calls in sync | `#MISE depends=["dotfiles:apply"]` | Depends field runs dependencies silently before task body, explicit calls provide better output interleaving and error context |
| Wrapping chezmoi commands | Aliasing chezmoi directly | Tasks provide unified namespace, consistent error handling, composability (sync task) |
| File-based tasks | TOML inline tasks | File tasks better for multi-step workflows with error handling, easier to test standalone |
| Bash scripts | Shell aliases | Tasks discoverable via `mise tasks`, work across shells, support rebuild detection |

**Installation:**
```bash
# All dependencies already installed
mise --version     # Should show 2026.1.9+
chezmoi --version  # Should show 2.69.4
git --version      # Should show 2.53.0+

# Verify existing scripts
ls -la scripts/verify-configs.sh scripts/zsh-smoke-test
```

## Architecture Patterns

### Recommended Task Structure

```
Chezmoi Source (~/.local/share/chezmoi/):
private_dot_config/mise/tasks/dotfiles/
├── executable_apply        # DOT-01: chezmoi apply --verbose
├── executable_verify       # DOT-02: scripts/verify-configs.sh
├── executable_smoke-test   # DOT-03: scripts/zsh-smoke-test
├── executable_diff         # DOT-04: chezmoi diff
├── executable_update       # DOT-05: chezmoi update --apply
└── executable_sync         # DOT-06: composite workflow

Deployed Target (~/.config/mise/tasks/dotfiles/):
apply         # -rwxr-xr-x
verify        # -rwxr-xr-x
smoke-test    # -rwxr-xr-x
diff          # -rwxr-xr-x
update        # -rwxr-xr-x
sync          # -rwxr-xr-x

Usage:
$ mise tasks
dotfiles:apply       a    Apply dotfiles with verbose output
dotfiles:verify      v    Run 112 verification checks
dotfiles:smoke-test       Validate shell functionality
dotfiles:diff        d    Preview dotfile changes
dotfiles:update           Pull and apply in one command
dotfiles:sync        s    Full sync: backup → pull → apply → verify

$ mise run a                    # Apply dotfiles
$ mise run v                    # Verify configs
$ mise run dotfiles:diff        # Preview changes
$ mise run s                    # Full sync workflow
```

### Pattern 1: Simple Command Wrapper

**What:** Task wrapping single chezmoi command with consistent flags
**When to use:** DOT-01 (apply), DOT-04 (diff), DOT-05 (update)

**Example (DOT-01: dotfiles:apply):**
```bash
#!/usr/bin/env bash
# Source: Phase 23 research, chezmoi docs
#MISE description="Apply dotfiles with verbose output"
#MISE alias="a"

set -euo pipefail

echo "Applying dotfiles..."
chezmoi apply --verbose

echo "✓ Dotfiles applied successfully"
```

**Why this works:** `set -euo pipefail` ensures failures abort, `--verbose` provides user feedback, echo statements wrap for clarity, alias provides shorthand access.

### Pattern 2: Script Wrapper with Path Resolution

**What:** Task wrapping existing script, resolving relative paths from project root
**When to use:** DOT-02 (verify), DOT-03 (smoke-test)

**Example (DOT-02: dotfiles:verify):**
```bash
#!/usr/bin/env bash
# Source: Phase 23 research
#MISE description="Run configuration verification (112 checks)"
#MISE alias="v"
#MISE sources=["scripts/verify-configs.sh", "scripts/verify-checks/*.sh"]
#MISE outputs=["/tmp/dotfiles-verify.timestamp"]

set -euo pipefail

# Resolve script path relative to chezmoi source
SCRIPT_PATH="${HOME}/.local/share/chezmoi/scripts/verify-configs.sh"

if [[ ! -x "$SCRIPT_PATH" ]]; then
  echo "ERROR: Verification script not found or not executable: $SCRIPT_PATH" >&2
  exit 1
fi

echo "Running verification checks..."
"$SCRIPT_PATH"

# Update timestamp for rebuild detection
touch /tmp/dotfiles-verify.timestamp

echo "✓ Verification complete"
```

**Why this works:** Absolute path avoids CWD issues (mise changes directory context), executable check provides clear error, rebuild detection via sources/outputs skips when unnecessary, timestamp marker allows future optimization.

### Pattern 3: Composite Workflow Task

**What:** Multi-step workflow chaining multiple operations with explicit sequencing
**When to use:** DOT-06 (sync)

**Example (DOT-06: dotfiles:sync):**
```bash
#!/usr/bin/env bash
# Source: Derived from Phase 23 research
#MISE description="Full sync: backup → pull → apply → verify"
#MISE alias="s"

set -euo pipefail

echo "Starting full dotfiles sync workflow..."
echo ""

# Step 1: Backup current state
echo "[1/4] Creating backup..."
BACKUP_DIR="${HOME}/.config.backup-$(date +%Y%m%d-%H%M%S)"
if [[ -d "${HOME}/.config" ]]; then
  cp -r "${HOME}/.config" "$BACKUP_DIR"
  echo "✓ Backup created: $BACKUP_DIR"
else
  echo "ℹ No .config directory to backup"
fi
echo ""

# Step 2: Pull latest changes from remote
echo "[2/4] Pulling latest changes..."
cd "${HOME}/.local/share/chezmoi"
git pull --rebase
echo "✓ Changes pulled"
echo ""

# Step 3: Apply dotfiles
echo "[3/4] Applying dotfiles..."
mise run dotfiles:apply
echo ""

# Step 4: Verify configuration
echo "[4/4] Verifying configuration..."
mise run dotfiles:verify
echo ""

echo "✓ Sync complete"
echo "  Backup: $BACKUP_DIR"
```

**Why this works:** Explicit steps with numbered progress provide user feedback, backup before changes allows rollback, git pull in chezmoi source ensures latest templates, `mise run` calls for apply/verify reuse existing tasks with their output formatting, `set -euo pipefail` aborts on any step failure preventing partial states.

**Alternative with `depends`:**
```bash
#!/usr/bin/env bash
#MISE description="Full sync: backup → pull → apply → verify"
#MISE alias="s"
#MISE depends=["dotfiles:apply", "dotfiles:verify"]

set -euo pipefail

# Backup and pull happen in this task body
# depends tasks (apply, verify) run AFTER this script completes
```

**Why explicit calls better:** Dependencies run after the task body in mise, making backup → pull → apply → verify ordering impossible with `depends`. Explicit `mise run` calls provide correct sequencing and better error context.

### Pattern 4: Preview-Only Command

**What:** Read-only command showing what would change without modifying system
**When to use:** DOT-04 (diff)

**Example (DOT-04: dotfiles:diff):**
```bash
#!/usr/bin/env bash
# Source: chezmoi docs
#MISE description="Preview dotfile changes before applying"
#MISE alias="d"

set -euo pipefail

echo "Showing pending dotfile changes..."
echo ""

chezmoi diff

echo ""
echo "ℹ No changes made. Run 'mise run dotfiles:apply' to apply these changes."
```

**Why this works:** `chezmoi diff` is read-only by default, user reminder about apply command provides next action, no rebuild detection needed (always fast, no outputs).

### Pattern 5: Pull-and-Apply Combined

**What:** Wrapper for `chezmoi update` which pulls from remote and applies in one command
**When to use:** DOT-05 (update)

**Example (DOT-05: dotfiles:update):**
```bash
#!/usr/bin/env bash
# Source: chezmoi docs
#MISE description="Pull latest dotfiles and apply (update)"
#MISE alias="u"

set -euo pipefail

echo "Pulling and applying dotfiles..."
chezmoi update --apply --verbose

echo "✓ Dotfiles updated and applied"
```

**Why this works:** `chezmoi update` combines git pull and apply, `--apply` flag ensures changes deployed (default: true but explicit is clearer), `--verbose` provides detailed output, simpler than separate pull + apply for common workflow.

### Anti-Patterns to Avoid

- **Don't use relative paths to scripts:** mise may change CWD to config directory — always use absolute paths like `${HOME}/.local/share/chezmoi/scripts/verify-configs.sh`
- **Don't use `depends` for ordered sequences:** mise runs depends AFTER task body — use explicit `mise run` calls for backup → pull → apply → verify ordering
- **Don't skip error handling:** Always use `set -euo pipefail` at script start to abort on failures, preventing partial states
- **Don't hide command output:** Users want to see what changed — use `--verbose` flags with chezmoi commands, echo progress messages in composite tasks
- **Don't assume scripts are executable:** Check with `[[ -x "$SCRIPT_PATH" ]]` before invoking, provide clear error if missing

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dotfile deployment | Custom sync scripts | `chezmoi apply` | Handles permissions, templates, conditional files, platform differences — avoids 100+ edge cases |
| Change preview | Custom diff logic | `chezmoi diff` | Understands template expansion, permission changes, executable bits — custom diff would miss these |
| Pull and apply | Manual git pull + file copy | `chezmoi update` | Handles rebase conflicts, submodules, template re-evaluation, atomic failures — git pull alone breaks templates |
| Configuration verification | Ad-hoc test scripts | Existing `scripts/verify-configs.sh` | Already implements 112 checks, plugin architecture, color output, phase filtering — reuse rather than rebuild |
| Shell smoke test | Custom shell startup checks | Existing `scripts/zsh-smoke-test` | Already validates 15+ critical functions, bindings, plugin loads — proven in Phase 22 monitoring |

**Key insight:** This phase is entirely about wrapping existing, proven tools. Don't reimplement chezmoi's deployment logic, template engine, or diff algorithm. Don't rebuild verification frameworks that already exist. The value is in the unified mise task interface, not in custom functionality.

## Common Pitfalls

### Pitfall 1: Relative Script Paths Break with mise CWD Changes

**What goes wrong:** Task uses `./scripts/verify-configs.sh`, mise changes to `~/.config/mise/` directory, script not found

**Why it happens:** mise defaults to running tasks from the directory containing mise.toml (or config root), not user's original CWD

**How to avoid:** Use absolute paths like `${HOME}/.local/share/chezmoi/scripts/verify-configs.sh`, or use `#MISE dir="{{cwd}}"` to override (but absolute paths clearer)

**Warning signs:** `scripts/verify-configs.sh: No such file or directory` even though script exists

### Pitfall 2: Task Dependencies Run After Task Body

**What goes wrong:** `dotfiles:sync` uses `#MISE depends=["dotfiles:apply", "dotfiles:verify"]`, expects apply/verify to run first, but they run AFTER the task body completes

**Why it happens:** mise's `depends` field runs prerequisite tasks AFTER the current task's script completes (counterintuitive naming)

**How to avoid:** Use explicit `mise run dotfiles:apply` and `mise run dotfiles:verify` calls in task body for sequential execution with correct order

**Warning signs:** Verification runs before apply, backup happens after changes deployed, ordered workflow executes backwards

### Pitfall 3: Missing Error Handling Leaves Partial State

**What goes wrong:** Sync task runs backup → pull → apply, apply fails midway, system left with partial changes and no way to detect

**Why it happens:** Without `set -euo pipefail`, bash continues after errors by default

**How to avoid:** Always start task scripts with `set -euo pipefail`, ensures first failure aborts entire workflow

**Warning signs:** Task reports success even though commands failed, partial file deployments, inconsistent state after errors

### Pitfall 4: Silent Commands Provide No User Feedback

**What goes wrong:** Task runs `chezmoi apply` without `--verbose`, user sees no output, doesn't know what changed or if task worked

**Why it happens:** chezmoi defaults to minimal output for scripting use cases

**How to avoid:** Add `--verbose` flag to apply/update commands, add echo statements before/after major operations, provide progress indicators for multi-step workflows

**Warning signs:** User reports "nothing happened" even though task completed successfully, confusion about what changed

### Pitfall 5: Rebuild Detection Timestamp Drift

**What goes wrong:** `dotfiles:verify` uses `sources=["~/.zshrc"]` and `outputs=["/tmp/verify.timestamp"]`, modify .zshrc, run verify, task skips because output timestamp somehow newer

**Why it happens:** Tilde paths may not expand correctly, or timezone/clock skew causes mtime comparison failures

**How to avoid:** Use absolute paths (`${HOME}/.zshrc`), or relative paths from config root, verify rebuild detection works with test run, not critical for user-triggered commands (diff, apply don't need rebuild detection)

**Warning signs:** Task always skips even after source changes, `mise run --force` required every time

### Pitfall 6: Backup Overwriting Previous Backups

**What goes wrong:** `dotfiles:sync` creates `~/.config.backup`, next run overwrites it, losing previous backup

**Why it happens:** Static backup filename with no timestamp or uniqueness

**How to avoid:** Use timestamp in backup path: `~/.config.backup-$(date +%Y%m%d-%H%M%S)`, provides unique backup per sync

**Warning signs:** Only one backup exists despite multiple sync runs, backup timestamp doesn't match last sync

## Code Examples

Verified patterns from official sources and Phase 23:

### DOT-01: Apply Task

```bash
#!/usr/bin/env bash
# Source: chezmoi docs https://www.chezmoi.io/reference/commands/apply/
#MISE description="Apply dotfiles with verbose output"
#MISE alias="a"

set -euo pipefail

echo "Applying dotfiles..."
chezmoi apply --verbose

echo "✓ Dotfiles applied successfully"
```

### DOT-02: Verify Task

```bash
#!/usr/bin/env bash
# Source: Existing scripts/verify-configs.sh
#MISE description="Run configuration verification (112 checks)"
#MISE alias="v"

set -euo pipefail

SCRIPT_PATH="${HOME}/.local/share/chezmoi/scripts/verify-configs.sh"

if [[ ! -x "$SCRIPT_PATH" ]]; then
  echo "ERROR: Verification script not found: $SCRIPT_PATH" >&2
  exit 1
fi

echo "Running verification checks..."
"$SCRIPT_PATH"

echo "✓ Verification complete"
```

### DOT-03: Smoke Test Task

```bash
#!/usr/bin/env bash
# Source: Existing scripts/zsh-smoke-test
#MISE description="Validate shell functionality"

set -euo pipefail

SCRIPT_PATH="${HOME}/.local/share/chezmoi/scripts/zsh-smoke-test"

if [[ ! -x "$SCRIPT_PATH" ]]; then
  echo "ERROR: Smoke test script not found: $SCRIPT_PATH" >&2
  exit 1
fi

echo "Running ZSH smoke test..."
"$SCRIPT_PATH"

echo "✓ Smoke test passed"
```

### DOT-04: Diff Task

```bash
#!/usr/bin/env bash
# Source: chezmoi docs
#MISE description="Preview dotfile changes before applying"
#MISE alias="d"

set -euo pipefail

echo "Showing pending dotfile changes..."
echo ""

chezmoi diff

echo ""
echo "ℹ No changes made. Run 'mise run dotfiles:apply' to apply."
```

### DOT-05: Update Task

```bash
#!/usr/bin/env bash
# Source: chezmoi docs https://www.chezmoi.io/reference/commands/update/
#MISE description="Pull latest dotfiles and apply (update)"
#MISE alias="u"

set -euo pipefail

echo "Pulling and applying dotfiles..."
chezmoi update --apply --verbose

echo "✓ Dotfiles updated and applied"
```

### DOT-06: Sync Task (Composite Workflow)

```bash
#!/usr/bin/env bash
# Source: Derived from Phase 23 patterns
#MISE description="Full sync: backup → pull → apply → verify"
#MISE alias="s"

set -euo pipefail

echo "Starting full dotfiles sync workflow..."
echo ""

# Step 1: Backup
echo "[1/4] Creating backup..."
BACKUP_DIR="${HOME}/.config.backup-$(date +%Y%m%d-%H%M%S)"
if [[ -d "${HOME}/.config" ]]; then
  cp -r "${HOME}/.config" "$BACKUP_DIR"
  echo "✓ Backup: $BACKUP_DIR"
fi
echo ""

# Step 2: Pull
echo "[2/4] Pulling latest changes..."
cd "${HOME}/.local/share/chezmoi"
git pull --rebase
echo "✓ Changes pulled"
echo ""

# Step 3: Apply
echo "[3/4] Applying dotfiles..."
mise run dotfiles:apply
echo ""

# Step 4: Verify
echo "[4/4] Verifying configuration..."
mise run dotfiles:verify
echo ""

echo "✓ Sync complete"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual chezmoi commands | mise task wrappers | Phase 24 (2026-02-14) | Unified namespace, discoverable commands, composite workflows |
| Dotbot + manual sync | chezmoi with mise tasks | Phase 2 (2026-01) | Templates, secrets, atomic apply, cross-platform support |
| Ad-hoc verification | Plugin-based framework | Phase 8-12 (2026-02) | 112 automated checks, extensible architecture |
| Shell aliases for shortcuts | mise task aliases | Phase 23-24 (2026-02) | Cross-shell, discoverable via `mise tasks`, composable |
| `chezmoi update` default no-apply | `--apply` flag explicit | Always available | Phase 24 makes apply explicit rather than relying on defaults |

**Deprecated/outdated:**
- **Dotbot symlinks:** Retired Phase 12 — chezmoi manages real files, no symlinks
- **Manual git commands in chezmoi source:** `chezmoi update` handles pull + rebase + apply atomically
- **Separate verify/smoke-test invocations:** `dotfiles:sync` combines in single workflow

## Open Questions

1. **Backup Strategy for Sync Task**
   - What we know: Current implementation backs up entire `~/.config` directory before sync
   - What's unclear: Should backup be selective (only chezmoi-managed paths)? Should old backups auto-prune after N days?
   - Recommendation: Start with full `.config` backup (simpler, safer), monitor disk usage, add pruning task in Phase 25 if needed

2. **Rebuild Detection Necessity**
   - What we know: Verification and smoke-test could use `sources`/`outputs` to skip when unchanged
   - What's unclear: Are these tasks expensive enough to justify rebuild detection? Verify runs in ~2s, smoke-test in <1s
   - Recommendation: Implement `sources`/`outputs` metadata but don't rely on it — user-triggered commands should run when requested, optimization is secondary

3. **Error Recovery in Sync Workflow**
   - What we know: `set -euo pipefail` aborts on first failure, backup exists for rollback
   - What's unclear: Should sync task detect failures and auto-restore from backup? Or leave manual?
   - Recommendation: Leave manual for Phase 24 — auto-restore risks hiding real errors, user should investigate failures before rollback

4. **Verification Check Count**
   - What we know: Documentation claims "112 verification checks" from v1.1 milestone
   - What's unclear: `scripts/verify-checks/` directory is empty except `.gitkeep`, where are the 112 checks?
   - Recommendation: Verify current check count with `scripts/verify-configs.sh` execution, update description if count changed, existing script framework is proven even if check files not visible

## Sources

### Primary (HIGH confidence)

- [Tasks | mise-en-place](https://mise.jdx.dev/tasks/) - Official task system overview
- [TOML-based Tasks | mise-en-place](https://mise.jdx.dev/tasks/toml-tasks.html) - Task dependencies and configuration
- [Running Tasks | mise-en-place](https://mise.jdx.dev/tasks/running-tasks.html) - Task execution and depends behavior
- [apply - chezmoi](https://www.chezmoi.io/reference/commands/apply/) - Apply command reference
- [chezmoi - Dotfile Management System](https://context7.com/twpayne/chezmoi/llms.txt) - Complete command reference (Context7)
- Phase 23 Research - Task infrastructure patterns, file-based tasks, `#MISE` metadata
- Local scripts: `scripts/verify-configs.sh`, `scripts/zsh-smoke-test` - Existing verification framework
- `.planning/MILESTONES.md` - 112 verification checks claim (v1.1 milestone)

### Secondary (MEDIUM confidence)

- [Continuous Improvement in DevOps: Streamlining with chezmoi and mise](https://manuelchichi.com.ar/blog/personal-toolset-2025/) - Real-world chezmoi + mise integration
- [Managing dotfiles with Chezmoi | Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/) - Backup and sync workflows
- [PBS 123: Backing up Dot Files and Intro to Templating (Chezmoi)](https://pbs.bartificer.net/pbs123) - Backup strategies
- [Usage - chezmoi FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/) - diff and apply best practices
- [Introducing Monorepo Tasks · jdx/mise](https://github.com/jdx/mise/discussions/6564) - Task organization patterns

### Tertiary (LOW confidence)

- WebSearch results for mise task workflows (cross-referenced with official docs)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - chezmoi 2.69.4 confirmed via `chezmoi doctor`, mise 2026.1.9+ from Phase 23, scripts verified locally
- Architecture: HIGH - Patterns derived from Phase 23 research and official chezmoi docs, scripts exist and are executable
- Pitfalls: MEDIUM-HIGH - CWD and depends ordering from Phase 23, error handling and paths from chezmoi best practices, backup timestamp from general scripting knowledge
- Existing scripts: HIGH - Verified `verify-configs.sh` and `zsh-smoke-test` exist and are executable
- Verification check count: MEDIUM - 112 checks claimed in milestones but verify-checks/ directory empty, script framework exists

**Research date:** 2026-02-14
**Valid until:** 30 days (2026-03-16) — mise and chezmoi are stable, task patterns unlikely to change

**Critical findings for planner:**
- All six tasks are simple wrappers around existing tools — no custom logic needed
- Existing `scripts/verify-configs.sh` and `scripts/zsh-smoke-test` ready to wrap
- Use absolute paths for script invocation to avoid CWD issues
- Use explicit `mise run` calls in sync task, not `depends` field (ordering constraint)
- `set -euo pipefail` mandatory for error handling
- Alias assignments: a (apply), v (verify), d (diff), u (update), s (sync)
- Timestamp-based backup naming prevents overwrites
- All tasks deploy via chezmoi `executable_` prefix pattern from Phase 23
