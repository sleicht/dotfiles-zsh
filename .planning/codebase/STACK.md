# Technology Stack

**Analysis Date:** 2026-01-25

## Languages

**Primary:**
- Zsh - Shell scripting language for configuration and automation
- Bash - Used in install script and setup utilities
- TOML - Configuration format for Nix and tool configs
- YAML - Configuration format for Dotbot, installation steps
- JSON - Configuration format for tools (Claude, Karabiner, Oh My Posh)
- Lua - Configuration for WezTerm terminal
- Nix - Declarative package management and system configuration

**Secondary:**
- AppleScript - Invoked via AeroSpace for macOS window management

## Runtime

**Environment:**
- macOS (Darwin) - aarch64-darwin (Apple Silicon)
- Zsh shell - Primary shell interpreter
- Bash shell - For POSIX compatibility

**Package Manager:**
- Homebrew - Primary macOS package manager
- Nix/Nix Flakes - Declarative system configuration (feature/nix branch)
- Home Manager - Nix-based dotfiles management
- Sheldon - Zsh plugin manager
- asdf - Version manager (dotbot-asdf plugin)

## Frameworks

**Core:**
- Nix Darwin 0.5+ - macOS system configuration framework
- Home Manager - User dotfiles and configuration management
- Dotbot - Configuration symlink framework
  - `dotbot` submodule - Core linking functionality
  - `dotbot-asdf` submodule - Version manager plugin
  - `dotbot-brew` submodule - Homebrew integration plugin

**Shell Management:**
- Sheldon - Fast, lightweight Zsh plugin manager (replaces Oh My Zsh)
- Zoxide - Smart directory navigation (cd replacement)
- Atuin - Encrypted, synced shell history with TUI

**Development:**
- Mise - Multi-language runtime manager (activated in zsh)
- Aider - AI-powered code editor (Claude models)
- Claude Code - IDE integration with Anthropic models

## Key Dependencies

**Critical:**
- `zsh` - Shell interpreter and configuration shell
- `git` - Version control system
- `homebrew` - Package installation and management

**CLI Tool Replacements:**
- `bat` - Syntax-highlighted cat replacement
- `lsd` - Colorful ls replacement with icons
- `duf` - Disk usage frontend (df replacement)
- `dust` - Directory size summary (du replacement)
- `bottom` - System monitor (top/htop replacement)
- `ripgrep` - Fast grep-like search tool
- `fd` - Fast find alternative
- `fzf` - Fuzzy finder for interactive filtering
- `zoxide` - Smart directory jumper

**Shell Enhancements:**
- `carapace` - Multi-shell completions framework
- `zsh-abbr` - Automatic abbreviation expansion
- `sheldon` - Plugin manager
- `atuin` - Enhanced command history
- `oh-my-posh` - Prompt engine

**Development Tools:**
- `neovim` - Modern vim-based text editor
- `lazygit` - Git client with TUI
- `lazydocker` - Docker client with TUI
- `docker` - Container platform
- `docker-compose` - Multi-container orchestration
- `kubectl` - (via kns plugin) Kubernetes CLI
- `helm` - Kubernetes package manager
- `argocd` - GitOps continuous delivery
- `opentofu` - Infrastructure as code (Terraform fork)
- `trivy` - Vulnerability scanner

**Terminal Emulators:**
- `ghostty` - Fast GPU-accelerated terminal
- `wezterm` - Cross-platform terminal emulator
- `kitty` - GPU-based terminal emulator

**Window Management:**
- `aerospace` - i3-like window manager for macOS

**Cloud & Infrastructure:**
- `gcloud-cli` - Google Cloud Platform CLI
- `aws-vault` - AWS credential management (via Homebrew)
- `jfrog-cli` - Artifactory/JFrog CLI

**Version Managers:**
- `asdf` - Multi-language runtime manager
- `mise` - Alternative to asdf

**Build & Package:**
- `just` - Task runner
- `cargo` - Rust package manager
- `golang` - Go language runtime
- `python` - Python runtime
- `uv` - Python package manager/installer
- `nushell` - Modern shell language

**Data Processing:**
- `jq` - JSON processor
- `yq` - YAML processor

**System Utilities:**
- `coreutils` - GNU core utilities
- `gnu-sed` - GNU sed
- `grep` - GNU grep
- `findutils` - GNU find utilities
- `openssh` - Secure shell
- `gnupg` - GPG encryption

## Configuration

**Environment:**
- Configured via environment variables in `zsh.d/variables.zsh`
- Credential management via 1Password SSH agent or git-credential-manager
- Mise runtime version management (`.mise.toml` pattern)

**Build:**
- Nix Flakes configuration: `nix-config/flake.nix`
- Nix modules:
  - `modules/nix-core.nix` - Core Nix configuration
  - `modules/system.nix` - macOS system settings
  - `modules/apps.nix` - Common applications
  - `modules/apps-fanaka.nix` - User-specific applications
  - `modules/home.nix` - Home Manager configuration
  - `modules/host-users.nix` - User definitions

**Installation Steps:**
- `steps/terminal.yml` - Terminal/dotfiles configuration via Dotbot
- `steps/dependencies.yml` - Disabled dependencies file
- `install` - Main bash installation script

**Tool Configuration:**
- `Brewfile` - Global Homebrew packages (159 lines)
- `Brewfile_Fanaka` - User-specific Homebrew packages
- `Brewfile_Client` - Machine-specific client packages
- `.config/atuin/config.toml` - History configuration
- `.config/aider.conf.yml` - AI editor configuration (Vertex AI Claude Sonnet 4.5)
- `.config/aerospace/aerospace.toml` - Window manager configuration
- `.config/oh-my-posh.omp.json` - Prompt configuration
- `.config/lsd/config.yaml` - Directory listing configuration
- `.config/karabiner/karabiner.json` - Keyboard remapping
- `.config/lazygit.yml` - Git client configuration

## Platform Requirements

**Development:**
- macOS (Darwin) - Only supported platform
- Apple Silicon (aarch64-darwin) - Primary architecture
- x86_64-darwin - Secondary architecture support
- 256MB+ disk space for dotfiles and linked configurations

**Production:**
- macOS running latest stable versions
- Homebrew installation required
- Nix package manager (for feature/nix branch)
- Git repository access (SSH key required)

## Additional Runtime Support

**Supported Shells:**
- Zsh (primary, fully configured)
- Bash (compatibility mode)
- Nushell (installed, can be alternative)

**IDE & Editors:**
- Claude Code - With agent scripts for debugging and codebase mapping
- Neovim - Symlinked configuration at `~/.config/nvim`
- Sublime Text - Configured via Homebrew cask

**macOS App Management:**
- Mac App Store integration via `mas` CLI
- Mackup - Synced configuration backup/restore

---

*Stack analysis: 2026-01-25*
