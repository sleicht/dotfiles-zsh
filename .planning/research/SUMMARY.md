# Project Research Summary

**Project:** mise Task Runner Integration for Dotfiles Management
**Domain:** Developer workflow automation for dotfiles
**Researched:** 2026-02-14
**Confidence:** HIGH

## Executive Summary

mise is a modern task runner built into the version management tool already used in this dotfiles setup. Research confirms that mise tasks integrate cleanly with the existing chezmoi-based dotfiles architecture by serving as a deployment target rather than a source of truth. Task scripts live in the chezmoi source directory (`~/.local/share/chezmoi/dot_mise/tasks/`), get deployed to the home directory (`~/.mise/tasks/`), and become globally available via mise's task discovery system. This creates a clean separation: chezmoi manages configuration source and deployment whilst mise provides runtime execution with environment variables, dependency management, and cross-machine availability.

The recommended approach is to start with file-based tasks organised by workflow category (dotfiles operations, git helpers, verification tasks) using mise's automatic namespacing. File-based tasks provide syntax highlighting, linting support, and work without mise installed, making them superior to TOML-based tasks for anything beyond one-liners. The architecture follows proven patterns from the mise community: tasks as executable shell scripts with metadata in comments, dependency chains via `depends`, and incremental builds using `sources/outputs` for expensive operations.

The primary risks centre around shell startup performance regression (mise activation adds ~100ms), PATH pollution from multiple tool managers, and the temptation to duplicate existing chezmoi run scripts. These are mitigated by conditional mise activation in interactive shells only, establishing clear PATH precedence order documented in code, and treating run scripts as deployment automation whilst tasks serve as user-facing workflows. The migration is low-risk because mise tasks are purely additive—existing workflows continue to function whilst new capabilities are layered on top.

## Key Findings

### Recommended Stack

mise 2026.2.11+ provides a built-in task runner that replaces traditional make/just approaches. The task system supports both file-based tasks (executable scripts with metadata comments) and TOML-based tasks (inline definitions). Research strongly favours file-based tasks for this use case because they provide editor syntax highlighting, work without mise installed, and support complex scripting logic.

