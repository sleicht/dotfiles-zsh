# Phase 5: Tool Version Migration (mise) - Research

**Researched:** 2026-01-28
**Domain:** Runtime version management (Node, Python, Go, Rust, Java, Ruby, Terraform)
**Confidence:** HIGH

## Summary

mise is a modern runtime version manager written in Rust that replaces asdf with significantly better performance and enhanced security. It provides drop-in compatibility with `.tool-versions` files while offering additional capabilities like environment variable management and task running. The migration from asdf to mise is straightforward due to native `.tool-versions` support, though asdf directories are not reused and tools must be reinstalled.

**Key findings:**
- mise is 10-50x faster than asdf for common operations (7x faster installs, zero runtime overhead vs 120ms per call)
- Built-in support for node, python, go, rust, java, ruby, terraform (no plugins needed)
- Native `.tool-versions` compatibility allows gradual migration
- mise already installed via Homebrew in Phase 4, basic config exists at `~/.config/mise/config.toml`
- Shell activation currently commented out in `hooks.zsh` (line 12)
- Current system has `~/.tool-versions` with java and nodejs definitions

**Primary recommendation:** Use `mise activate zsh` for interactive shell integration, migrate global config from `~/.tool-versions` to chezmoi-managed `~/.config/mise/config.toml`, remove asdf plugin/directory infrastructure cleanly, and establish global defaults for all managed runtimes.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| mise | 2026.1.9+ | Runtime version manager | Written in Rust, 10-50x faster than asdf, built-in support for major languages, active development |
| mise (core backends) | Built-in | node, python, go, rust, java, ruby, terraform | No plugins required, cryptographically verified downloads, maintained by mise team |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Aqua backend | Via mise | Additional tools via Aqua registry | For tools not in core mise (kubectl, terraform variants, etc.) |
| npm backend | Via mise | Node.js CLI tools globally | Tools like prettier, eslint, typescript |
| pipx backend | Via mise | Python CLI tools isolated | Tools like black, poetry, ruff, httpie |
| cargo backend | Via mise | Rust CLI tools | Tools like ripgrep, fd, bat (if not via Homebrew) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mise | asdf | asdf has 120ms overhead per runtime call, shell-based (slower), security concerns with plugins |
| mise | nvm/pyenv/rbenv | Single-language managers require separate tools per runtime, no unified config |
| mise | volta | Volta is node-specific only, mise handles 7+ languages |
| mise activate | mise shims | Shims add ~1ms overhead, don't support env vars or hooks, better for CI/CD than interactive shells |

**Installation:**
```bash
# Already installed via Homebrew in Phase 4
brew install mise

# Or via official installer
curl https://mise.run | sh
```

## Architecture Patterns

### Recommended Configuration Structure

```
~/.config/mise/
├── config.toml              # Global defaults (chezmoi-managed)
└── (completions managed via shell)

Project directories:
├── .tool-versions           # Project-specific versions (mise reads natively)
└── mise.toml               # Optional, more features than .tool-versions
```

### Pattern 1: Global Configuration via chezmoi

**What:** Manage `~/.config/mise/config.toml` as a chezmoi template
**When to use:** Always - ensures consistent global defaults across all machines
**Example:**
```toml
# Source: https://mise.jdx.dev/configuration.html
[tools]
# Global tool versions (LTS/stable defaults)
node = 'lts'              # Latest LTS version
python = ['3.11', '3.12'] # Multiple versions available
go = '1.22'
rust = 'stable'
java = '25'               # LTS version
ruby = '3'
terraform = '1.9'

[settings]
# Enable reading .nvmrc, .python-version, etc.
idiomatic_version_file_enable_tools = ['node', 'python']

# Auto-install missing tools when entering directories
not_found_auto_install = true
exec_auto_install = true
task_auto_install = true

# Performance/behavior
jobs = 4                  # Parallel installs
verbose = false
yes = false               # Prompt for confirmations

[env]
# Optional: Global environment variables
NODE_ENV = 'development'
```

### Pattern 2: Shell Activation (Interactive)

