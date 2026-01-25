# Codebase Structure

**Analysis Date:** 2026-01-25

## Directory Layout

```
dotfiles-zsh/
├── install                          # Main installation entry point (bash script)
├── steps/                           # Dotbot configuration files
│   ├── terminal.yml                # Symlink configuration for shell/tool files
│   └── dependencies.yml            # Brewfile package specification
├── zsh.d/                          # Shell initialization modules (15 files)
│   ├── aliases.zsh                # Command aliases and shortcuts
│   ├── functions.zsh              # Custom shell functions
│   ├── variables.zsh              # Environment variables and paths
│   ├── keybinds.zsh               # ZSH key bindings
│   ├── completions.zsh            # Shell completion configuration
│   ├── atuin.zsh                  # Atuin (history management) setup
│   ├── carapace.zsh               # Carapace (completion engine) setup
│   ├── hooks.zsh                  # ZSH hooks configuration
│   ├── path.zsh                   # PATH manipulation and setup
│   ├── ssh.zsh                    # SSH configuration
│   ├── external.zsh               # External tool integration
│   ├── intelli-shell.zsh          # Shell intelligence features
│   ├── lens-completion.zsh        # Kubernetes lens completions
│   ├── wt.zsh                     # Welltodo integration
│   └── xlaude.zsh                 # Claude CLI integration
├── .config/                         # Configuration files for tools (30+ subdirs)
│   ├── zshrc                       # Main ZSH configuration file
│   ├── zprofile                    # ZSH profile initialization
│   ├── zgenom/                     # Plugin manager configuration
│   │   └── zgenomrc.zsh           # Plugin specifications and loading
│   ├── atuin/                      # Atuin (history tool) configuration
│   ├── git/                        # Git configuration
│   │   ├── gitconfig              # Git settings
│   │   ├── gitignore              # Global gitignore patterns
│   │   └── gitattributes          # Git attributes
│   ├── nvim/                       # Neovim configuration (external, may be symlink)
│   ├── kitty.conf                 # Kitty terminal configuration
│   ├── wezterm.lua                # WezTerm terminal configuration
│   ├── ghostty/                   # Ghostty terminal configuration
│   ├── aerospace/                 # Aerospace window manager configuration
│   │   └── aerospace.toml         # Window manager settings
│   ├── bat/                        # Bat (cat replacement) configuration
│   ├── lsd/                        # LSD (ls replacement) configuration
│   ├── btop/                       # Btop (system monitor) configuration
│   ├── lazygit.yml                # LazyGit configuration
│   ├── atuin/config.toml          # Atuin history database config
│   ├── claude/                     # Claude tool configuration
│   │   ├── CLAUDE.md              # Claude instructions
│   │   ├── settings.json          # Claude settings
│   │   ├── agents/                # Claude agent definitions
│   │   ├── commands/              # Claude custom commands
│   │   └── skills/                # Claude skill definitions
│   ├── karabiner/                 # Karabiner key remapping
│   ├── nushell/                   # Nushell shell configuration
│   ├── oh-my-posh.omp.json        # Oh My Posh prompt theme
│   ├── aider.conf.yml             # Aider (AI pair programmer) configuration
│   ├── finicky.js                 # Finicky (URL router) configuration
│   └── [other tools]              # psqlrc, sqliterc, inputrc, nanorc, editorconfig
├── Brewfile                         # Main Homebrew package list (95+ packages)
├── Brewfile_Client                # Client machine-specific packages
├── Brewfile_Fanaka                # Fanaka machine-specific packages
├── zgenom/                          # Zgenom plugin manager (git submodule)
│   └── zgenom.zsh                 # Plugin manager executable
├── dotbot/                          # Dotbot installation tool (git submodule)
│   └── bin/dotbot                 # Dotbot executable
├── dotbot-brew/                     # Dotbot Homebrew plugin (git submodule)
├── dotbot-asdf/                     # Dotbot ASDF plugin (git submodule)
├── dotbot-brewfile/                # Dotbot Brewfile plugin (git submodule)
├── .claude/                         # Claude tool state directory
│   ├── CLAUDE.md                  # Project-specific Claude instructions
│   ├── settings.json              # Claude workspace settings
│   ├── agents/                    # Symlink to .config/claude/agents
│   ├── commands/                  # Symlink to .config/claude/commands
│   └── skills/                    # Symlink to .config/claude/skills
├── .config/claude/                 # Claude tool configurations (canonical location)
│   ├── agents/                    # Agent definitions (GSD agents)
│   ├── commands/                  # Custom command implementations
│   └── skills/                    # Skill definitions
├── .planning/                       # GSD planning directory
│   └── codebase/                  # Codebase analysis documents
├── .github/                         # GitHub configuration
├── CLAUDE.md                        # Project instructions for Claude
├── AGENTS.md                        # Documentation about Claude agents
├── AIDER.md                         # Aider tool documentation
├── LICENSE.md                       # Project license
├── README.md                        # Project documentation (if exists)
├── .gitignore                       # Git ignore patterns
├── .gitmodules                      # Git submodule specifications
├── .editorconfig                    # Editor configuration
└── art/                             # Art/graphics directory

```

## Directory Purposes

**install:**
- Purpose: Main entry point for setting up dotfiles on a new system
- Contains: Bash script that orchestrates Dotbot and submodule setup
- Key files: None (single file)

**steps/:**
- Purpose: Dotbot configuration specifications
- Contains: YAML files defining symlinks and package installations
- Key files: `terminal.yml` (main symlink config), `dependencies.yml` (package specs)

**zsh.d/:**
- Purpose: Modular ZSH shell initialization organized by concern
- Contains: 15 shell scripts that extend ZSH functionality
- Key files: `aliases.zsh`, `functions.zsh`, `variables.zsh` (core modules)

