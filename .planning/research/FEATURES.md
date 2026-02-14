# Feature Research

**Domain:** mise Task Runner for Dotfiles Management and Dev Workflows
**Researched:** 2026-02-14
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| File-based tasks in `.mise/tasks/` | Standard convention for mise tasks, users expect this structure | LOW | Tasks are executable scripts in `.mise/tasks/`, `mise-tasks/`, `mise/tasks/`, or `.config/mise/tasks`. Must be executable. Subdirectories auto-prefix task names (e.g., `test/unit` → `test:unit`) |
| Task discovery via `mise tasks` | Users need to see what tasks are available | LOW | `mise tasks` lists current hierarchy, `mise tasks --all` lists entire monorepo. Task `description` field is critical for AI agent discoverability |
| Task composition with `depends` | Tasks need to chain together (e.g., `test` depends on `build`) | LOW | `depends` runs tasks first, fails if dependency fails. `depends_post` runs after main task. `wait_for` waits for optional dependencies |
| Environment variable injection | Tasks need access to project paths and context | LOW | Auto-injected: `MISE_PROJECT_ROOT`, `MISE_CONFIG_ROOT`, `MISE_ORIGINAL_CWD`, `MISE_TASK_NAME`, `MISE_TASK_DIR`. Custom env via `env` field |
| Task arguments via `usage` field | Tasks need to accept parameters | MEDIUM | Positional args: `arg "<name>"` (required), `arg "[name]"` (optional). Flags: `flag "--name"`. Available as `$usage_name` env vars. Tera templates deprecated in 2026.11.0 |
| Parallel execution by default | Users expect fast task runs | LOW | Default 4 parallel jobs, configurable via `--jobs`, `jobs` setting, or `MISE_JOBS`. Use `depends` to control execution order |
| Task aliases for short names | Users want `mise run b` not `mise run build` | LOW | Define `alias = "b"` in TOML or `#MISE alias="b"` in file tasks |
| Task hiding with `hide = true` | Internal helper tasks shouldn't clutter `mise tasks` output | LOW | Add `hide = true` to task config. Show with `mise tasks --hidden` |
| Cross-platform shell scripts | Dotfiles run on macOS and Linux | MEDIUM | Bash is default, but use shebang for other interpreters: `#!/usr/bin/env python`. Tasks run with `set -e` for sh/bash/zsh |
| Auto-installation of tools | Tasks should auto-install tools defined in mise.toml | LOW | File tasks now auto-install tools (2026 feature). Matches inline task behaviour |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| File-based rebuild detection with `sources`/`outputs` | Skip expensive tasks when files haven't changed | MEDIUM | Task only runs if newest source > oldest output (mtime comparison). Uses `sources = ['src/**/*.rs']`, `outputs = ['target/debug/mycli']` glob patterns |
| `mise watch` for auto-rebuild | Automatic task re-run on file changes | LOW | Uses `sources` from task definition. `mise watch build` watches sources and rebuilds on change. `-r` flag for continuous restart |
| Working directory control with `dir` | Run tasks in specific directories | LOW | Default: directory of `mise.toml`. Override with `dir = "{{cwd}}"` for user's current working directory. `MISE_TASK_DIR` available |
| Multiple interpreter support via shebang | Tasks in Python, Node, Ruby, etc. | MEDIUM | Use `#!/usr/bin/env python` or advanced `#!/usr/bin/env -S uv run --script` for multi-arg interpreters. Full script control |
| Monorepo task patterns | Discover and run tasks across subdirectories | HIGH | `experimental_monorepo_root` enables auto-discovery with path prefixing. Pattern-based execution with wildcards: `mise run test:**:local` |
| Task templates for monorepos | Reusable task definitions across projects | HIGH | Define at monorepo root, extend in subdirs. Reduces duplication for similar projects |
| Semantic grouping with colon namespacing | Organize tasks hierarchically (e.g., `test:unit`, `test:integration`, `git:commit`) | LOW | Convention: use colons for grouping. Enables pattern matching: `mise run test:**` runs all test tasks |
| Configurable concurrency control | Fine-tune parallel execution | MEDIUM | Default 4 jobs. Override with `--jobs N` or `MISE_JOBS`. `--raw` forces serial execution (jobs=1) for clean stdio |
| TOML-based task definition | Alternative to file-based tasks for inline config | LOW | Define in `mise.toml` with `[tasks.name]` sections. Good for simple tasks, file-based better for complex scripts |
| Task output control | Manage stdio connection | LOW | `--raw` connects stdin/stdout/stderr to terminal (forces serial). Default buffers output for parallel runs |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Tera template functions in scripts | Legacy feature for arguments | Deprecated in 2026.5.0, removed in 2026.11.0. Creates coupling to mise-specific syntax | Use `usage` field instead. Arguments become env vars (`$usage_name`). More standard, better shellcheck support |
| Complex task interdependencies | Want to orchestrate everything | Creates fragile dependency graphs, hard to debug, serial bottlenecks | Keep tasks focused. Use `depends` sparingly. Prefer composable small tasks that can run independently |
| Running tasks without description | Faster to write | AI agents (and humans) can't discover task purpose. `mise tasks ls` output useless | ALWAYS write descriptions. It's the ONLY context for discoverability. Answer: what, why, inputs, outputs, when to run |
| Using `mise run` for general automation | Task runner as catch-all script executor | mise tasks optimised for project workflows, not general automation. Overhead for simple scripts | Use tasks for project-specific workflows (build, test, deploy). Use shell functions/aliases for general commands |
| Global mise tasks | Want tasks available everywhere | Tasks tied to project context (MISE_PROJECT_ROOT). Global tasks lose context | Keep tasks in project directories. Use shell aliases/functions for global commands. mise is project-scoped |
| Mixing file and TOML tasks with same name | Want flexibility | Confusing which runs, override behaviour unclear | Pick one convention per project. File-based for complex, TOML for simple. Don't mix for same task name |

