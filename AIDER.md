# AIDER.md

This file provides guidance to Aider (aider.chat) when working with code in this repository.

## Repository Overview

This repository contains ZSH dotfiles for macOS configuration. It uses Dotbot for managing symlinks and Homebrew for package installation. The repository is structured to provide a complete terminal environment setup with custom configurations for various tools.

## Repository Structure

- **install**: Main installation script that runs Dotbot with configuration from steps/ directory
- **steps/**: Contains YAML files defining what to install and how
  - `terminal.yml`: Symlinks for shell configuration files
  - `dependencies_global.yml`: Global package installation via Homebrew
  - `dependencies_client.yml`, `dependencies_fanaka.yml`: Machine-specific configurations
- **zsh.d/**: Custom ZSH configuration files
  - `aliases.zsh`: Shell aliases and shortcuts
  - `functions.zsh`: Custom shell functions
  - `variables.zsh`: Environment variables
  - Other files for completions, hooks, keybinds, etc.
- **.config/**: Actual configuration files for various tools
- **Brewfile**: Defines packages to install via Homebrew

## Commands

### Installation

To install the dotfiles:

```bash
# Clone the repository
git clone --recursive git@github.com:sleicht/dotfiles-zsh.git ~/.dotfiles

# Run the installation
cd ~/.dotfiles && ./install
```

### Updating

To update the dotfiles after making changes:

```bash
# Pull latest changes
git pull

# Run the installation script again to apply changes
./install
```

### Homebrew Package Management

```bash
# Update Homebrew and installed packages
brew update && brew upgrade && brew cleanup

# Add new packages to Brewfile, then run
brew bundle
```

## Key Features

1. **Shell Plugin Management**: Uses Sheldon instead of native Oh My Zsh
2. **Advanced History**: Integrated with Atuin for better history search and sync
3. **Modern CLI Tools**: Configured with replacements for standard Unix tools
  - bat (instead of cat)
  - duf (instead of df)
  - dust (instead of du)
  - bottom (instead of top/htop)
  - lsd (instead of ls)
4. **Shell Completions**: Carapace for better shell completions
5. **Navigation**: Zoxide for faster directory navigation

## Technical Details

1. **Dotbot**: The system uses Dotbot to create symlinks from files in the repository to the appropriate locations in the home directory. Configuration is in `steps/terminal.yml`.

2. **Sheldon**: Plugin management is handled by Sheldon, configured in `.config/sheldon/plugins.toml`.

3. **Shell Configuration Files**:
  - `.zshrc`: Main ZSH configuration
  - `.zshenv`, `.zprofile`: Environment variable setup
  - `zsh.d/*.zsh`: Modular configuration files loaded by sheldon

## Guidelines for Code Changes

- When modifying shell configuration, ensure changes are modular and placed in appropriate files under `zsh.d/`
- Test changes by sourcing the modified files or restarting the shell
- Keep machine-specific configurations in separate Brewfiles (e.g., `Brewfile_Client`, `Brewfile_Fanaka`)
- Maintain compatibility with macOS and the tools installed via Homebrew
