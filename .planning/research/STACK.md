# Stack Research

**Domain:** mise task runner for dotfiles operations and dev workflows
**Researched:** 2026-02-14
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| mise | 2026.2.11+ | Task runner, runtime manager | Already installed for runtime management; built-in task runner with parallel execution, incremental builds, and file-based task support. Native Rust performance. |
| chezmoi | 2.69.4+ | Dotfiles manager | Already in use managing 135 files; handles cross-platform templates, symlinks, and file deployment. |
| mise.toml | N/A | Task configuration | Central configuration file for mise tasks; supports TOML-based task definitions with rich metadata. |
| .mise/tasks/ | N/A | File-based task directory | Preferred for executable scripts; provides editor syntax highlighting, linting support, and better organisation via subdirectories. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| watchexec | Latest | File watching for mise watch | Required for `mise watch` command to automatically rebuild tasks on file changes. Optional for basic task execution. |
| bash/zsh | System default | Task script interpreter | Default shell for task execution. mise sets `-e` (errexit) automatically for sh/bash/zsh. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| #MISE comments | Task metadata in file-based tasks | Use `#MISE` or `# [MISE]` comments at top of executable files to define description, alias, depends, sources, outputs, env, tools. Formatters may change `#MISE` to `# MISE` (invalid), use `# [MISE]` for safety. |
| mise tasks ls | Task discovery and listing | Shows all available tasks from current directory hierarchy. Use `--all` for monorepo mode. |
| mise tasks deps | Dependency visualisation | Displays task dependency tree for debugging execution order. |
| mise run --dry-run | Execution preview | Shows task execution order without running them. Useful for validating dependencies. |

## Installation

```bash
# mise already installed via Homebrew
mise --version  # Should be 2026.2.11 or later

# Optional: Install watchexec for mise watch functionality
brew install watchexec

# No additional packages required - mise task runner is built-in
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| mise tasks | just (Justfile) | If you need a dedicated task runner not tied to version management, or if team is already familiar with just. |
| mise tasks | Taskfile (task) | If you prefer Go-based tooling or need Taskfile.yml for compatibility with existing workflows. |
| mise tasks | GNU Make | Never for new projects. Only if maintaining legacy projects with existing Makefiles. |
| mise tasks | npm scripts | Only for pure Node.js projects with no other language runtimes. Mise provides better cross-tool support. |
| .mise/tasks/ (file-based) | [tasks] in mise.toml | Use TOML-based tasks only for trivial one-liners where editor support isn't needed. File-based tasks preferred for multi-line scripts. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Tera template functions (arg(), option(), flag()) | Deprecated in mise 2026.5.0, removal in 2026.11.0 | Use `usage` field for task arguments. Arguments available as `$usage_*` environment variables. |
| Global `mise add` for tasks | Tasks should be project-scoped, not global | Define tasks in project's mise.toml or .mise/tasks/ directory. |
| Duplicating chezmoi run scripts | Avoid redundancy with existing chezmoi run_once scripts | Use mise tasks to orchestrate chezmoi operations, not replace chezmoi's built-in script execution. |
| .PHONY declarations | Not needed - mise task runner handles this automatically | Define tasks as files or in [tasks] section; mise doesn't require explicit PHONY declarations like Make. |
| Hardcoded paths in tasks | Breaks portability across machines | Use mise environment variables: `$MISE_PROJECT_ROOT`, `$MISE_CONFIG_ROOT`, `$MISE_TASK_DIR`, `$MISE_ORIGINAL_CWD`. |

## Stack Patterns by Variant

**If building dotfiles operations (apply, verify, update, sync, smoke-test):**
- Use file-based tasks in `.mise/tasks/dotfiles/`
- Configure `sources` to watch chezmoi source files
- Use `depends` to ensure prerequisites run first (e.g., verify depends on apply)
- Because: Dotfiles tasks are complex scripts benefiting from syntax highlighting; file watching enables automatic updates

**If building dev workflows (git helpers for conventional commits, branch cleanup, PR creation):**
- Use file-based tasks in `.mise/tasks/dev/`
- Leverage mise's automatic tool version inheritance (git, gh CLI)
- Use `usage` field for task arguments (e.g., commit message, branch name)
- Because: Git workflows require rich scripting; mise ensures consistent tool versions across machines

**If building environment bootstrap:**
- Use TOML-based tasks in mise.toml for orchestration
- File-based tasks for complex installation logic
- Use `depends` to order: install tools → configure shell → verify setup
- Because: Bootstrap needs clear dependency chain; TOML provides declarative overview while file tasks handle complexity

**If needing cross-machine deployment:**
- Manage mise.toml with chezmoi templates (.mise.toml.tmpl)
- Manage .mise/tasks/ as regular chezmoi source files
- Use chezmoi's .chezmoiignore if tasks should be machine-specific
- Because: chezmoi handles cross-platform differences; mise.toml templating enables per-machine task customisation

## Task Discovery Hierarchy

mise discovers tasks in this priority order:
1. **File tasks**: Executable files in task directories (mise-tasks, .mise-tasks, .mise/tasks, mise/tasks, .config/mise/tasks)
2. **TOML tasks**: Defined in mise.toml files ([tasks.name] sections)
3. **Parent directory tasks**: Available from parent directories (hierarchical inheritance)

File tasks in subdirectories are automatically namespaced:
- `.mise/tasks/build` → task name: `build`
- `.mise/tasks/test/integration` → task name: `test:integration`
- `.mise/tasks/dotfiles/apply` → task name: `dotfiles:apply`

## Task Configuration Options

### File-Based Task Configuration (via #MISE comments)

```bash
#!/usr/bin/env bash
#MISE description="Apply dotfiles to system"
#MISE alias="apply"
#MISE sources=[".local/share/chezmoi/**/*"]
#MISE depends=["dotfiles:verify"]
#MISE env={CHEZMOI_VERBOSE="1"}