**What:** Use `mise activate` for interactive shells to get zero-overhead PATH updates
**When to use:** Always for `.zshrc` (interactive sessions)
**Example:**
```zsh
# Source: https://mise.jdx.dev/getting-started.html
# In .zshrc or hooks.zsh
if command -v mise > /dev/null; then
  eval "$(mise activate zsh)"
fi
```

**Performance characteristics:**
- Adds ~10ms when prompt loads (4ms if no changes)
- Adds 0ms when calling binaries (vs asdf's 120ms overhead)
- Updates environment on directory change via `mise hook-env`

### Pattern 3: Project Version Files

**What:** Use `.tool-versions` for cross-tool compatibility
**When to use:** In projects that might use asdf or mise
**Example:**
```text
# Source: https://mise.jdx.dev/dev-tools/comparison-to-asdf.html
node 22.12.0
python 3.11.5
terraform 1.9.0
```

**Alternative (mise.toml for more features):**
```toml
[tools]
node = "22.12.0"
python = "3.11.5"
terraform = "1.9.0"

[env]
NODE_ENV = "production"
AWS_REGION = "us-east-1"
```

### Pattern 4: Completions Management

**What:** Generate mise completions via chezmoi run script
**When to use:** Once during initial setup, regenerate when mise updates
**Example:**
```zsh
# Source: https://mise.jdx.dev/cli/completion.html
# Via run_once script or manual
mise completion zsh > ~/.local/share/zsh/site-functions/_mise
```

### Anti-Patterns to Avoid

- **Using shims for interactive shells:** Shims don't support environment variables or hooks. Use `mise activate` instead.
- **Keeping `~/.tool-versions` as global config:** mise doesn't use this location. Global config lives in `~/.config/mise/config.toml`.
- **Installing runtimes via both Homebrew and mise:** Creates conflicts. Remove Homebrew-installed node, python, go, etc. Let mise manage them exclusively.
- **Mixing asdf and mise:** asdf directories (`~/.asdf`) are not reused by mise. Clean removal required.
- **Not enabling `not_found_auto_install`:** Without it, missing tools cause command failures instead of auto-installing.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version switching logic | Custom shell scripts checking `.tool-versions` | `mise activate` | Handles all edge cases: directory changes, file watches, nested configs, precedence rules |
| Download verification | `curl \| tar` scripts | mise core backends | Cryptographic verification (Cosign/SLSA), retry logic, checksum validation |
| Environment variable management | direnv + custom scripts | mise `[env]` sections | Integrated with version switching, supports .env files, template support |
| Global version defaults | Manually symlinking binaries | mise global config | Cross-machine sync via chezmoi, precedence over project configs works correctly |
| Shell completion generation | Writing completion scripts | `mise completion zsh` | Auto-generated, complete coverage, updated with mise releases |
| Parallel tool installation | Sequential install loops | mise `jobs` setting | Parallel downloads/installs, proper error handling, atomic operations |

**Key insight:** Runtime version management has complex edge cases (nested configs, shell hooks, PATH precedence, download failures, version resolution). mise solves these comprehensively; custom solutions inevitably miss cases.

## Common Pitfalls

### Pitfall 1: asdf Compatibility Assumptions

**What goes wrong:** Assuming mise is 100% compatible with asdf workflows
**Why it happens:** mise reads `.tool-versions` but uses different internal structure
**How to avoid:**
- Don't expect `~/.tool-versions` to work as global config (use `~/.config/mise/config.toml` instead)
- Don't reuse `~/.asdf` directory (mise uses `~/.local/share/mise` and `~/.config/mise`)
- Don't assume asdf plugins work (mise has built-in core backends, only 25% of registry uses asdf backend)
- New asdf-go (0.16+) has commands mise doesn't support (`asdf set`)

**Warning signs:**
- Global tools not available after setting `~/.tool-versions`
- Commands like `mise set` failing (asdf-go only)
- Attempting to run `asdf plugin add` commands

**Prevention:** Migrate `~/.tool-versions` content to `~/.config/mise/config.toml`, delete `~/.asdf` completely.

### Pitfall 2: Shell Activation Timing

**What goes wrong:** mise activation happens too late or in wrong shell config file
**Why it happens:** Confusion between interactive vs non-interactive, login vs non-login shells
**How to avoid:**
- Put `mise activate zsh` in `.zshrc` (interactive sessions)
- Put `mise activate zsh --shims` in `.zprofile` (non-interactive/login if needed)
- Don't put activation in `.zshenv` (runs for all shells, including subprocesses)
- Use shims for CI/CD and scripts, not `mise activate`

**Warning signs:**
- Tools available in some terminals but not others
- Environment variables not loading
- Slow shell startup (100-200ms+) due to duplicate activations
- Commands failing in scripts but working interactively

**Prevention:** Follow official shell integration pattern, test in new shell sessions.

### Pitfall 3: Homebrew Runtime Conflicts

**What goes wrong:** Runtime installed via both Homebrew and mise causes version confusion
**Why it happens:** Homebrew formulae for node, python, go appear in PATH before mise versions
**How to avoid:**
- Remove Homebrew-installed runtimes: `brew uninstall node python go rust`
- Keep Homebrew for build tools (python@3.11 as dependency is OK)
- Let mise exclusively manage runtime versions
- Verify with `which node` after mise activation (should show mise path)

**Warning signs:**
- `which node` shows `/opt/homebrew/bin/node` instead of `~/.local/share/mise/installs/node/...`
- Version mismatch between `node --version` and `.tool-versions`
- Tools installed via npm not found (wrong node version active)

**Prevention:** Audit Homebrew packages, remove runtime conflicts before activating mise.

### Pitfall 4: Not Understanding Version Resolution

**What goes wrong:** Unexpected version used when multiple configs exist
**Why it happens:** mise config precedence not understood
**How to avoid:**
- Precedence (highest to lowest):
  1. Local directory `mise.toml` / `.tool-versions`
  2. Parent directory configs (searches up tree)
  3. Global `~/.config/mise/config.toml`
- Use `mise current` to see active versions and source
- Use `mise where node` to see installation directory
- Project `.tool-versions` always wins over global config

**Warning signs:**
- Tool version doesn't match `.tool-versions` file
- Different versions in subdirectories vs root
- Global config changes not taking effect

**Prevention:** Use `mise current` and `mise ls` to debug version resolution.

### Pitfall 5: Auto-Install Disabled

**What goes wrong:** Commands fail with "command not found" instead of installing tool
**Why it happens:** `not_found_auto_install` and related settings default to true but may be disabled
**How to avoid:**
- Ensure `not_found_auto_install = true` in config.toml
- Ensure `exec_auto_install = true` for `mise x` commands
- Ensure `task_auto_install = true` for `mise run` tasks
- Understand auto-install only works when `mise activate` is running (not in CI)

**Warning signs:**
- `node: command not found` when `.tool-versions` exists
- Tools not installing when entering project directory
- Need to manually run `mise install` constantly

**Prevention:** Enable auto-install settings in global config, verify with `mise settings`.

### Pitfall 6: Completions Not Working

**What goes wrong:** Tab completion for mise commands doesn't work
**Why it happens:** Completions not generated or in wrong location
**How to avoid:**
- Generate completions: `mise completion zsh > ~/.local/share/zsh/site-functions/_mise`
- Ensure completion path in `fpath` before `compinit`
- Regenerate after mise updates
- Don't rely on Homebrew completions (manage via chezmoi)

**Warning signs:**
- Tab completion shows "no matches found"
- Only basic file completion works
- Completions work for other tools but not mise

**Prevention:** Generate completions in chezmoi run script, verify with `mise <TAB>`.

## Code Examples

Verified patterns from official sources:

### Global Config Setup
```toml
# Source: https://mise.jdx.dev/configuration.html
# Location: ~/.config/mise/config.toml (chezmoi-managed)

[tools]
# Use semantic versioning or special keywords
node = 'lts'              # Latest LTS
python = ['3.11', '3.12'] # Multiple versions
go = '1.22'               # Specific minor
rust = 'stable'           # Keyword
java = '25'               # LTS major
ruby = '3'                # Prefix match (latest 3.x)

[settings]
# Compatibility with other version files
idiomatic_version_file_enable_tools = ['node', 'python']

# Auto-installation behavior
not_found_auto_install = true
exec_auto_install = true
task_auto_install = true

# Performance
jobs = 4
verbose = false

[env]
# Optional global environment variables
NODE_ENV = 'development'
```

### Shell Integration (ZSH)
```zsh
# Source: https://mise.jdx.dev/getting-started.html
# Location: ~/.zshrc or ~/.zsh.d/hooks.zsh

# Activate mise for interactive shells
if command -v mise > /dev/null; then
  eval "$(mise activate zsh)"
fi

# Optional: Load completions (if not managed via chezmoi)
# if command -v mise > /dev/null; then
#   eval "$(mise completion zsh)"
# fi
```

### Installing and Using Tools
```bash
# Source: https://mise.jdx.dev/dev-tools/
# Install specific version globally
mise use --global node@22
mise use --global python@3.12

# Install version for current directory (creates .tool-versions)
mise use node@20.12.0

# Install all tools defined in .tool-versions
mise install

# List installed versions
mise ls

# Show current active versions
mise current

# Show where a tool is installed
mise where node
```

### Migration from asdf
```bash
# Source: https://mise.jdx.dev/dev-tools/comparison-to-asdf.html
# 1. Generate mise.toml from .tool-versions (optional)
mise config generate

# 2. Convert global ~/.tool-versions to mise config (if exists)
cat ~/.tool-versions | tr -s ' ' | tr ' ' '@' | xargs -n2 mise use -g

# 3. Install all tools
mise install

# 4. Remove asdf (after verification)
rm -rf ~/.asdf
```

### Completion Generation
```bash
# Source: https://mise.jdx.dev/cli/completion.html
# Generate zsh completions
mise completion zsh > ~/.local/share/zsh/site-functions/_mise

# Ensure fpath includes completion directory (before compinit)
# In .zshrc:
# fpath=(~/.local/share/zsh/site-functions $fpath)
# autoload -Uz compinit && compinit
```

### Verification Commands
```bash
# Check mise is working
mise doctor

# Show current configuration
mise config ls

# Show all settings
mise settings

# Show environment variables
mise env

# Run command with mise environment
mise exec -- node --version
mise x -- python --version
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| asdf (bash) | mise (rust) | 2023 | 10-50x faster operations, zero runtime overhead |
| asdf plugins | mise core backends | 2024 | Built-in support for major languages, cryptographic verification |
| Shims only | PATH activation | 2023 | Dynamic environment updates, hook support, env var management |
| .tool-versions only | mise.toml + .tool-versions | 2024 | Enhanced features (env vars, tasks) while maintaining compatibility |
| Manual plugin security | Aqua/UBI backends | 2024-2025 | Cosign/SLSA verification, reduced supply chain risk |
| direnv separate | mise env management | 2024 | Unified tool, env var switching integrated with version switching |

**Deprecated/outdated:**
- **asdf plugins:** mise has 210/846 tools still using asdf backend, but core languages use built-in backends
- **Global ~/.tool-versions:** Not supported by mise (use `~/.config/mise/config.toml` instead)
- **asdf 0.16+ (Go version) commands:** `asdf set` and other new commands not compatible with mise
- **mise shims for interactive shells:** Use `mise activate` instead; shims are for CI/CD
- **Installing runtimes via Homebrew:** Conflicts with mise; use mise exclusively

## Open Questions

### 1. Shell startup performance with mise activate

**What we know:**
- mise activate adds ~10ms per prompt (4ms if no changes)
- Some users report 100-200ms delays (GitHub discussions #4821, #6279)
- Performance depends on number of tools, config complexity, filesystem speed

**What's unclear:**
- Exact impact on this specific dotfiles setup
- Whether caching can reduce overhead further
- If Sheldon + mise + other hooks exceed acceptable threshold

**Recommendation:**
- Implement mise activate as planned
- Benchmark shell startup before/after (use `time zsh -i -c exit`)
- If >100ms total, consider shims as fallback or optimize other hooks first
- Target: <50ms total shell startup time

### 2. Interaction with Homebrew-installed build dependencies

**What we know:**
- Homebrew Python 3.11 may exist as dependency for other formulae
- mise should manage user-facing runtimes
- System build tools can coexist

**What's unclear:**
- Should Homebrew python@3.11 formula be explicitly allowed if needed by dependencies?
- How to handle formulae that depend on specific node/python versions?

**Recommendation:**
- Remove user-installed `node`, `python`, `go`, `rust` via Homebrew
- Allow Homebrew-installed build dependencies (they use versioned paths like `python@3.11`)
- mise PATH entries should come before Homebrew in PATH precedence
- Document this in verification steps

### 3. Machine-specific mise settings

**What we know:**
- Global config at `~/.config/mise/config.toml` managed by chezmoi
- `mise.local.toml` can override for local settings
- `.chezmoidata.yaml` has `mise:` section ready for machine-specific config

**What's unclear:**
- Do we need machine-specific mise tool versions (client vs fanaka)?
- Should global defaults be templated based on machine_type?

**Recommendation:**
- Start with same global defaults for all machines (LTS/stable versions)
- Projects use `.tool-versions` for specific needs
- If machine-specific needed later, template config.toml with `{{- if eq .machine_type "client" }}`
- Keep it simple initially

## Sources

### Primary (HIGH confidence)

- Context7 `/jdx/mise` - Core mise documentation, configuration patterns, shell integration, migration guides
- [mise Official Documentation - Configuration](https://mise.jdx.dev/configuration.html) - Global settings, tool versions, config.toml structure
- [mise Official Documentation - Getting Started](https://mise.jdx.dev/getting-started.html) - Installation, shell activation, initial setup
- [mise Official Documentation - Shims](https://mise.jdx.dev/dev-tools/shims.html) - Shims vs activate comparison
- [mise Official Documentation - Comparison to asdf](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html) - Performance benchmarks, migration guide
- [mise Official Documentation - FAQ](https://mise.jdx.dev/faq.html) - Common issues, troubleshooting

### Secondary (MEDIUM confidence)

- [Better Stack - Mise vs asdf](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/) - Performance comparisons, practical migration guide
- [Oreate AI - Mise vs. Asdf](https://www.oreateai.com/blog/mise-vs-asdf-the-new-era-of-development-environment-management/c0fac9cc7f8b0d414d4f492cd38e54c7) - Architecture differences
- [Medium - Why I Switched from asdf to mise](https://medium.com/@nidhivya18_77320/why-i-switched-from-asdf-to-mise-and-you-should-too-8962bf6a6308) - Real-world migration experience
- [Medium - Migrating from asdf to mise without the headaches (Jan 2026)](https://koji-kanao.medium.com/migrating-from-asdf-to-mise-without-the-headaches-fad759f33dce) - Recent migration guide
- [Christian Tietze - Migrating from asdf to mise](https://christiantietze.de/posts/2025/07/migrating-asdf-to-mise-en-place/) - Detailed migration walkthrough

### Tertiary (LOW confidence)

- GitHub Discussions:
  - [#4821 - Shell startup delay with mise activate](https://github.com/jdx/mise/discussions/4821) - User-reported performance issues
  - [#6279 - Shell startup overhead](https://github.com/jdx/mise/discussions/6279) - More performance discussion
  - [#4054 - Supply chain security](https://github.com/jdx/mise/discussions/4054) - Security considerations

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official mise documentation and Context7 provide complete coverage of installation, configuration, and core backends
- Architecture: HIGH - Clear patterns from official docs, verified with Context7 code examples and multiple migration guides
- Pitfalls: MEDIUM - Combination of official FAQ, GitHub discussions, and migration blog posts; some issues are user-reported

**Research date:** 2026-01-28
**Valid until:** 2026-03-28 (60 days - mise is stable, Rust-based, mature project with consistent patterns)

**Current system state:**
- mise 2026.1.9 already installed via Homebrew
- Basic config exists at `~/.config/mise/config.toml` with node and ruby
- Shell activation commented out in `hooks.zsh` (line 12)
- Global `~/.tool-versions` exists with java and nodejs
- No `~/.asdf` directory found (asdf not installed)
- Node 22.21.1 installed via mise