## Feature Dependencies

```
[Task Arguments (usage field)]
    └──requires──> [Environment Variable Injection]

[File-based Rebuild Detection]
    └──requires──> [sources/outputs configuration]
    └──enhances──> [mise watch]

[Parallel Execution]
    ──conflicts──> [--raw flag (forces serial)]

[depends]
    └──requires──> [Task Discovery]

[Monorepo Task Patterns]
    └──requires──> [experimental_monorepo_root setting]
    └──enhances──> [Semantic Grouping with Colons]

[Auto-install Tools]
    └──requires──> [Tools defined in mise.toml]

[Multiple Interpreters]
    └──requires──> [Shebang support]
    └──enhances──> [File-based Tasks]
```

### Dependency Notes

- **Task Arguments requires Environment Variable Injection:** Arguments defined in `usage` field become environment variables prefixed with `usage_`. The env injection system is foundational.
- **File-based Rebuild Detection enhances mise watch:** Watch uses the `sources` field to determine which files to monitor. Rebuild detection optimises when tasks run.
- **Parallel Execution conflicts with --raw flag:** Raw mode connects stdio to terminal, which requires serial execution to prevent output interleaving.
- **depends requires Task Discovery:** Can't depend on tasks that aren't discoverable. Task naming and location conventions enable dependency resolution.
- **Monorepo Task Patterns requires experimental setting:** Must enable `experimental_monorepo_root` in root `mise.toml`. Without it, subdirectory tasks aren't auto-discovered.
- **Auto-install Tools requires tools in mise.toml:** File tasks now auto-install tools, matching inline task behaviour. But tools must be defined in the config first.

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [x] File-based tasks in `.mise/tasks/` — Essential convention, enables all task functionality
- [x] Task discovery via `mise tasks` — Users need to see available tasks
- [x] Basic task descriptions — AI agent and human discoverability
- [x] Environment variable injection (`MISE_PROJECT_ROOT`, etc.) — Tasks need project context
- [x] Simple task composition with `depends` — Core workflow chaining (e.g., `verify` depends on `apply`)
- [x] Colon-based namespacing for organisation — `dotfiles:apply`, `git:commit`, etc. Clean structure
- [x] Bash script execution — Default interpreter, works everywhere
- [x] Task aliases — Short names for common operations (`mise run a` for `dotfiles:apply`)

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Task arguments via `usage` field — Add when tasks need parameters (e.g., `mise run git:commit "feat: message"`)
- [ ] File-based rebuild detection (`sources`/`outputs`) — Add when tasks become expensive and need smart skip logic
- [ ] `mise watch` integration — Add when rapid iteration workflows emerge
- [ ] Parallel execution tuning — Add if default 4 jobs causes issues or bottlenecks
- [ ] `depends_post` for cleanup tasks — Add when cleanup patterns emerge
- [ ] Task hiding with `hide = true` — Add when internal helper tasks clutter output
- [ ] Working directory control with `dir` — Add if tasks need to run from specific locations

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Multiple interpreter support (Python, Node) — Add only if non-bash workflows emerge
- [ ] Monorepo task patterns — Not applicable for single dotfiles repo
- [ ] Task templates — Not needed without monorepo
- [ ] TOML-based tasks — File-based sufficient, adds complexity
- [ ] Advanced concurrency control — Default behaviour sufficient
- [ ] `wait_for` optional dependencies — Rare use case, adds complexity

