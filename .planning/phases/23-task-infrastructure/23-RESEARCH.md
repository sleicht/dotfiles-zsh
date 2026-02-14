# Phase 23: Task Infrastructure - Research

**Researched:** 2026-02-14
**Domain:** mise task runner with file-based tasks, chezmoi deployment, rebuild detection
**Confidence:** HIGH

## Summary

Phase 23 establishes mise's task runner infrastructure by deploying executable shell scripts from chezmoi source (`dot_mise/tasks/`) to the user's home directory (`~/.mise/tasks/`) where mise discovers them globally. The research confirms mise supports file-based tasks with automatic discovery, colon-based namespacing via subdirectories, task aliases, and sophisticated rebuild detection using source/output timestamps. The standard pattern deploys tasks via chezmoi with `executable_` prefix for permissions, uses `#MISE` metadata comments for configuration, and leverages mise's built-in task discovery to make dotfiles operations available as `mise run <task>` commands.

**Key validated patterns:**
- File-based tasks in `~/.config/mise/tasks/` or `~/.mise/tasks/` discovered globally
- Subdirectory structure creates colon namespaces (`dotfiles/apply.sh` → `dotfiles:apply`)
- `#MISE` metadata comments configure alias, sources, outputs, dependencies, environment
- Rebuild detection via `sources`/`outputs` skips expensive tasks when files unchanged
- chezmoi's `executable_` prefix preserves execute permissions across deployment

**Primary recommendation:** Deploy tasks to `~/.mise/tasks/` using chezmoi `dot_mise/tasks/` source directory with `executable_` prefix, organise by namespace subdirectories (`dotfiles/`, `git/`), use `#MISE` comments for aliases and rebuild detection, verify with `mise tasks` showing complete task catalogue.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mise | 2026.1.9+ | Task runner with file-based task support | Active development, mature task system, built-in rebuild detection, global task discovery |
| chezmoi | 2.69.3+ | Dotfiles deployment managing task files | Established in Phase 2, handles executable permissions, template support for machine differences |
| Bash/Zsh | 5.x+ | Shell interpreter for task scripts | Standard Unix shell, supported via shebang in task files |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| usage CLI | Latest | Argument/flag completions | When tasks need structured CLI arguments (via `usage` field in `#MISE` comments) |
| gh CLI | Latest | GitHub operations in git tasks | For `git:pr` task creating pull requests |
| Other interpreters | Latest | Multi-language tasks | Python/Node/Ruby tasks via shebang (`#!/usr/bin/env python`) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| File-based tasks | TOML tasks in mise.toml | TOML tasks better for simple inline commands, file tasks better for complex multi-step workflows, easier to test standalone |
| `~/.mise/tasks/` | Project `.mise/tasks/` | Project-scoped tasks only work in that directory, global tasks available everywhere |
| chezmoi deployment | Manual symlinks | Manual loses templating, permission management, cross-machine support |
| mise tasks | Makefile/just | mise integrates with tool management, understands project context, better rebuild detection |
| Tera templates | `usage` field | Tera deprecated 2026.5.0, removed 2026.11.0 — usage field is current standard |

**Installation:**
```bash
# mise already installed in Phase 5
mise --version  # Should show 2026.1.9+

# chezmoi already installed in Phase 2
chezmoi --version  # Should show 2.69.3+

# Optional: usage CLI for task argument completions
brew install usage-cli
```

## Architecture Patterns

### Recommended Task Structure

