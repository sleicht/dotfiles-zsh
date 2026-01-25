# AGENTS.md

Guidelines for AI coding agents working in this ZSH dotfiles repository.

## Repository Overview

macOS ZSH dotfiles using Dotbot for symlink management and Homebrew for packages. Modular shell configuration with zgenom plugin management.

## Build/Install Commands

```bash
# Install/update dotfiles (creates symlinks via Dotbot)
./install

# Update shell plugins after changes
zgenom reset && zgenom save

# Homebrew package management
brew bundle                              # Install from Brewfile
brew update && brew upgrade && brew cleanup
```

There are no test commands or CI/CD pipelines in this repository.

## Linting

Use `shellcheck` for all shell scripts. Many files include ZSH-specific pragmas:

```bash
# Check a script
shellcheck zsh.d/your-script.zsh

# Common pragmas for ZSH-isms (Shellcheck targets POSIX/Bash)
# shellcheck disable=SC2139  # Word expansion in alias
# shellcheck disable=SC2154  # Variable referenced but not assigned
```

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `zsh.d/` | Modular ZSH configuration files (aliases, functions, etc.) |
| `.config/` | Tool configuration files (symlinked to ~/.config/) |
| `steps/` | Dotbot YAML configuration files |
| `dotfiles-marketplace/` | Claude/OpenCode plugin definitions |

## Code Style Guidelines

### General Formatting

- **Indentation**: 2 spaces (see `.editorconfig`)
- **Line endings**: LF (Unix style)
- **Max line length**: 120 characters
- **Final newline**: Always include
- **Trailing whitespace**: Remove

### Shell Script Conventions

1. **Shebang**: Always include `#!/usr/bin/env zsh` for ZSH scripts
2. **Shellcheck**: Add pragmas for ZSH-specific constructs
3. **Variables**: Use `local` for function-scoped variables
4. **Quoting**: Always quote variables: `"$variable"` not `$variable`
5. **Conditionals**: Use `[[ ]]` for tests (ZSH-specific)
6. **Command substitution**: Use `$(command)` not backticks

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files in zsh.d/ | lowercase with `.zsh` extension | `aliases.zsh` |
| Functions | lowercase with underscores | `add_to_path()` |
| Aliases | lowercase, short | `gs`, `gc`, `gd` |
| Environment variables | UPPERCASE | `DOTFILES`, `HOMEBREW_PREFIX` |
| Local variables | lowercase with underscores | `local dir_name` |

### Function Structure

```zsh
function_name() {
  local arg1="$1"
  local result

  if [[ -z "$arg1" ]]; then
    echo "usage: function_name <arg>" >&2
    return 1
  fi

  # Implementation
  result="processed"
  echo "$result"
}
```

### Adding New Configuration

1. **New shell logic**: Create file in `zsh.d/` with `.zsh` extension
2. **New tool config**: Add to `.config/`, update `steps/terminal.yml` for symlink
3. **New Homebrew package**: Add to appropriate `Brewfile` or `Brewfile_*`

## Key Files

| File | Purpose |
|------|---------|
| `install` | Main installation script (runs Dotbot) |
| `steps/terminal.yml` | Symlink definitions |
| `steps/dependencies.yml` | Brewfile definitions |
| `.config/zgenom/zgenomrc.zsh` | Shell plugin loader |
| `zsh.d/aliases.zsh` | Shell aliases |
| `zsh.d/functions.zsh` | Shell functions |
| `zsh.d/variables.zsh` | Environment variables |
| `zsh.d/path.zsh` | PATH modifications |
| `zsh.d/external.zsh` | External tool configuration (fzf, zoxide, mise) |
| `zsh.d/hooks.zsh` | Shell hooks and plugin loading |

## Git Commit Messages

This repository uses Conventional Commits with Jira ticket prefixes:

```
<jira-ticket>: <type>[scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code style changes (formatting) |
| `refactor` | Code refactoring |
| `perf` | Performance improvements |
| `test` | Adding or updating tests |
| `build` | Build system or dependency changes |
| `ci` | CI/CD configuration changes |
| `chore` | Other changes |

### Examples

```
MLE-999: feat: add new shell alias for kubectl
MLE-999: fix(aliases): correct typo in git alias
MLE-999: docs: update README with installation steps
```

## Error Handling

```zsh
# Return non-zero on error
if [[ ! -d "$dir" ]]; then
  echo "Error: Directory not found" >&2
  return 1
fi

# Use set -e in scripts for fail-fast behaviour
set -e
```

## Architecture Patterns

### Modular Loading

Files in `zsh.d/` are loaded via zgenom. After adding new files:

```bash
zgenom reset && zgenom save
```

### Homebrew Architecture Detection

```zsh
if [ "$(uname -m)" = "x86_64" ]; then
  export HOMEBREW_PREFIX="/usr/local"
elif [ "$(uname -m)" = "arm64" ]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
fi
```

### PATH Management

Use the `add_to_path` function from `zsh.d/path.zsh`:

```zsh
add_to_path() {
  if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}
```

## Testing Changes

```bash
# Source a modified file to test
source zsh.d/your-modified-file.zsh

# Or reload the entire shell
exec $SHELL -l

# Or use the alias
reloadshell
```

## Common Patterns

### Conditional Tool Loading

```zsh
if command -v tool_name > /dev/null; then
  eval "$(tool_name init zsh)"
fi
```

### Safe File Sourcing

```zsh
if [ -r "$file_path" ]; then
  source "$file_path"
fi
```

## Do Not

- Commit machine-specific paths (use variables like `$HOME`, `$DOTFILES`)
- Add secrets or credentials to any file
- Modify files in `dotbot/`, `zgenom/`, or other submodule directories
- Use `cd` in scripts without returning (use subshells or `pushd`/`popd`)