## Feature Prioritisation Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| File-based tasks in `.mise/tasks/` | HIGH | LOW | P1 |
| Task discovery and descriptions | HIGH | LOW | P1 |
| Environment variable injection | HIGH | LOW | P1 |
| Task composition with `depends` | HIGH | LOW | P1 |
| Colon-based namespacing | HIGH | LOW | P1 |
| Task aliases | MEDIUM | LOW | P1 |
| Task arguments via `usage` | MEDIUM | MEDIUM | P2 |
| File-based rebuild detection | MEDIUM | MEDIUM | P2 |
| `mise watch` integration | MEDIUM | LOW | P2 |
| Parallel execution tuning | LOW | LOW | P2 |
| Task hiding | LOW | LOW | P2 |
| Working directory control | LOW | LOW | P2 |
| Multiple interpreters | LOW | MEDIUM | P3 |
| Monorepo patterns | LOW | HIGH | P3 |
| TOML-based tasks | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch — Core task runner functionality
- P2: Should have, add when possible — Optimisations and ergonomics
- P3: Nice to have, future consideration — Not applicable or rare use cases

## Competitor Feature Analysis

| Feature | make (traditional) | just (modern alternative) | mise tasks (our approach) |
|---------|-------------------|---------------------------|---------------------------|
| Task definition | Makefile with targets | Justfile with recipes | `.mise/tasks/` directory + executable scripts OR `mise.toml` TOML tasks |
| Task discovery | `make help` (manual) | `just --list` | `mise tasks` / `mise tasks --all` |
| Dependencies | Prerequisites in target line | `recipe: dep1 dep2` | `depends = ["dep1", "dep2"]` in config or script comments |
| Parallel execution | `make -j4` | Sequential by default | Parallel by default (4 jobs), `--jobs N` to configure |
| File watching | External tools | `just --watch` | `mise watch taskname` using `sources` field |
| Rebuild detection | Timestamp-based (built-in) | Manual checks | `sources`/`outputs` with mtime comparison |
| Arguments | Makefile variables `make VAR=value` | Recipe parameters `just recipe arg` | `usage` field → `$usage_arg` env vars |
| Multiple interpreters | Shell only | Shell only | Any interpreter via shebang |
| Project context | Manual `$(pwd)` | `justfile_directory()` | Auto-injected `MISE_PROJECT_ROOT`, `MISE_CONFIG_ROOT` |
| Cross-platform | Poor (GNU make vs BSD make) | Good (written in Rust) | Good (written in Rust) |