**.config/:**
- Purpose: Canonical location for all tool and shell configurations
- Contains: 30+ subdirectories for different tools and their settings
- Key files: `zshrc`, `zprofile`, `zgenom/zgenomrc.zsh` (shell initialization)

**.config/claude/:**
- Purpose: Store Claude IDE tool configurations for this project
- Contains: Agent definitions, command implementations, skill definitions
- Key files: `CLAUDE.md`, `settings.json` (core config)

**zgenom/:**
- Purpose: ZSH plugin manager (manages plugins and completion)
- Contains: Plugin manager source code
- Key files: `zgenom.zsh` (main executable)

**dotbot/:**
- Purpose: Symlink and configuration installation tool
- Contains: Dotbot framework source code
- Key files: `bin/dotbot` (main executable)

**dotbot-*/ (brew, asdf, brewfile):**
- Purpose: Dotbot plugins extending functionality
- Contains: Plugin implementations for Homebrew and ASDF support
- Key files: Plugin entry points (varies by plugin)

**.planning/codebase/:**
- Purpose: Store GSD (Golden Signal Data) codebase analysis documents
- Contains: Architecture and structure analysis markdown files
- Key files: `ARCHITECTURE.md`, `STRUCTURE.md` (codebase documentation)

## Key File Locations

**Entry Points:**
- `install`: Installation orchestration script
- `.config/zshrc`: Shell initialization (symlinked to `~/.zshrc` during install)
- `.config/zprofile`: Shell profile setup (symlinked to `~/.zprofile`)

**Configuration:**
- `steps/terminal.yml`: Dotbot symlink mappings and installation directives
- `steps/dependencies.yml`: Brewfile specifications
- `.config/zgenom/zgenomrc.zsh`: Plugin and completion definitions
- `Brewfile`: Master package specification

**Core Logic:**
- `zsh.d/aliases.zsh`: Command aliases and navigation shortcuts
- `zsh.d/functions.zsh`: Custom utility functions
- `zsh.d/variables.zsh`: Environment variable initialization
- `zsh.d/path.zsh`: PATH assembly and binary resolution

**Tool Integration:**
- `.config/git/`: Git configuration
- `.config/nvim/`: Neovim editor configuration
- `.config/atuin/`: History database and keybindings
- `.config/claude/`: Claude IDE tool configuration and agents

**Testing:**
- Not applicable - shell configuration project without tests

## Naming Conventions

**Files:**
- Shell modules: lowercase with `.zsh` extension (e.g., `aliases.zsh`)
- Configuration files: tool-specific names matching tool expectations (e.g., `gitconfig`, `kitty.conf`)
- Brewfiles: `Brewfile` (main), `Brewfile_<MachineName>` for machine-specific variants
- Dotbot configs: YAML files in `steps/` directory

**Directories:**
- Shell modules: `zsh.d/` (contains shell configuration modules)
- Tool configs: `.config/<tool-name>/` (matches XDG Base Directory specification)
- Symlink targets: `.config/` or repository root (files symlinked to home during install)
- Machine variants: `Brewfile_<MachineName>` (not directories, but naming pattern)

## Where to Add New Code

**New Shell Alias or Function:**
- Primary code: `zsh.d/aliases.zsh` (aliases) or `zsh.d/functions.zsh` (functions)
- Related files: Update `.config/zsh-abbr/user-abbreviations` if abbreviation-based variant needed

**New Shell Configuration Module:**
- Implementation: Create `zsh.d/<module-name>.zsh` with clear semantic purpose
- Integration: Zgenom automatically sources all `~/.zsh.d/*.zsh` files during initialization
- File pattern: Keep file under 100 lines; separate concerns into different files

**New Tool Configuration:**
- Implementation: Add configuration in `.config/<tool-name>/` directory
- Symlink: Add link entry to `steps/terminal.yml` mapping tool config to home directory
- Pattern: Follow XDG Base Directory specification where applicable

**New System Package:**
- Primary: Add to appropriate Brewfile (`Brewfile` for universal, `Brewfile_<Machine>` for machine-specific)
- Package type: Use `brew` for packages, `cask` for applications, `tap` for custom repositories
- Integration: Re-run `./install` or `brew bundle` to apply

**Machine-Specific Configuration:**
- Implementation: Create `Brewfile_<MachineName>` for machine-specific packages
- Machine names: Use actual machine names (e.g., `Brewfile_Client`, `Brewfile_Fanaka`)
- Integration: Uncomment relevant Brewfile in `steps/dependencies.yml` to enable

**New Integration/Extension:**
- Primary: Create new file in `.config/` if tool-specific, or `zsh.d/` if shell-related
- Entry point: If tool needs initialization, add to `.config/zshrc` or appropriate `zsh.d/` module
- Testing: Source the file in current shell and verify functionality

## Special Directories

**.config:**
- Purpose: Tool and shell configuration repository
- Generated: No (all manually maintained)
- Committed: Yes (primary canonical location for configurations)

**zgenom/ (and dotbot/, dotbot-*/):**
- Purpose: Git submodules for package manager and installation tools
- Generated: No (external repositories)
- Committed: Yes (as submodule references)

**.planning/codebase/:**
- Purpose: GSD (Golden Signal Data) codebase analysis documents
- Generated: Yes (created by Claude codebase mapper agent)
- Committed: Yes (documentation for future reference)

**.claude/ (symlink to .config/claude/):**
- Purpose: Claude IDE tool state and configuration
- Generated: Partially (settings may be auto-generated by Claude IDE)
- Committed: Yes (for reproducible Claude tool configuration)

---

*Structure analysis: 2026-01-25*