```
Chezmoi Source (~/.local/share/chezmoi/):
dot_mise/
├── tasks/
│   ├── dotfiles/
│   │   ├── executable_apply           # → ~/.mise/tasks/dotfiles/apply
│   │   ├── executable_verify          # → ~/.mise/tasks/dotfiles/verify
│   │   ├── executable_smoke-test      # → ~/.mise/tasks/dotfiles/smoke-test
│   │   ├── executable_diff            # → ~/.mise/tasks/dotfiles/diff
│   │   ├── executable_update          # → ~/.mise/tasks/dotfiles/update
│   │   └── executable_sync            # → ~/.mise/tasks/dotfiles/sync
│   └── git/
│       ├── executable_commit          # → ~/.mise/tasks/git/commit
│       ├── executable_branch          # → ~/.mise/tasks/git/branch
│       ├── executable_cleanup         # → ~/.mise/tasks/git/cleanup
│       └── executable_pr              # → ~/.mise/tasks/git/pr

Deployed Target (~/.mise/tasks/):
dotfiles/
├── apply         # Executable, #MISE metadata
├── verify        # Executable
├── smoke-test    # Executable
├── diff          # Executable
├── update        # Executable
└── sync          # Executable, depends on other tasks
git/
├── commit        # Executable
├── branch        # Executable
├── cleanup       # Executable
└── pr            # Executable

Usage:
$ mise tasks
dotfiles:apply       a    Apply dotfiles with chezmoi
dotfiles:verify           Verify configuration files
dotfiles:smoke-test       Run ZSH smoke test
dotfiles:diff             Show pending dotfile changes
dotfiles:update           Pull and apply dotfile updates
dotfiles:sync             Full sync: backup → pull → apply → verify
git:commit               Create conventional commit with Jira prefix
git:branch               Create feature branch with naming convention
git:cleanup              Remove merged local branches
git:pr                   Create GitHub pull request

$ mise run a                    # Runs dotfiles:apply via alias
$ mise run dotfiles:verify      # Full task name
$ mise run git:commit           # Git task
```

### Pattern 1: File-Based Task with Metadata

**What:** Executable shell script with `#MISE` comment configuration
**When to use:** All tasks in this phase (standard approach)

**Example:**
```bash
#!/usr/bin/env bash
# Source: https://mise.jdx.dev/tasks/file-tasks.html
#MISE description="Apply dotfiles with chezmoi"
#MISE alias="a"
#MISE sources=[".local/share/chezmoi/**/*"]
#MISE outputs=["~/.zshrc", "~/.config/**/*"]

set -euo pipefail

echo "Applying dotfiles..."
chezmoi apply --verbose

echo "✓ Dotfiles applied successfully"
```

**Why this works:** `#MISE` metadata configures task without separate TOML, `sources`/`outputs` enable rebuild detection, alias provides shorthand, executable permission set via chezmoi `executable_` prefix.

### Pattern 2: Colon-Based Namespacing via Subdirectories

**What:** Subdirectories in `~/.mise/tasks/` automatically create namespace prefixes
**When to use:** Organising related tasks (dotfiles ops, git workflows)

**Example:**
```
~/.mise/tasks/
├── dotfiles/apply        → mise task name: dotfiles:apply
├── dotfiles/verify       → mise task name: dotfiles:verify
├── git/commit            → mise task name: git:commit
└── git/pr                → mise task name: git:pr
```

**Why this works:** mise automatically prefixes task names with subdirectory path, creating logical grouping visible in `mise tasks` output, prevents name collisions between domains.

### Pattern 3: Rebuild Detection with Sources/Outputs

**What:** Skip expensive tasks when source files unchanged using timestamp comparison
**When to use:** Tasks with clear inputs/outputs (builds, tests that depend on specific files)

**Example:**
```bash
#!/usr/bin/env bash
#MISE description="Run verification suite"
#MISE sources=["~/.zshrc", "~/.zsh.d/**/*.zsh", "scripts/verify-configs.sh"]
#MISE outputs=["/tmp/last-verify.timestamp"]
#MISE depends=["dotfiles:apply"]

# Task only runs if sources newer than outputs
scripts/verify-configs.sh

# Update timestamp marker
touch /tmp/last-verify.timestamp
```

**Why this works:** mise compares mtime (modification time) of all sources against outputs, skips task execution if outputs are newer, dramatically speeds up repeated task runs when nothing changed.

### Pattern 4: Task Dependencies and Composition

**What:** Composite tasks that chain multiple operations with dependencies
**When to use:** Workflows combining multiple steps (sync = backup → pull → apply → verify)

**Example:**
```bash
#!/usr/bin/env bash
#MISE description="Full sync: backup → pull → apply → verify"
#MISE alias="s"
#MISE depends=["dotfiles:apply", "dotfiles:verify"]

set -euo pipefail

echo "Starting full dotfiles sync..."

# Backup current state (simple file copy, not a depends task)
echo "Creating backup..."
cp -r ~/.config ~/.config.backup-$(date +%Y%m%d-%H%M%S)

# Pull latest changes
echo "Pulling updates..."
cd ~/.local/share/chezmoi && git pull

# depends tasks run automatically: dotfiles:apply, dotfiles:verify

echo "✓ Sync complete"
```

**Why this works:** `depends` field ensures prerequisite tasks run first, failure in dependency blocks parent task, allows building complex workflows from simple task primitives.