**Our differentiation:**
- **Language-agnostic task execution:** Shebang support for Python, Node, Ruby, etc. (vs make/just shell-only)
- **Smart rebuild detection:** File-based `sources`/`outputs` with mtime checking (vs make's target-based approach)
- **Integrated with tool management:** Tasks auto-install tools from `mise.toml` (vs make/just separate tool installation)
- **Parallel by default:** Optimised for modern multi-core systems (vs make manual `-j`, just sequential)
- **AI agent friendly:** Task descriptions for discoverability (vs make/just manual docs)

## Implementation Patterns for This Project

### Dotfiles Operations Tasks

**Expected tasks:**
- `dotfiles:apply` — Run `chezmoi apply` with verification
- `dotfiles:verify` — Run `scripts/verify-configs.sh` (112 checks)
- `dotfiles:smoke-test` — Run `scripts/zsh-smoke-test.sh` (13 checks)
- `dotfiles:update-packages` — Update Homebrew packages via chezmoi run_onchange scripts
- `dotfiles:sync` — Composite task: verify → apply → smoke-test

**Complexity:** LOW-MEDIUM
- File-based tasks for scripts that already exist
- `depends` for composition (`sync` depends on `verify`, `apply`, `smoke-test`)
- No arguments needed initially
- Environment vars for paths (`MISE_PROJECT_ROOT`)

**Dependencies on existing infrastructure:**
- Relies on chezmoi being installed (via mise.toml tools)
- Wraps existing scripts (`verify-configs.sh`, `zsh-smoke-test.sh`)
- Homebrew automation already via chezmoi `run_onchange_` scripts

### Git Workflow Tasks

**Expected tasks:**
- `git:commit` — Conventional commit with Jira ticket prefix (`MLE-999: feat: message`)
- `git:branch` — Create feature branch with naming convention (`feature/MLE-999-description`)
- `git:cleanup` — Prune merged branches
- `git:pr` — Create pull request with template
- `git:bootstrap` — Set up git hooks (gitleaks), configure git settings

**Complexity:** MEDIUM
- Need arguments for commit messages, branch names (`usage` field)
- Interactive prompts for PR creation
- Integration with gh CLI for PR creation
- gitleaks hook installation (already exists globally)

**Dependencies on existing infrastructure:**
- gh CLI installed (add to mise.toml tools if needed)
- git obviously required
- Global gitleaks hooks already configured
- Branch naming conventions from CLAUDE.md

### Task Organisation Pattern

```
.mise/tasks/
├── dotfiles/
│   ├── apply          # chezmoi apply wrapper
│   ├── verify         # run verify-configs.sh
│   ├── smoke-test     # run zsh-smoke-test.sh
│   ├── update         # update Homebrew packages
│   └── sync           # composite: verify → apply → smoke-test
└── git/
    ├── commit         # conventional commit helper
    ├── branch         # create feature branch
    ├── cleanup        # prune merged branches
    ├── pr             # create pull request
    └── bootstrap      # setup git hooks and config
```

**Naming rationale:**
- Colon namespacing (`dotfiles:apply`, `git:commit`) from directory structure
- Short, action-oriented names
- Aliases for common operations: `apply` → `a`, `commit` → `c`, `pr` → `p`

### Cross-Platform Considerations

**macOS vs Linux:**
- Bash scripts portable across both
- Homebrew works on both (via chezmoi conditional scripts)
- Paths resolved via `MISE_PROJECT_ROOT` (cross-platform)
- Tool installation via mise.toml handles platform differences

**Implementation strategy:**
- Use `/usr/bin/env bash` shebang
- Avoid macOS-specific commands (prefer cross-platform alternatives)
- Use chezmoi's platform detection for platform-specific tasks (already implemented)
- Test on both platforms (existing infrastructure supports this)

## Sources

**Official mise documentation:**
- [Tasks Overview](https://mise.jdx.dev/tasks/)
- [File Tasks](https://mise.jdx.dev/tasks/file-tasks.html)
- [TOML-based Tasks](https://mise.jdx.dev/tasks/toml-tasks.html)
- [Task Configuration](https://mise.jdx.dev/tasks/task-configuration.html)
- [Running Tasks](https://mise.jdx.dev/tasks/running-tasks.html)
- [Task Arguments](https://mise.jdx.dev/tasks/task-arguments.html)
- [Task System Architecture](https://mise.jdx.dev/tasks/architecture.html)
- [Monorepo Tasks](https://mise.jdx.dev/tasks/monorepo.html)

**Community resources:**
- [Using mise-en-place for dotfiles — Sympolymathesy](https://v5.chriskrycho.com/notes/using-mise-en-place-for-dotfiles/)
- [Continuous Improvement in DevOps: Streamlining with chezmoi and mise](https://manuelchichi.com.ar/blog/personal-toolset-2025/)
- [Using Mise for All the Things](https://jarv.org/posts/mise/)
- [Getting Started with Mise | Better Stack Community](https://betterstack.com/community/guides/scaling-nodejs/mise-explained/)
- [Best Practices for Using Mise to Maintain Project Structure and Manage Environment Variables](https://combray.prose.sh/2025-11-26-mise-project-structure-env-vars)

**GitHub discussions:**
- [Introducing Monorepo Tasks · Discussion #6564](https://github.com/jdx/mise/discussions/6564)
- [Deprecation Announcement: Tera Template Functions for Task Arguments · Discussion #6766](https://github.com/jdx/mise/discussions/6766)
- [method for running tasks in series · Discussion #3761](https://github.com/jdx/mise/discussions/3761)

---
*Feature research for: mise Task Runner for Dotfiles Management and Dev Workflows*
*Researched: 2026-02-14*
