# Architecture

**Analysis Date:** 2026-01-25

## Pattern Overview

**Overall:** Modular shell configuration with layered initialization and plugin management using Dotbot for symlink installation.

**Key Characteristics:**
- Declarative configuration through Dotbot YAML files specifying symlinks and package installation
- Modular shell initialization with separate responsibility files in `zsh.d/`
- Plugin management via Zgenom (wrapper around Oh My Zsh plugins)
- Homebrew-driven dependency management with machine-specific Brewfiles
- Configuration files symlinked from repository to user home directory

## Layers

**Installation Layer:**
- Purpose: Bootstrap dotfiles and establish symlinks from repository to home directory
- Location: `install` (entry point), `steps/terminal.yml`, `steps/dependencies.yml`
- Contains: Dotbot configuration, machine-specific Brewfile specifications
- Depends on: Dotbot, dotbot-brew, dotbot-asdf submodules
- Used by: Initial setup and updates via `./install` command

**Shell Initialization Layer:**
- Purpose: Initialize ZSH environment with plugins, functions, and configurations
- Location: `.config/zshrc`, `.config/zprofile`
- Contains: Environment variable setup, Zgenom plugin loading, PATH configuration
- Depends on: Zgenom plugin manager, home directory symlinks created by install layer
- Used by: Every ZSH shell session startup

**Configuration Module Layer:**
- Purpose: Organize shell initialization into focused, reloadable modules
- Location: `zsh.d/*.zsh` files (15 files with specific concerns)
- Contains: Aliases, functions, keybinds, completions, environment setup, integrations
- Depends on: Plugin managers (Zgenom), tool-specific configuration files
- Used by: Zgenom loads these files during shell initialization

**Tool Configuration Layer:**
- Purpose: Store actual configuration for external tools and applications
- Location: `.config/` directory (30+ subdirectories for different tools)
- Contains: Tool-specific TOML, YAML, JSON, and Lua configuration files
- Depends on: Respective tools being installed via Brewfile
- Used by: External tools (git, nvim, atuin, lazygit, kitty, etc.) when invoked

**Package Management Layer:**
- Purpose: Declare and install system dependencies and tools
- Location: `Brewfile`, `Brewfile_Client`, `Brewfile_Fanaka`
- Contains: Homebrew package taps and package specifications
- Depends on: Homebrew package manager
- Used by: `brew bundle` or dotbot-brew plugin

## Data Flow

**Initial Installation Flow:**

1. User runs `./install` from repository root
2. Dotbot submodules synced and initialized (dotbot, dotbot-asdf, dotbot-brew)
3. `steps/terminal.yml` processed: creates symlinks from `.config/` to `~/.config/`
4. Symlinks created for shell files: `zsh.d/` → `~/.zsh.d`, `.config/zshrc` → `~/.zshrc`, etc.
5. Tool configuration files (bat, kitty, git, nvim, etc.) symlinked to their expected locations
6. Dotbot-brew plugin processes Brewfile entries to install packages

**Shell Session Initialization Flow:**

1. Shell invoked → ZSH reads `~/.zshrc` (symlinked from `.config/zshrc`)
2. `.config/zshrc` sources Zgenom from `~/.zgenom/zgenom.zsh`
3. Zgenom loads configuration from `.config/zgenom/zgenomrc.zsh`
4. If zgenom save doesn't exist: loads Oh My Zsh base, plugins, and custom scripts
5. Custom modules loaded: `~/.zsh.d/*.zsh` files (sourced by zgenom)
6. Each module (aliases, functions, keybinds, etc.) extends shell capabilities
7. Plugin completions and configurations applied
8. Shell ready for user input

**State Management:**
- Zgenom maintains state in `~/.zgenom/init.zsh` (regenerated on plugin changes)
- Machine state: Brewfile pinned versions determine installed package state
- Configuration state: Repository git history tracks configuration changes
- Per-machine state: `Brewfile_Client` and `Brewfile_Fanaka` allow machine-specific variations

## Key Abstractions

**Plugin System (Zgenom):**
- Purpose: Manage ZSH plugins and automatically source them
- Examples: `~/.zgenom/zgenom.zsh` (plugin manager), `.config/zgenom/zgenomrc.zsh` (plugin specification)
- Pattern: Declarative plugin loading with automatic initialization caching

**Configuration Module:**
- Purpose: Group related shell configurations into focused files
- Examples: `zsh.d/aliases.zsh`, `zsh.d/functions.zsh`, `zsh.d/keybinds.zsh`, `zsh.d/variables.zsh`
- Pattern: Each file has a single semantic concern, sourced together during initialization

**Tool Configuration:**
- Purpose: Store configuration for external CLI tools in their expected locations
- Examples: `.config/git/gitconfig`, `.config/nvim`, `.config/atuin/config.toml`
- Pattern: Repository holds canonical config, symlinks ensure tools find them in home directory

**PATH Management:**
- Purpose: Establish proper command resolution order with tool binaries
- Examples: `zsh.d/path.zsh` with `add_to_path` helper function
- Pattern: Centralized PATH setup prevents duplicate entries on shell reload

## Entry Points

**Installation Entry Point:**
- Location: `install` (bash script)
- Triggers: User runs `./install`, typically after cloning or pulling changes
- Responsibilities: Orchestrate submodule sync, invoke Dotbot with terminal configuration, handle package installation

**Shell Session Entry Point:**
- Location: `~/.zshrc` (symlinked from `.config/zshrc`)
- Triggers: ZSH shell startup (login or interactive)
- Responsibilities: Set up Zgenom environment, load plugin manager configuration, initialize shell modules

**Submodule Entry Points:**
- Dotbot: `dotbot/bin/dotbot` - Symlink and installation orchestration
- Dotbot-brew: Plugin for `dotbot` - Homebrew package installation
- Dotbot-asdf: Plugin for `dotbot` - Language runtime version management

## Error Handling

**Strategy:** Silent failure with optional output; shell continues even if individual components fail

**Patterns:**
- `|| true` in install script allows continued execution if components fail
- Tool-specific sourcing uses `if command -v <tool> > /dev/null` guards before initialization
- Zgenom autoupdate runs silently; failures don't block shell startup
- Missing private zsh files (`~/.zsh.d.private/*.zsh`) don't block initialization (conditional loading)

## Cross-Cutting Concerns

**Logging:**
- Dotbot stdout/stderr optionally captured via `stdout: true`, `stderr: true` in YAML
- Shell module initialization is silent by default
- Tool-specific logging handled by individual tools (atuin, lazygit, etc.)

**Validation:**
- Dotbot validates symlink creation, directory existence
- Zgenom validates plugin sources before loading
- Homebrew validates package availability before installation
- PATH validation via `add_to_path` prevents duplicate entries

**Authentication:**
- SSH configuration via `.config/ssh_config` (currently commented out)
- GPG agent setup via `.config/gpgagent` symlinked to `~/.gnupg/gpg-agent.conf`
- Git credentials handled via git config (`.config/git/gitconfig`)
- Claude tool authentication configured in `.config/claude/settings.json`

---

*Architecture analysis: 2026-01-25*