### Pattern 5: Chezmoi Deployment with Executable Permissions

**What:** Deploy task files via chezmoi with `executable_` prefix to preserve permissions
**When to use:** All task files (required pattern for this phase)

**Example:**
```bash
# In chezmoi source directory
cd ~/.local/share/chezmoi

# Create task with executable_ prefix
cat > dot_mise/tasks/dotfiles/executable_apply << 'EOF'
#!/usr/bin/env bash
#MISE description="Apply dotfiles"
#MISE alias="a"
chezmoi apply --verbose
EOF

# No chmod needed — chezmoi handles it via executable_ prefix

# Apply to deploy
chezmoi apply

# Verify deployed with correct permissions
ls -l ~/.mise/tasks/dotfiles/apply  # Should show -rwxr-xr-x
mise tasks                           # Should list dotfiles:apply
```

**Why this works:** chezmoi's `executable_` prefix automatically sets 0755 permissions on target file, no manual `chmod` needed, permissions preserved across machines, works consistently on macOS and Linux.

### Anti-Patterns to Avoid

- **Don't use shorthand `mise <task>` in scripts:** Always use `mise run <task>` — if mise adds a command with that name in future, shorthand breaks
- **Don't rely on Tera templates:** arg(), option(), flag() deprecated 2026.5.0, removed 2026.11.0 — use `usage` field instead
- **Don't format `#MISE` to `# MISE`:** Formatters breaking `#MISE` make configuration unrecognised — use `# [MISE]` alternative syntax if formatters aggressive
- **Don't forget executable bit:** Tasks without execute permissions not detected by mise — always use chezmoi `executable_` prefix
- **Don't mix global config locations:** Choose either `~/.config/mise/tasks/` or `~/.mise/tasks/` consistently — this project uses `~/.mise/tasks/` for simplicity
- **Don't assume CWD:** mise changes to mise.toml directory before running tasks — use `MISE_ORIGINAL_CWD` if you need original directory

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Task discovery | Custom script registry | mise's file-based discovery | mise automatically finds executable files in task directories, handles namespacing, provides `mise tasks` listing |
| Rebuild detection | Manual timestamp checking | mise `sources`/`outputs` | mise handles mtime comparison, glob patterns, skip logic — avoid complex shell timestamp comparison |
| Task aliases | Shell alias registry | `#MISE alias="x"` | mise manages alias uniqueness, conflict detection, completion integration |
| Task dependencies | Manual sequencing | `#MISE depends=["task1"]` | mise handles parallel execution, failure propagation, dependency resolution |
| Cross-machine scripts | Hardcoded paths | chezmoi templates + mise vars | chezmoi templates handle OS differences, mise provides runtime context via env vars |

**Key insight:** Task runners already solve task discovery, dependency management, and rebuild detection. Don't reimplement these with custom shell logic — use mise's built-in features. The complexity comes from parallel execution, correct failure handling, and efficient skip detection, all solved in mise.

## Common Pitfalls

### Pitfall 1: Executable Permission Missing on Deployment

**What goes wrong:** Task file deployed to `~/.mise/tasks/` without execute bit, mise doesn't detect it, `mise tasks` doesn't list it

**Why it happens:** Forgot `executable_` prefix in chezmoi source filename, or manually created file without `chmod +x`

**How to avoid:** Always use `executable_` prefix for task files in chezmoi source (`dot_mise/tasks/dotfiles/executable_apply`), verify with `ls -l ~/.mise/tasks/` showing `-rwxr-xr-x`

**Warning signs:** `mise tasks` output missing expected task, error "task not found" when running `mise run <task>`

### Pitfall 2: Formatter Breaking #MISE Configuration

**What goes wrong:** Code formatter changes `#MISE` to `# MISE` (with space), mise no longer recognises metadata, task has no description/alias/sources

**Why it happens:** Shell formatters (shfmt, shellcheck auto-fix) normalise comment spacing

**How to avoid:** Use alternative syntax `# [MISE]` instead of `#MISE`, configure formatter to ignore these lines, verify metadata with `mise tasks --json`

**Warning signs:** Task appears in listing but has no description, alias doesn't work, rebuild detection not functioning

### Pitfall 3: Working Directory Assumptions

**What goes wrong:** Task assumes it runs in user's current directory, breaks when mise changes to mise.toml directory

**Why it happens:** mise defaults to config file's directory for consistent task execution context

**How to avoid:** Use `MISE_ORIGINAL_CWD` env var for user's directory, or explicitly set `#MISE dir="{{cwd}}"` to override default