# Task script here
```

### TOML-Based Task Configuration

```toml
[tasks.build]
description = "Build the project"
run = "cargo build"
sources = ["Cargo.toml", "src/**/*.rs"]
outputs = ["target/debug/mycli"]
depends = ["lint", "test"]
env = { RUST_BACKTRACE = "1" }
```

### Task Dependency Control

- `depends = ["task1", "task2"]` — Hard dependencies; if missing, task fails
- `wait_for = ["task1"]` — Soft dependencies; wait if running, but don't require
- `depends_post = ["task1"]` — Run after current task completes

### Incremental Build Support

```toml
sources = ["src/**/*.rs", "Cargo.toml"]  # Input files
outputs = ["target/debug/binary"]         # Output files
```

mise skips task execution if outputs are newer than sources (based on modification time).
Use `mise run --force` to override.

### Task Arguments (Recommended: usage field)

```toml
[tasks.test]
usage = 'arg "<file>" help="The file to test" default="src/main.rs"'
run = 'cargo test ${usage_file?}'
```

Arguments available as environment variables: `$usage_file`, `$usage_verbose`, etc.

## Task Execution Model

**Parallel execution:**
- Default: 4 parallel jobs
- Configure: `--jobs N`, `MISE_JOBS=N`, or `jobs` setting in mise.toml
- Automatic DAG (directed acyclic graph) creation ensures correct dependency order while maximising parallelism

**Environment inheritance:**
- Tasks automatically inherit tool versions from mise.toml
- Environment variables from `[env]` section available to all tasks
- Special variables: `MISE_PROJECT_ROOT`, `MISE_CONFIG_ROOT`, `MISE_TASK_DIR`, `MISE_ORIGINAL_CWD`, `MISE_TASK_NAME`, `MISE_TASK_FILE`

**Error handling:**
- Tasks run with `set -e` (errexit) for sh/bash/zsh
- Use `--continue-on-error` to run all tasks even if some fail
- Exit code propagation: task exit code becomes mise exit code

## Integration with chezmoi

**Deployment strategy:**

1. **mise.toml**: Manage as chezmoi template (`.mise.toml.tmpl`)
   - Enables per-machine customisation (macOS vs Linux)
   - Use chezmoi data variables for conditional tasks

2. **.mise/tasks/**: Manage as regular chezmoi source files
   - chezmoi creates `.mise/` directory in target location
   - Executable permissions preserved automatically
   - Cross-machine deployment via `chezmoi apply`

3. **.chezmoiignore**: Exclude machine-specific tasks
   ```
   # .chezmoiignore
   {{ if eq .chezmoi.os "darwin" }}
   .mise/tasks/linux/**
   {{ else if eq .chezmoi.os "linux" }}
   .mise/tasks/macos/**
   {{ end }}
   ```

**Avoiding duplication:**

- **DON'T**: Rewrite chezmoi run_once scripts as mise tasks
- **DO**: Use mise tasks to orchestrate chezmoi operations
- **DO**: Use mise tasks for workflows that span multiple tools (git + chezmoi)
- **DO**: Use chezmoi run_once for one-time system setup

**Example integration:**

```toml
# .mise.toml.tmpl
[tasks.dotfiles-apply]
run = "chezmoi apply --verbose"
sources = ["{{ .chezmoi.sourceDir }}/**/*"]

