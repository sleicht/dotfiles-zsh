# Architecture Research: Mise Task Runner Integration

**Domain:** Dotfiles management with task runner integration
**Researched:** 2026-02-14
**Confidence:** HIGH

## Executive Summary

The mise task runner integrates with the existing chezmoi-based dotfiles architecture as a **deployment target**, not a source file. Task scripts are authored in the chezmoi source (`~/.local/share/chezmoi/.mise/tasks/`), deployed to the home directory (`~/.mise/tasks/`), and made available globally via mise's task discovery system. This creates a clean separation: chezmoi manages the source of truth and deployment, whilst mise provides the runtime execution environment with environment variables, dependency management, and cross-machine availability.

The architecture introduces **new components** (task files, task configuration) and **modified components** (global mise config.toml gains task settings), with integration points at deployment time (chezmoi apply) and runtime (mise task execution). The build order follows: chezmoi source → deployment → mise discovery → task availability.

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      SOURCE LAYER (chezmoi)                          │
├─────────────────────────────────────────────────────────────────────┤
│  ~/.local/share/chezmoi/                                             │
│  ├── .chezmoidata.yaml              # Package + tool data            │
│  ├── .chezmoi.yaml.tmpl             # Machine identity config        │
│  ├── private_dot_config/mise/       # Mise configuration             │
│  │   └── config.toml.tmpl           # Global mise config template    │
│  ├── dot_mise/                      # Task source (NEW)              │
│  │   └── tasks/                     # Task scripts                   │
│  │       ├── dotfiles/              # Dotfiles operations            │
│  │       ├── dev/                   # Development workflows          │
│  │       └── verify/                # Verification tasks             │
│  └── run_onchange_after_*.sh.tmpl  # Deployment scripts              │
│                                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                    DEPLOYMENT LAYER (chezmoi apply)                  │
├─────────────────────────────────────────────────────────────────────┤
│  1. Templates rendered → 2. Files deployed → 3. Run scripts executed │
│                                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                      TARGET LAYER (home directory)                   │
├─────────────────────────────────────────────────────────────────────┤
│  ~/                                                                   │
│  ├── .config/mise/                                                   │
│  │   └── config.toml               # Global mise configuration       │
│  ├── .mise/                         # Project-level mise (NEW)       │
│  │   └── tasks/                    # Executable task scripts         │
│  │       ├── dotfiles/             # mise run dotfiles:*             │
│  │       ├── dev/                  # mise run dev:*                  │
│  │       └── verify/               # mise run verify:*               │
│  └── .zsh.d/                       # Shell configuration              │
│      └── mise.zsh                  # Mise activation/completion      │
│                                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                      RUNTIME LAYER (mise)                            │
├─────────────────────────────────────────────────────────────────────┤
│  mise task discovery → task execution → env vars + tools injected    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │ Global tasks │  │ Project tasks│  │ Task runtime │               │
│  │ ~/.config/   │  │ ~/.mise/     │  │ + mise env   │               │
│  │ mise/tasks   │  │ tasks        │  │ + mise tools │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **chezmoi source** | Source of truth for all dotfiles including task scripts | Git repository at `~/.local/share/chezmoi/` |
| **dot_mise/tasks/** | Task script source files (versioned, templatable) | Shell scripts with `#MISE` comments for metadata |
| **config.toml.tmpl** | Global mise configuration template | TOML template using `.chezmoidata.yaml` data |
| **chezmoi run scripts** | Deployment automation (packages, permissions, caching) | `run_onchange_after_*.sh.tmpl` executed on apply |
| **~/.mise/tasks/** | Deployed task scripts (executable, discovered by mise) | File-based tasks with subdirectory prefixes |
| **mise runtime** | Task execution with env vars, tools, and dependencies | `mise run <task>` or `mise <task>` |
| **mise config** | Global tool versions, settings, and task behaviour | `~/.config/mise/config.toml` |

## Integration with Existing Architecture

### Unchanged Components

These components continue to function as before:

- **chezmoi source directory** (`~/.local/share/chezmoi/`): Still the source of truth
- **.chezmoidata.yaml**: Still contains package lists and tool versions
- **.chezmoi.yaml.tmpl**: Still handles machine identity and encryption
- **run scripts**: Still handle deployment automation
- **Shell configuration** (`zsh.d/*.zsh`): Still loaded by Sheldon
- **Sheldon plugins**: Still manage ZSH plugins
- **Existing mise config.toml**: Still manages global tool versions

### New Components

Components introduced by mise task runner:

1. **dot_mise/tasks/** (chezmoi source)
   - Location: `~/.local/share/chezmoi/dot_mise/tasks/`
   - Purpose: Source files for task scripts
   - Managed by: chezmoi (versioned, templatable)
   - Deployed to: `~/.mise/tasks/` (home directory)

2. **Task scripts** (executable shell scripts)
   - Format: Shell scripts with `#MISE` metadata comments
   - Naming: Executable files in task directories
   - Organisation: Subdirectories create task prefixes (`dotfiles/apply` → `dotfiles:apply`)

3. **~/.mise/tasks/** (deployment target)
   - Location: Home directory (outside chezmoi source)
   - Purpose: Runtime task discovery location
   - Populated by: chezmoi apply
   - Discovered by: mise task system

### Modified Components

Components that gain new capabilities:

1. **config.toml.tmpl** (mise global config)
   - **Before**: Tool versions and settings only
   - **After**: + task behaviour settings (jobs, output mode)
   - **New settings**: Task-specific configuration from `.chezmoidata.yaml`

2. **run scripts**
   - **Before**: Package installation, cleanup, permissions
   - **After**: + potential task-based replacements (see evolution path)

3. **.chezmoidata.yaml**
   - **Before**: Package lists, tool versions
   - **After**: + task configuration data (if task metadata is templated)

## Integration Points

### 1. Deployment-Time Integration (chezmoi → mise)

**When:** `chezmoi apply` or `chezmoi update`

**What happens:**
```
1. chezmoi renders templates (config.toml.tmpl, task scripts if templated)
2. chezmoi deploys files:
   - dot_mise/tasks/* → ~/.mise/tasks/*
   - config.toml.tmpl → ~/.config/mise/config.toml
3. chezmoi sets execute permissions on task scripts
4. chezmoi runs run_onchange_after_* scripts
```

**Key behaviour:**
- Task scripts deployed to `~/.mise/tasks/` (project-level tasks for home directory)
- Scripts must be executable (chezmoi's `executable_` prefix or chmod in run script)
- No special mise invocation needed—tasks become available immediately after deployment

### 2. Runtime Integration (mise → environment)

**When:** `mise run <task>` or `mise <task>`

**What happens:**
```
1. mise discovers tasks:
   - Global: ~/.config/mise/tasks/*
   - Project: ~/.mise/tasks/*
   - Directory-specific: .mise/tasks/* (if in project directory)
2. mise loads environment:
   - Tool versions from mise.toml or config.toml
   - Environment variables from [env] sections
   - Task-specific env vars from task metadata
3. mise executes task:
   - Sets MISE_* environment variables
   - Runs task with mise-managed tools in PATH
   - Handles dependencies, sources, outputs
```

**Key behaviour:**
- Tasks in `~/.mise/tasks/` are available globally (anywhere in shell)
- Tasks can use mise-managed tools (node, python, etc.) without version conflicts
- Task execution includes mise environment (env vars, tool paths)

### 3. Data Flow Integration

**Configuration data flow:**
```
.chezmoidata.yaml
    ↓ (template rendering)
config.toml.tmpl → ~/.config/mise/config.toml
                       ↓ (read by mise)
                   mise runtime
```

**Task deployment flow:**
```
~/.local/share/chezmoi/dot_mise/tasks/dotfiles/apply
    ↓ (chezmoi apply)
~/.mise/tasks/dotfiles/apply
    ↓ (mise discovery)
Available as: mise run dotfiles:apply
```

### 4. Verification Integration

**Pattern:** Task-based verification (future evolution)

```
Current: scripts/verify-configs.sh + scripts/verify-checks/*.sh
Future:  mise run verify:configs (orchestrator task)
         ├── mise run verify:shell
         ├── mise run verify:packages
         └── mise run verify:permissions
```

## Recommended Project Structure

### Task Directory Organisation

```
~/.local/share/chezmoi/dot_mise/tasks/
├── dotfiles/                   # Dotfiles operations (mise run dotfiles:*)
│   ├── executable_apply        # mise run dotfiles:apply
│   ├── executable_update       # mise run dotfiles:update
│   ├── executable_diff         # mise run dotfiles:diff
│   └── executable_backup       # mise run dotfiles:backup
├── dev/                        # Development workflows (mise run dev:*)
│   ├── executable_setup        # mise run dev:setup
│   ├── executable_clean        # mise run dev:clean
│   └── executable_lint         # mise run dev:lint
├── verify/                     # Verification tasks (mise run verify:*)
│   ├── executable__default     # mise run verify (default task)
│   ├── executable_shell        # mise run verify:shell
│   ├── executable_packages     # mise run verify:packages
│   └── executable_permissions  # mise run verify:permissions
└── tools/                      # Tool management (mise run tools:*)
    ├── executable_update       # mise run tools:update
    └── executable_cleanup      # mise run tools:cleanup
```

### Naming Conventions

**chezmoi naming (source files):**
- `executable_<name>`: Creates executable file (preferred for tasks)
- `dot_mise/tasks/`: Creates `.mise/tasks/` in home directory
- Subdirectories: Create task prefixes automatically

**mise naming (deployed tasks):**
- `dotfiles/apply` → task name: `dotfiles:apply`
- `verify/_default` → task name: `verify` (default task in directory)
- Colon-separated prefixes: `category:action` convention

### Structure Rationale

- **Subdirectories by category**: Groups related tasks (dotfiles ops, dev workflows, verification)
- **Prefix-based namespacing**: mise automatically creates `category:action` names from `category/action` paths
- **Default tasks**: `_default` files allow `mise run verify` instead of requiring `mise run verify:_default`
- **Executable prefix in source**: Ensures tasks are executable after deployment (chezmoi sets permissions)

## Architectural Patterns

### Pattern 1: File-Based Tasks with Metadata

**What:** Executable shell scripts with `#MISE` comment headers for configuration

**When to use:** Default choice for all tasks—better editor support, non-mise user compatibility

**Trade-offs:**
- **Pros**: Syntax highlighting, linting, works without mise, clean separation
- **Cons**: Metadata in comments (not validated until runtime)

**Example:**
```bash
#!/usr/bin/env bash
#MISE description="Apply dotfiles configuration"
#MISE depends=["dotfiles:backup"]
#MISE sources=[".chezmoidata.yaml", ".chezmoi.yaml.tmpl"]
#MISE alias="apply"

set -euo pipefail

# Task logic
chezmoi apply --verbose
```

**Deployment:** Place in `~/.local/share/chezmoi/dot_mise/tasks/dotfiles/executable_apply`

**Result:** Available as `mise run dotfiles:apply` or `mise run apply` (via alias)

### Pattern 2: Task Dependencies with Shared State

**What:** Tasks that depend on other tasks, sharing environment variables and results

**When to use:** Multi-step workflows (backup → apply → verify), orchestration tasks

**Trade-offs:**
- **Pros**: Clear dependency graph, automatic ordering, parallel execution where possible
- **Cons**: Debugging can be harder with complex dependency chains

**Example:**
```bash
#!/usr/bin/env bash
#MISE description="Full dotfiles update workflow"
#MISE depends=["dotfiles:backup", "dotfiles:pull", "dotfiles:apply", "verify:all"]

# This task runs after all dependencies succeed
echo "Dotfiles update complete. Backup, pull, apply, and verification successful."
```

**Key behaviour:**
- Dependencies run in dependency order (backup → pull → apply → verify)
- If any dependency fails, this task does not run
- Parallel execution where dependencies allow (mise determines safe parallelism)

### Pattern 3: Source/Output Tracking for Caching

**What:** Tasks with `#MISE sources` and `#MISE outputs` for smart re-running

**When to use:** Expensive tasks (compilation, generation) that should skip if inputs unchanged

**Trade-offs:**
- **Pros**: Significant time savings for expensive operations
- **Cons**: Requires careful source/output specification, can skip when shouldn't if misconfigured

**Example:**
```bash
#!/usr/bin/env bash
#MISE description="Generate ZSH completions from mise"
#MISE sources=["~/.config/mise/config.toml"]
#MISE outputs=["~/.local/share/zsh/site-functions/_mise"]

# Only runs if config.toml newer than _mise completion file
mise completion zsh > ~/.local/share/zsh/site-functions/_mise
```

**Key behaviour:**
- mise compares modification times: newest source vs oldest output
- Task skipped if output newer than all sources
- Ideal for generated files that only change when config changes

## Data Flow

### Task Deployment Flow

```
Developer Action: Edit task in chezmoi source
    ↓
~/.local/share/chezmoi/dot_mise/tasks/dotfiles/apply
    ↓ (git commit)
Source control (versioned, backed up)
    ↓ (on any machine: chezmoi update)
chezmoi pull from remote
    ↓ (chezmoi apply)
~/.mise/tasks/dotfiles/apply (deployed, executable)
    ↓ (mise task discovery)
Task available: mise run dotfiles:apply
```

### Task Execution Flow

```
User Command: mise run dotfiles:apply
    ↓
mise discovers task in ~/.mise/tasks/dotfiles/apply
    ↓
mise reads task metadata (#MISE comments)
    ↓
mise loads environment:
    - Tool versions from ~/.config/mise/config.toml
    - Env vars from mise.toml [env] (if exists)
    - Task-specific env vars from metadata
    ↓
mise sets MISE_* environment variables:
    - MISE_ORIGINAL_CWD (where command was run)
    - MISE_CONFIG_ROOT (~/.config/mise or project root)
    - MISE_PROJECT_ROOT (home directory)
    - MISE_TASK_NAME (dotfiles:apply)
    - MISE_TASK_DIR (~/.mise/tasks/dotfiles)
    ↓
mise executes task script:
    - With mise-managed tools in PATH
    - With environment variables set
    - With dependencies resolved (if specified)
    ↓
Task output (line-buffered, prefixed with task name)
```

### Cross-Machine Synchronisation Flow

```
Machine A: Create/edit task
    ↓
chezmoi source: ~/.local/share/chezmoi/dot_mise/tasks/dev/setup
    ↓ (git commit + push)
Remote repository (GitHub, GitLab, etc.)
    ↓ (on Machine B: chezmoi update)
Machine B: chezmoi pull + apply
    ↓
Machine B: ~/.mise/tasks/dev/setup (deployed)
    ↓
Machine B: mise run dev:setup (available immediately)
```

## Relationship with Chezmoi Run Scripts

### Current Run Scripts (Unchanged)

These continue to function as deployment automation:

| Script | Purpose | Timing | Stays |
|--------|---------|--------|-------|
| `run_once_before_install-homebrew.sh.tmpl` | Install Homebrew | Once, before deployment | Yes |
| `run_onchange_after_01-install-packages.sh.tmpl` | Install Homebrew packages | When .chezmoidata.yaml changes | Yes |
| `run_onchange_after_02-cleanup-packages.sh.tmpl` | Remove untracked packages | When .chezmoidata.yaml changes | Yes |
| `run_onchange_after_03-clear-evalcache.sh.tmpl` | Invalidate evalcache | When configs change | Yes |
| `run_after_10-verify-permissions.sh.tmpl` | Verify file permissions | After every apply | Yes |
| `run_once_after_generate-mise-completions.sh.tmpl` | Generate mise completions | Once after install | Yes |
| `run_once_after_cleanup-homebrew-runtimes.sh.tmpl` | Remove redundant Homebrew tools | Once (migration) | Yes |

**Why they stay:** These are **deployment-time operations** triggered by chezmoi apply, not **user-invoked workflows**.

### Future Evolution Path (Optional)

**Task-based alternatives** (can coexist with run scripts):

| Run Script | Equivalent Mise Task | When to Use Task |
|------------|---------------------|-----------------|
| Manual package install | `mise run dotfiles:install-packages` | User wants to install packages without full apply |
| Manual verification | `mise run verify:all` | User wants to verify config without deployment |
| N/A | `mise run dotfiles:backup` | New capability: backup before risky operations |
| N/A | `mise run dotfiles:diff` | New capability: preview changes before apply |

**Pattern:** Run scripts remain for automatic deployment; tasks provide **user-facing workflows**.

**Example coexistence:**
```bash
# Automatic (during chezmoi apply)
run_onchange_after_01-install-packages.sh.tmpl

# Manual (user-invoked)
mise run dotfiles:install-packages  # Same logic, user-triggered
```

**Implementation:** Run script calls task (single source of truth):
```bash
#!/bin/bash
# run_onchange_after_01-install-packages.sh.tmpl
mise run dotfiles:install-packages
```

## Configuration Evolution

### Current: config.toml.tmpl

```toml
# ~/.local/share/chezmoi/private_dot_config/mise/config.toml.tmpl
[tools]
node = "lts"
python = "3.12"
# ... other tools from .chezmoidata.yaml

[settings]
not_found_auto_install = true
exec_auto_install = true
jobs = 4

[env]
# Global environment variables
```

### After Task Integration

```toml
# ~/.local/share/chezmoi/private_dot_config/mise/config.toml.tmpl
[tools]
node = "lts"
python = "3.12"
# ... other tools from .chezmoidata.yaml

[settings]
not_found_auto_install = true
exec_auto_install = true
jobs = 4

# Task-specific settings (NEW)
task_output = "prefix"  # prefix | interleave | quiet
task_jobs = 4           # max parallel tasks

[env]
# Global environment variables (available to all tasks)
EDITOR = "nvim"
VISUAL = "nvim"

# Optional: Task aliases for frequently used commands (NEW)
[tasks.apply]
alias = "a"
run = "chezmoi apply --verbose"

[tasks.update]
alias = "u"
depends = ["dotfiles:backup", "dotfiles:pull", "dotfiles:apply"]
```

**Key additions:**
- **task_output**: Controls task output formatting
- **task_jobs**: Max parallel task execution
- **[tasks.*]**: Optional inline task definitions for simple tasks
- **[env]**: Env vars available to all tasks

**Note:** Most tasks will be file-based in `dot_mise/tasks/`, not inline in config.toml.

## Anti-Patterns

### Anti-Pattern 1: Duplicating Run Scripts as Tasks

**What people do:** Convert every run script to a task immediately

**Why it's wrong:** Run scripts are deployment automation; tasks are user workflows. Not all run scripts need task equivalents.

**Do this instead:**
- Keep run scripts for deployment automation (`run_onchange_after_*`)
- Create tasks for **user-invoked workflows** (backup, diff, verify)
- Let run scripts **call tasks** if logic needs to be shared

**Example:**
```bash
# WRONG: Duplicate logic
# run_onchange_after_install.sh.tmpl
brew bundle --global

# .mise/tasks/dotfiles/install
brew bundle --global

# RIGHT: Run script calls task (single source)
# run_onchange_after_install.sh.tmpl
mise run dotfiles:install

# .mise/tasks/dotfiles/install (source of truth)
brew bundle --global
```

### Anti-Pattern 2: Storing Tasks Outside Chezmoi Source

**What people do:** Manually create tasks in `~/.mise/tasks/` and forget to add to chezmoi source

**Why it's wrong:** Tasks not in chezmoi source aren't versioned, backed up, or synced across machines

**Do this instead:**
- **Always** create tasks in chezmoi source: `~/.local/share/chezmoi/dot_mise/tasks/`
- Let chezmoi deploy to `~/.mise/tasks/`
- Edit with `chezmoi edit ~/.mise/tasks/<task>` (edits source, not deployed file)

**Verification:**
```bash
# WRONG: Direct edit
nvim ~/.mise/tasks/dotfiles/apply  # Not in chezmoi source!

# RIGHT: Edit via chezmoi
chezmoi edit ~/.mise/tasks/dotfiles/apply  # Edits source file
# Or edit source directly
nvim ~/.local/share/chezmoi/dot_mise/tasks/dotfiles/executable_apply
```

### Anti-Pattern 3: Complex Logic in TOML Tasks

**What people do:** Define multi-line shell scripts in `run = """..."""` blocks in mise.toml

**Why it's wrong:** No syntax highlighting, no linting, hard to maintain, not usable without mise

**Do this instead:** Use file-based tasks for anything more than a one-liner

**Example:**
```toml
# WRONG: Complex logic in TOML
[tasks.complex]
run = """
set -euo pipefail
if [ -f ~/.zshrc ]; then
  source ~/.zshrc
fi
chezmoi apply --verbose
"""

# RIGHT: File-based task
# .mise/tasks/dotfiles/executable_apply
#!/usr/bin/env bash
#MISE description="Apply dotfiles"
set -euo pipefail

if [ -f ~/.zshrc ]; then
  source ~/.zshrc
fi
chezmoi apply --verbose
```

### Anti-Pattern 4: Not Using Task Dependencies

**What people do:** Manually chain tasks with `&&` or create monolithic tasks

**Why it's wrong:** Loses parallel execution, no automatic dependency ordering, brittle

**Do this instead:** Use `#MISE depends` for clear dependency graphs

**Example:**
```bash
# WRONG: Manual chaining
#!/usr/bin/env bash
mise run dotfiles:backup && mise run dotfiles:pull && mise run dotfiles:apply

# RIGHT: Dependency declaration
#!/usr/bin/env bash
#MISE description="Full dotfiles update"
#MISE depends=["dotfiles:backup", "dotfiles:pull", "dotfiles:apply"]

echo "All dependencies completed successfully"
```

**Why better:** mise handles execution order, parallelism, and failure handling automatically.

## Build Order and Dependencies

### Deployment Order (chezmoi apply)

```
1. Before scripts (run_once_before_*, run_before_*)
   └── Install Homebrew if missing

2. Files/directories/symlinks deployed
   ├── .config/mise/config.toml (from config.toml.tmpl)
   ├── .mise/tasks/* (from dot_mise/tasks/*)
   ├── .zsh.d/* (shell configuration)
   └── Other dotfiles

3. After scripts (run_once_after_*, run_onchange_after_*, run_after_*)
   ├── Install/cleanup packages (if .chezmoidata.yaml changed)
   ├── Clear evalcache (if configs changed)
   ├── Generate mise completions (once)
   └── Verify permissions (always)
```

**Key dependencies:**
- Tasks deployed (step 2) **before** run_after scripts (step 3)
- mise config deployed **before** tasks executed
- Homebrew installed **before** package installation
- Files deployed **before** permission verification

### Runtime Discovery Order (mise task execution)

```
1. mise discovers tasks (when mise activated in shell)
   ├── Global: ~/.config/mise/tasks/*
   ├── Project: ~/.mise/tasks/*
   └── Directory-specific: .mise/tasks/* (if in project dir)

2. Task name resolution
   ├── Subdirectories create prefixes (dotfiles/apply → dotfiles:apply)
   ├── _default files create directory-level tasks (verify/_default → verify)
   └── Aliases from config.toml or task metadata

3. Task execution (on mise run <task>)
   ├── Load global config (~/.config/mise/config.toml)
   ├── Load project config (mise.toml, if exists)
   ├── Load environment variables ([env] sections + task metadata)
   ├── Resolve dependencies (depends= in task metadata)
   ├── Check sources/outputs (skip if outputs newer)
   └── Execute task with mise environment
```

### Cross-Machine Sync Order

```
1. Machine A: Edit task in chezmoi source
2. Machine A: git commit + push to remote
3. Machine B: chezmoi update (pulls from remote)
4. Machine B: chezmoi apply (deploys tasks)
5. Machine B: Tasks immediately available (mise discovers on next shell invocation)
```

**No manual mise commands needed:** Task availability is automatic after chezmoi apply.

## New vs Modified Component Summary

### New Components (Created by This Integration)

| Component | Location | Purpose | Managed By |
|-----------|----------|---------|------------|
| `dot_mise/` | Chezmoi source | Task script source directory | Chezmoi |
| `dot_mise/tasks/` | Chezmoi source | Task scripts (versioned) | Chezmoi + Git |
| `~/.mise/` | Home directory | Project-level mise directory | Deployed by chezmoi |
| `~/.mise/tasks/` | Home directory | Deployed task scripts (executable) | Deployed by chezmoi, discovered by mise |
| Task scripts | `~/.mise/tasks/**/*` | Executable shell scripts with metadata | Written in source, deployed by chezmoi, run by mise |

### Modified Components (Gain New Capabilities)

| Component | Location | Before | After | Change |
|-----------|----------|--------|-------|--------|
| `config.toml.tmpl` | Chezmoi source | Tool versions, settings | + task settings (jobs, output) | Add `[settings]` task config |
| Deployed `config.toml` | `~/.config/mise/` | Runtime tool config | + runtime task config | Rendered from template |
| `.chezmoidata.yaml` | Chezmoi source | Package lists, tool versions | + optional task metadata | Add task config data if needed |

### Unchanged Components (No Changes Needed)

| Component | Location | Purpose |
|-----------|----------|---------|
| `.chezmoi.yaml.tmpl` | Chezmoi source | Machine identity, encryption, Bitwarden |
| `run_*` scripts | Chezmoi source | Deployment automation |
| `zsh.d/*.zsh` | Chezmoi source | Shell configuration (already has mise.zsh) |
| Sheldon config | `~/.config/sheldon/plugins.toml` | Plugin management |
| Existing mise tools | `[tools]` in config.toml | Runtime version management |

## Sources

### Mise Official Documentation (HIGH confidence)
- [Tasks | mise-en-place](https://mise.jdx.dev/tasks/) - Task runner overview
- [File Tasks | mise-en-place](https://mise.jdx.dev/tasks/file-tasks.html) - File-based task documentation
- [TOML-based Tasks | mise-en-place](https://mise.jdx.dev/tasks/toml-tasks.html) - Inline task configuration
- [Task Configuration | mise-en-place](https://mise.jdx.dev/tasks/task-configuration.html) - Task metadata and settings
- [Running Tasks | mise-en-place](https://mise.jdx.dev/tasks/running-tasks.html) - Task execution and discovery
- [Monorepo Tasks | mise-en-place](https://mise.jdx.dev/tasks/monorepo.html) - Subdirectory prefixes
- [Configuration | mise-en-place](https://mise.jdx.dev/configuration.html) - Global vs project config
- [Environments | mise-en-place](https://mise.jdx.dev/environments/) - Environment variable management

### Chezmoi Official Documentation (HIGH confidence)
- [Use scripts to perform actions - chezmoi](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) - Run script types and execution order
- [Target types - chezmoi](https://www.chezmoi.io/reference/target-types/) - File naming and attributes

### Integration Patterns (MEDIUM confidence)
- [mizchi/chezmoi-dotfiles](https://github.com/mizchi/chezmoi-dotfiles) - Real-world mise + chezmoi integration
- [Managing dotfiles with Chezmoi | Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/) - Dotfiles management patterns

### Community Resources (MEDIUM confidence)
- [Getting Started with Mise | Better Stack Community](https://betterstack.com/community/guides/scaling-nodejs/mise-explained/) - Mise task runner guide
- [Using Mise for All the Things | jarv.org](https://jarv.org/posts/mise/) - Task and environment management patterns

---
*Architecture research for: Mise task runner integration with chezmoi dotfiles*
*Researched: 2026-02-14*