**Core technologies:**
- **mise 2026.2.11+**: Task runner and runtime manager — Already installed, provides native Rust performance with parallel execution, incremental builds via sources/outputs, and automatic tool installation
- **chezmoi 2.69.4+**: Dotfiles deployment — Already managing 135 files; handles task script deployment via standard chezmoi mechanisms (templates, symlinks, file deployment)
- **File-based tasks in .mise/tasks/**: Executable task scripts — Preferred over TOML for multi-line scripts; provides syntax highlighting, linting support, and better organisation via subdirectories
- **mise.toml or config.toml**: Task configuration — Central configuration for global task settings (parallel jobs, output mode); task definitions should primarily live in files, not TOML

**Supporting capabilities:**
- Automatic task namespacing via directory structure (`.mise/tasks/dotfiles/apply` → `mise run dotfiles:apply`)
- Task dependency resolution with `depends`, `wait_for`, and `depends_post`
- Smart rebuild detection using `sources`/`outputs` with modification time comparison
- Environment variable injection: `MISE_PROJECT_ROOT`, `MISE_CONFIG_ROOT`, `MISE_TASK_DIR`
- Task arguments via `usage` field (deprecates old Tera template approach in 2026.11.0)

### Expected Features

Research identified clear distinction between table stakes features that users expect from any task runner and differentiating features that make mise competitive with alternatives like make, just, or npm scripts.

**Must have (table stakes):**
- File-based tasks in `.mise/tasks/` with subdirectory organisation
- Task discovery via `mise tasks` with descriptions for AI agent discoverability
- Basic task composition using `depends` for workflow chaining
- Environment variable injection for project context
- Colon-based namespacing from directory structure (`dotfiles:apply`, `git:commit`)
- Task aliases for short names (`mise run a` instead of `mise run dotfiles:apply`)
- Cross-platform shell scripts (macOS and Linux compatibility)

**Should have (competitive advantages):**
- File-based rebuild detection with `sources`/`outputs` to skip expensive operations when files unchanged
- `mise watch` for automatic task re-run on file changes (requires watchexec)
- Working directory control via `dir` field
- Multiple interpreter support via shebang (Python, Node, Ruby scripts as tasks)
- Semantic grouping with colon namespacing patterns for hierarchical organisation
- Parallel execution by default (4 jobs) with configurable concurrency

**Defer (v2+):**
- TOML-based task definitions (file-based tasks are sufficient for this use case)
- Monorepo task patterns (not applicable for single dotfiles repository)
- Task templates (only useful in monorepo contexts)
- Advanced concurrency control (default 4 parallel jobs is sufficient)
- Multiple interpreter workflows (bash is adequate for dotfiles operations)

**Anti-features to avoid:**
- Tera template functions in scripts (deprecated 2026.5.0, removed 2026.11.0)
- Complex task interdependencies (creates fragile dependency graphs)
- Running tasks without descriptions (breaks discoverability for AI agents and humans)
- Global mise tasks (tasks should be project-scoped)
- Duplicating chezmoi run scripts as tasks (run scripts are deployment automation, tasks are user workflows)

### Architecture Approach

The mise task runner integrates with the existing chezmoi dotfiles architecture as a **deployment target**. Task scripts are authored in the chezmoi source directory, deployed to the home directory during `chezmoi apply`, and discovered by mise at runtime. This creates clean separation: chezmoi owns the source of truth and deployment, whilst mise provides runtime execution environment.

**Major components:**

1. **chezmoi source layer** (`~/.local/share/chezmoi/dot_mise/tasks/`) — Source of truth for task scripts, versioned in Git, managed by chezmoi, deployed as regular files with executable permissions preserved

2. **Deployment layer** (chezmoi apply process) — Templates rendered, files deployed to `~/.mise/tasks/`, executable permissions set, run scripts executed for deployment automation

3. **Target layer** (`~/.mise/tasks/`) — Deployed task scripts discovered by mise, available globally in any shell, organised by subdirectory into namespaced task names

4. **Runtime layer** (mise execution) — Task discovery from global and project directories, environment variable injection, tool version management, parallel execution with dependency resolution

**Integration points:**
- **Deployment-time**: chezmoi deploys task scripts from source to `~/.mise/tasks/` during apply
- **Runtime**: mise discovers tasks and executes with injected environment variables and mise-managed tools
- **Cross-machine sync**: Git repository → chezmoi source → deployment → task availability (automatic after chezmoi apply)

**Key architectural patterns:**
- File-based tasks with `#MISE` metadata comments for configuration (description, depends, sources, outputs)
- Task dependencies with shared state via environment variables
- Source/output tracking for incremental builds and caching
- Separation of deployment automation (run scripts) from user-facing workflows (tasks)

### Critical Pitfalls

Research identified migration risks from similar chezmoi/mise adoption patterns and dotfiles management anti-patterns.

1. **Duplicating chezmoi run scripts as tasks** — Run scripts are deployment automation triggered by `chezmoi apply`; tasks are user-invoked workflows. Don't convert every run script to a task immediately. Instead, keep run scripts for deployment automation and create tasks only for user-facing workflows (backup, diff, verify). If logic must be shared, let run scripts call tasks (single source of truth).

2. **Shell startup performance regression** — `eval "$(mise activate zsh)"` can add 100-200ms to shell startup. Mitigate by using conditional activation in interactive shells only, caching activation output, or using shims for non-interactive contexts. Profile with `zprof` to identify actual impact. Target: < 300ms total shell startup time.

3. **PATH pollution and wrong precedence order** — Multiple tools (Homebrew, mise, system) prepending to PATH causes wrong tool versions to execute or duplicate PATH entries. Establish clear precedence order: user local bins → mise shims → Homebrew → system paths. Use idempotent PATH additions or ZSH's `typeset -U path` for unique values.

4. **Storing tasks outside chezmoi source** — Manually creating tasks in `~/.mise/tasks/` bypasses version control and cross-machine sync. Always create tasks in chezmoi source (`~/.local/share/chezmoi/dot_mise/tasks/`), edit via `chezmoi edit`, and let chezmoi deploy. Never edit deployed files directly.

5. **Complex logic in TOML tasks** — Multi-line shell scripts in `run = """..."""` blocks lack syntax highlighting, linting, and portability. Use file-based tasks for anything more than a one-liner. File tasks work without mise installed and get full editor support.

## Implications for Roadmap

Based on research, the implementation should follow a conservative, incremental approach that layers mise tasks onto the existing stable dotfiles architecture without disrupting current workflows.

### Phase 1: Foundation (Task Infrastructure)

**Rationale:** Establish basic task directory structure and deployment pipeline before adding any task logic. This validates the chezmoi → mise integration works correctly and sets naming conventions.

**Delivers:**
- `.mise/tasks/` directory structure in chezmoi source
- Minimal "hello world" tasks to verify deployment
- Task discovery working (`mise tasks` shows deployed tasks)
- Documentation of task organisation patterns

**Addresses:**
- File-based tasks in `.mise/tasks/` (table stakes feature)
- Task discovery via `mise tasks` (table stakes feature)
- Colon-based namespacing (table stakes feature)

**Avoids:**
- Storing tasks outside chezmoi source (pitfall #4)

**Research needs:** Standard patterns well-documented, no additional research required.

### Phase 2: Dotfiles Operations Tasks

**Rationale:** Wrap existing dotfiles workflows (verify, smoke-test, apply) as tasks to provide user-friendly commands. These tasks orchestrate existing scripts without duplicating logic, validating the run-script-calls-task pattern.

**Delivers:**
- `mise run dotfiles:verify` — Runs existing `scripts/verify-configs.sh`
- `mise run dotfiles:smoke-test` — Runs existing `scripts/zsh-smoke-test.sh`
- `mise run dotfiles:apply` — Runs `chezmoi apply` with verification
- `mise run dotfiles:sync` — Composite task (verify → apply → smoke-test)

**Uses:**
- Task composition with `depends` (STACK.md)
- Environment variable injection for script paths (STACK.md)
- Task aliases for common operations (FEATURES.md)

**Implements:**
- Task wrapper pattern from ARCHITECTURE.md (tasks orchestrate, don't replace)

**Avoids:**
- Duplicating chezmoi run scripts (pitfall #1)

**Research needs:** Standard patterns, no additional research required.

### Phase 3: Git Workflow Tasks

**Rationale:** Provide developer-friendly git helpers that enforce conventional commit format and branch naming conventions from CLAUDE.md. These tasks add new capabilities not present in run scripts.

**Delivers:**
- `mise run git:commit` — Conventional commit helper with Jira ticket prefix
- `mise run git:branch` — Create feature branch with naming convention
- `mise run git:cleanup` — Prune merged branches
- `mise run git:pr` — Create pull request with template

**Uses:**
- Task arguments via `usage` field (STACK.md)
- gh CLI integration for PR creation
- Conventional commit enforcement

**Addresses:**
- Task arguments via usage field (should-have feature for v1.x)

**Avoids:**
- Complex task interdependencies (anti-feature from FEATURES.md)

**Research needs:** May need phase-specific research for gh CLI integration patterns and conventional commit tooling options.

### Phase 4: Performance Optimisation

**Rationale:** After basic tasks working, optimise for performance to prevent shell startup regression. Implements caching and lazy loading patterns to maintain < 300ms startup time.

**Delivers:**
- Shell startup time profiling and benchmarking
- Conditional mise activation (interactive shells only)
- Cached activation output (evalcache or similar)
- PATH precedence documentation and cleanup

**Addresses:**
- File-based rebuild detection with sources/outputs (should-have feature)
- Performance targets from research (< 300ms startup)

**Avoids:**
- Shell startup performance regression (pitfall #2)
- PATH pollution and wrong precedence (pitfall #3)

**Research needs:** May need phase-specific research for ZSH evalcache implementation patterns and profiling tool selection (zprof vs zsh-bench).

### Phase Ordering Rationale

- **Foundation first** because it establishes the deployment pipeline and validates chezmoi → mise integration works before adding complexity
- **Dotfiles operations before git workflows** because they wrap existing scripts (lower risk) and validate the orchestration pattern before building new capabilities
- **Git workflows after dotfiles** because they require arguments and more complex logic, building on foundation and orchestration patterns
- **Performance optimisation last** because it requires baseline functionality to benchmark against and real usage patterns to identify bottlenecks

This ordering follows dependency chain: infrastructure → simple orchestration → complex new capabilities → optimisation. Each phase builds on previous phases whilst delivering standalone value.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 3 (Git Workflows):** gh CLI integration patterns, conventional commit tooling options (commitizen vs custom scripts), PR template strategies. Research needed because git workflow automation has many tooling choices with trade-offs.

- **Phase 4 (Performance):** ZSH evalcache implementation, profiling tool comparison (zprof vs zsh-bench), optimal caching strategies. Research needed because performance optimisation requires specific ZSH plugin knowledge and measurement methodology.

Phases with standard patterns (skip research-phase):

- **Phase 1 (Foundation):** File-based task creation, chezmoi deployment, mise discovery all well-documented in official docs with clear examples.

- **Phase 2 (Dotfiles Operations):** Task composition with depends, wrapper scripts, environment variables all standard mise patterns covered thoroughly in research.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official mise documentation comprehensive; mise already installed and working; chezmoi integration patterns proven in community repos |
| Features | HIGH | Clear distinction between table stakes and differentiators based on mise official docs and community patterns; anti-features identified from GitHub discussions |
| Architecture | HIGH | Integration points validated against official chezmoi/mise architecture docs; deployment flow matches proven patterns from example repos |
| Pitfalls | HIGH | Pitfalls sourced from real migration experiences, official migration guides, and common mistakes documented in GitHub issues/discussions |

**Overall confidence:** HIGH

Research is based primarily on official documentation (mise.jdx.dev, chezmoi.io) with validation from community resources and real-world migration experiences. mise 2026.2.11 is a recent stable release with mature task runner feature set. chezmoi 2.69.4 is well-established with proven deployment mechanisms.

### Gaps to Address

**ZSH-specific performance optimisation:**
- Research identified general strategies (evalcache, lazy loading, zprof) but didn't validate specific plugin implementations
- **Handle during Phase 4:** Research and benchmark specific evalcache plugins during performance optimisation phase
- **Risk:** LOW — multiple proven approaches exist; benchmarking will identify best fit

**gh CLI integration patterns:**
- Research identified gh CLI as recommended tool but didn't explore detailed PR creation workflows or template strategies
- **Handle during Phase 3:** Research gh CLI PR creation patterns and template options when implementing git workflow tasks
- **Risk:** LOW — gh CLI has comprehensive documentation and standard usage patterns

**Cross-platform testing:**
- Research documented macOS/Linux differences but didn't validate actual deployment on both platforms
- **Handle during execution:** Test task deployment and execution on both macOS and Linux during Phase 1 foundation work
- **Risk:** LOW — chezmoi handles cross-platform differences; mise is platform-agnostic

**Task argument patterns:**
- Research identified `usage` field as recommended approach but didn't explore complex argument parsing scenarios
- **Handle during Phase 3:** Evaluate whether simple `usage` field sufficient or if additional argument parsing needed for git workflows
- **Risk:** LOW — usage field covers most common scenarios; can fall back to manual parsing if needed

## Sources

### Primary (HIGH confidence)

**mise official documentation:**
- [Tasks Overview](https://mise.jdx.dev/tasks/) — Task system architecture, discovery, execution model
- [File Tasks](https://mise.jdx.dev/tasks/file-tasks.html) — File-based task format, metadata comments, directory organisation
- [TOML Tasks](https://mise.jdx.dev/tasks/toml-tasks.html) — Inline task configuration (evaluated as inferior for this use case)
- [Task Configuration](https://mise.jdx.dev/tasks/task-configuration.html) — All configuration options (depends, sources, outputs, env)
- [Task Arguments](https://mise.jdx.dev/tasks/task-arguments.html) — usage field documentation, Tera deprecation timeline
- [Running Tasks](https://mise.jdx.dev/tasks/running-tasks.html) — Parallel execution, output modes, error handling

**chezmoi official documentation:**
- [Use scripts to perform actions](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/) — Run script types and execution order
- [Target types](https://www.chezmoi.io/reference/target-types/) — File naming conventions (executable_, private_, etc.)
- [Templating](https://www.chezmoi.io/user-guide/templating/) — Template syntax, whitespace control, error handling

### Secondary (MEDIUM confidence)

**Community integration examples:**
- [mizchi/chezmoi-dotfiles](https://github.com/mizchi/chezmoi-dotfiles) — Real-world mise + chezmoi integration demonstrating deployment patterns
- [Using mise-en-place for dotfiles](https://v5.chriskrycho.com/notes/using-mise-en-place-for-dotfiles/) — Practical mise adoption in dotfiles context
- [Using Mise for All the Things](https://jarv.org/posts/mise/) — Comprehensive mise usage patterns including tasks

**Migration experiences:**
- [Migrating from asdf to mise without the headaches](https://dev.to/0xkoji/migrating-from-asdf-to-mise-without-the-headaches-1jp3) — Real migration pitfalls and solutions
- [Dotfiles Management with Dotbot and Chezmoi](https://myhomelab.gr/automation/2025/06/26/dotfiles-management.html) — Workflow paradigm shift documentation

**Performance considerations:**
- [Is it normal that eval "$(mise activate zsh)" is adding ~100-200ms delay?](https://github.com/jdx/mise/discussions/4821) — Startup performance discussion with mitigation strategies
- [Debugging Shell Startup Performance](https://jannismain.github.io/posts/pyenv-shell-performance-issues/) — Shell profiling methodology

### Tertiary (LOW confidence)

**Feature discussions:**
- [Introducing Monorepo Tasks](https://github.com/jdx/mise/discussions/6564) — Monorepo feature design (not applicable but informative for architecture understanding)
- [Deprecation: Tera Template Functions](https://github.com/jdx/mise/discussions/6766) — Timeline for task argument changes (validates stack recommendations)

---

*Research completed: 2026-02-14*
*Ready for roadmap: yes*