[tasks.dotfiles-update]
depends = ["dotfiles-apply"]
run = "chezmoi update"
```

## Remote Task Inclusion (Advanced)

```toml
# Include tasks from Git repository
[task-includes]
"company/shared-tasks" = "git::https://github.com/company/shared-tasks.git"
```

Tasks cached in `MISE_CACHE_DIR/remote-git-tasks-cache`. Clear with `mise cache clear`.
Disable caching: `MISE_TASK_REMOTE_NO_CACHE=true` or `--no-cache` flag.

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| mise@2026.2.11 | chezmoi@2.69.4 | No known compatibility issues. mise.toml can be managed as chezmoi template. |
| mise@2026.5.0+ | N/A | Deprecation warnings for Tera template functions in task arguments. |
| mise@2026.11.0 | N/A | Tera template functions removed. Must use `usage` field for arguments. |

## Sources

**HIGH confidence:**
- [Tasks Overview](https://mise.jdx.dev/tasks/) — Task system architecture, discovery, execution model
- [Task Configuration](https://mise.jdx.dev/tasks/task-configuration.html) — All configuration options (depends, wait_for, sources, outputs, env)
- [File Tasks](https://mise.jdx.dev/tasks/file-tasks.html) — File-based task format, #MISE comments, directory organisation
- [TOML Tasks](https://mise.jdx.dev/tasks/toml-tasks.html) — TOML-based task syntax and examples
- [Task Arguments](https://mise.jdx.dev/tasks/task-arguments.html) — usage field documentation, argument handling
- [Running Tasks](https://mise.jdx.dev/tasks/running-tasks.html) — Parallel execution, output modes, error handling
- [Task System Architecture](https://mise.jdx.dev/tasks/architecture.html) — DAG creation, dependency resolution
- [Monorepo Tasks](https://mise.jdx.dev/tasks/monorepo.html) — Subdirectory discovery, namespacing
- [mise watch](https://mise.jdx.dev/cli/watch.html) — Automatic rebuild on file changes
- [GitHub: jdx/mise](https://github.com/jdx/mise) — Official repository, version 2026.2.11 confirmed

**MEDIUM confidence:**
- [Deprecation Announcement: Tera Template Functions](https://github.com/jdx/mise/discussions/6766) — Timeline for argument handling changes
- [Introducing Monorepo Tasks](https://github.com/jdx/mise/discussions/6564) — Monorepo feature design and rationale
- [chezmoi: .chezmoiignore](https://www.chezmoi.io/reference/special-files/chezmoiignore/) — Pattern syntax for excluding files
- [chezmoi: Manage machine-to-machine differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/) — Template strategies

**WebSearch findings:**
- Multiple sources confirm mise task runner as replacement for make/npm scripts (HIGH agreement)
- mise 2026.2.11 release date: 2026-02-12 (confirmed via installed version)
- Parallel execution default: 4 jobs (consistent across documentation)
- File-based tasks preferred over TOML for multi-line scripts (community consensus)

---
*Stack research for: mise task runner integration*
*Researched: 2026-02-14*