**Warning signs:** Relative paths not resolving, "file not found" errors for files in user's directory

### Pitfall 4: Task Shadowing by Future Commands

**What goes wrong:** Use shorthand `mise apply` instead of `mise run apply`, mise adds `apply` command in future release, task never runs

**Why it happens:** mise prioritises built-in commands over tasks when using shorthand syntax

**How to avoid:** Always use `mise run <task>` or `mise r <task>` in scripts and documentation, never rely on shorthand

**Warning signs:** Task works today but could silently break after mise upgrade

### Pitfall 5: Sources/Outputs Glob Pattern Errors

**What goes wrong:** Rebuild detection doesn't trigger when files change, task skips incorrectly

**Why it happens:** Invalid glob patterns in `sources` (e.g., `~/.config/**/*` doesn't expand tilde, need absolute path or relative path)

**How to avoid:** Use relative paths from config root, or `{{env.HOME}}/.config/**/*` template syntax, test with `mise run <task> --force` then normal run

**Warning signs:** Task never re-runs even after source changes, always skips with "up-to-date" message

### Pitfall 6: Monorepo Exclusion Override

**What goes wrong:** Add custom exclusion pattern in monorepo mode, default exclusions (node_modules, target) no longer apply

**Why it happens:** Specifying any patterns replaces defaults, doesn't append

**How to avoid:** Not applicable to this phase (not using monorepo mode), but worth knowing for future

**Warning signs:** mise discovering unwanted tasks in node_modules or build directories

## Code Examples

Verified patterns from official sources:

### Basic Task with Alias and Description

```bash
#!/usr/bin/env bash
# Source: https://mise.jdx.dev/tasks/file-tasks.html
#MISE description="Apply dotfiles with chezmoi"
#MISE alias="a"

set -euo pipefail
chezmoi apply --verbose
```

### Task with Rebuild Detection

```bash
#!/usr/bin/env bash
# Source: https://mise.jdx.dev/tasks/task-configuration.html
#MISE description="Run verification suite"
#MISE sources=["scripts/verify-configs.sh", "~/.zshrc", "~/.zsh.d/**/*.zsh"]
#MISE outputs=["/tmp/last-verify.timestamp"]

set -euo pipefail
scripts/verify-configs.sh
touch /tmp/last-verify.timestamp
```

### Task with Dependencies

```bash
#!/usr/bin/env bash
# Source: https://mise.jdx.dev/tasks/task-configuration.html
#MISE description="Full dotfiles sync"
#MISE depends=["dotfiles:apply", "dotfiles:verify"]

set -euo pipefail
cd ~/.local/share/chezmoi && git pull
# Dependencies run automatically after this script
```

### Task with Environment Variables

```bash
#!/usr/bin/env bash
# Source: https://mise.jdx.dev/tasks/file-tasks.html
#MISE description="Run smoke test with verbose output"
#MISE env={VERBOSE="1", DEBUG="true"}

set -euo pipefail
scripts/zsh-smoke-test.sh
```

### Task with Required Tools

```bash
#!/usr/bin/env bash
# Source: https://mise.jdx.dev/tasks/task-configuration.html
#MISE description="Create GitHub pull request"
#MISE tools={gh="latest"}

set -euo pipefail
gh pr create --fill
```

### Composite Task Pattern

```bash
#!/usr/bin/env bash
# Source: Derived from https://mise.jdx.dev/tasks/task-configuration.html
#MISE description="Full sync: backup → pull → apply → verify"
#MISE alias="s"

set -euo pipefail

# Backup
cp -r ~/.config ~/.config.backup-$(date +%Y%m%d-%H%M%S)

# Pull
cd ~/.local/share/chezmoi && git pull

# Apply
mise run dotfiles:apply

# Verify
mise run dotfiles:verify

echo "✓ Sync complete"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Tera templates (arg(), option(), flag()) | `usage` field for task arguments | Deprecated 2026.5.0, removed 2026.11.0 | Must use `usage` field for argument parsing, Tera no longer supported |
| Monorepo experimental flag | Native monorepo support | Stabilised 2025 | Can use monorepo features without experimental flag (not needed for this project) |
| Manual timestamp checking | sources/outputs rebuild detection | Mature feature since mise 2024.x | Built-in skip logic more reliable than custom shell timestamp logic |
| Task shadowing allowed | Warning + recommendation for explicit `mise run` | Documentation updated 2025+ | Best practice to avoid future command conflicts |

**Deprecated/outdated:**
- **Tera template functions:** arg(), option(), flag() in task files deprecated 2026.5.0, removed 2026.11.0 — use `usage` field instead
- **Shorthand task invocation in scripts:** `mise <task>` still works but discouraged — use `mise run <task>` to avoid shadowing

## Open Questions

1. **Global vs Config-Root Task Priority**
   - What we know: Tasks can exist in `~/.config/mise/tasks/` (global) and `.mise/tasks/` (project)
   - What's unclear: If both define `dotfiles:apply`, which wins? Does project override global?
   - Recommendation: Use only global tasks for dotfiles project (single config root), verify with `mise tasks --json` showing source paths

2. **Rebuild Detection with Templates**
   - What we know: mise compares mtime of sources vs outputs
   - What's unclear: If chezmoi template changes but target file mtime unchanged, does rebuild trigger?
   - Recommendation: Use chezmoi's `run_onchange_` scripts for cache invalidation (Phase 22 pattern), mise tasks for user-triggered workflows

3. **Task Discovery Performance**
   - What we know: mise scans task directories on each invocation
   - What's unclear: Performance impact with many tasks (100+), does mise cache task list?
   - Recommendation: Start with ~10 tasks (INFRA + DOT + GIT requirements), measure `mise tasks` latency, optimise if needed

## Sources

### Primary (HIGH confidence)

- [Tasks | mise-en-place](https://mise.jdx.dev/tasks/) - Official task system overview
- [File Tasks | mise-en-place](https://mise.jdx.dev/tasks/file-tasks.html) - File-based task documentation with directory structure, metadata, examples
- [Task Configuration | mise-en-place](https://mise.jdx.dev/tasks/task-configuration.html) - Complete task configuration options (alias, sources, outputs, depends, etc.)
- [TOML-based Tasks | mise-en-place](https://mise.jdx.dev/tasks/toml-tasks.html) - Sources/outputs rebuild detection, task dependencies
- [Manage different types of file - chezmoi](https://www.chezmoi.io/user-guide/manage-different-types-of-file/) - executable_ prefix, permission management
- Phase 2 Research (chezmoi foundation) - Established chezmoi deployment patterns
- Phase 5 Research (mise tool version) - mise installation, configuration structure

### Secondary (MEDIUM confidence)

- [Using mise-en-place for dotfiles — Sympolymathesy, by Chris Krycho](https://v5.chriskrycho.com/notes/using-mise-en-place-for-dotfiles/) - Real-world dotfiles + mise tasks integration
- [Continuous Improvement in DevOps: Streamlining with chezmoi and mise](https://manuelchichi.com.ar/blog/personal-toolset-2025/) - chezmoi + mise integration patterns (2025)
- [Best Practices for Using Mise to Maintain Project Structure and Environment Variables](https://combray.prose.sh/2025-11-26-mise-project-structure-env-vars) - mise project structure recommendations
- GitHub discussions on mise tasks - [Discussion #6564](https://github.com/jdx/mise/discussions/6564), [Discussion #3761](https://github.com/jdx/mise/discussions/3761)

### Tertiary (LOW confidence)

- Various WebSearch results for mise tasks and chezmoi executable files (cross-referenced with official docs for verification)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - mise and chezmoi versions verified, task system mature and well-documented
- Architecture: HIGH - File-based tasks, directory structure, namespacing verified from official docs with code examples
- Pitfalls: MEDIUM-HIGH - Most from official docs (formatter, permissions, shadowing), working directory and glob patterns inferred from docs but not explicitly listed as "common mistakes"
- Rebuild detection: HIGH - sources/outputs feature documented with examples, mtime comparison confirmed
- Chezmoi integration: HIGH - executable_ prefix confirmed from official docs, deployment pattern established in Phase 2

**Research date:** 2026-02-14
**Valid until:** 30 days (2026-03-16) — mise is stable, task system mature, unlikely to change significantly

**Critical findings for planner:**
- Use `~/.mise/tasks/` as global task directory (simpler than `~/.config/mise/tasks/` for dotfiles)
- Always prefix with `executable_` in chezmoi source
- Namespace by subdirectory: `dotfiles/`, `git/`
- `#MISE` metadata required for descriptions, aliases
- Rebuild detection via `sources`/`outputs` optional but valuable for expensive tasks
- Verify tasks with `mise tasks` after deployment
