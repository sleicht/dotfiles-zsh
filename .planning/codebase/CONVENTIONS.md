# Coding Conventions

**Analysis Date:** 2026-01-25

## Overview

This repository contains ZSH dotfiles for macOS configuration with mixed shell scripts and Python code. The primary code is shell scripts (ZSH/Bash), with a Python testing framework in the Dotbot submodule. Conventions are enforced through EditorConfig and ShellCheck directives.

## Naming Patterns

**Files:**
- ZSH configuration files: `lowercase-with-hyphens.zsh` (e.g., `aliases.zsh`, `functions.zsh`, `completions.zsh`)
- Helper scripts: `kebab-case.sh` (e.g., `statusline-command.sh`)
- Python test files: `test_*.py` (e.g., `test_link.py`, `test_config.py`)
- YAML configuration: `lowercase.yml` or `lowercase.yaml` (e.g., `terminal.yml`, `dependencies.yml`)
- Brewfiles: `Brewfile` or `Brewfile_Machinename` (e.g., `Brewfile_Client`, `Brewfile_Fanaka`)

**Functions:**
- ZSH functions: lowercase with underscores as needed (e.g., `pyclean`, `mkd`, `cdf`, `targz`, `getcertnames`)
- Functions use `function` keyword or direct definition syntax: `function name() { ... }`
- Bash-like definition also used: `name() { ... }`
- Mixed convention observed in codebase

**Variables:**
- Environment variables: `UPPERCASE_WITH_UNDERSCORES` (e.g., `DOTFILES`, `HOMEBREW_PREFIX`, `XDG_CONFIG_HOME`)
- Local variables: `lowercase_with_underscores` (e.g., `dir_name`, `current_dir`, `branch`)
- Functions use local keyword for scoped variables: `local var_name="$1"`

**Types/Aliases:**
- Bash/ZSH aliases: lowercase or lowercase_with_underscores, often short forms
  - Examples: `..`, `gs` (git status), `gb` (git branch), `gcm` (git commit -m)
  - Expansion aliases documented with comments showing purpose
  - Path aliases like `dotfiles`, `library`, `cdl` used for navigation

## Code Style

**Formatting:**
- EditorConfig enforced: `.editorconfig`
- Default settings:
  - Indent: 2 spaces (all files except Python)
  - Python: 4 spaces indent
  - Line length: 120 characters max
  - Character encoding: UTF-8
  - Line endings: LF (Unix)
  - Trailing whitespace: trimmed
  - Final newline: inserted if missing
  - Tab width: 2 spaces

**Linting:**
- ShellCheck directives used sparingly: `# shellcheck disable=SC2139` pattern
- Found in: `aliases.zsh`, `carapace.zsh`, `variables.zsh`
- Directives disable specific warnings when needed
- No centralized `.shellcheckrc` found; uses inline directives only
- No automated linting pipeline detected in main dotfiles

**Error Handling in Shell:**
- Installation script (`install`) uses `set -e` for immediate exit on error
- Functions return explicit error codes (e.g., `return 1`, `return 137`)
- Most shell functions use error checking with `||` syntax
- Examples from `functions.zsh`:
  - `mkdir -p "$dir_name" && cd "$dir_name"` (command chaining)
  - Early returns on argument validation: `return 137` for invalid arguments
  - Output redirection to `/dev/null` for error suppression: `command 2>/dev/null`

**Error Handling in Python:**
- Type hints used throughout test code (e.g., `def test_link_canonicalization(home: str, dotfiles: Dotfiles, run_dotbot: Callable[..., None]) -> None`)
- Assertions with descriptive messages: `assert expected == actual, "description"`
- Exception handling with context managers for cleanup (try/finally patterns)
- Mock-based error isolation

## Import Organization

**ZSH Configuration:**
- Shebang always first: `#!/usr/bin/env zsh`
- ShellCheck directives immediately follow shebang
- Comments explaining purpose next: `# 'filename.zsh' provides...`
- Then blank line before code starts

**Python:**
- Standard library imports first (no comments between groups)
- Third-party imports next (pytest, yaml, dotbot)
- Local imports last (from tests.conftest import Dotfiles)
- Alphabetical ordering within groups

**External Tool Integration:**
- Commands sourced from Homebrew paths: `$HOMEBREW_PREFIX/opt/...`
- Conditional sourcing with existence checks: `if [ -r "/path/to/file" ]; then source "/path/to/file"; fi`
- Tool initialization via `eval` for dynamic shell integration
- Examples: `eval "$(zoxide init zsh --no-cmd)"`, `eval "$(mise activate zsh)"`

## Comments

**When to Comment:**
- Function headers explaining purpose (observed in `functions.zsh`)
- Complex operations needing explanation (e.g., algorithm details in compression logic)
- Configuration sections separated by comment headers: `# === Section Name ===`
- Disabled code kept with comments explaining why (e.g., `#if command -v direnv`)
- Platform-specific sections marked with comments

**JSDoc/DocStrings:**
- Python docstrings used for test fixtures and utility functions
- Format follows PEP 257 style
- Example from `conftest.py`:
  ```python
  def get_long_path(path: str) -> str:
      """Get the long path for a given path."""
  ```
- ZSH functions rarely have formal docstrings; use inline comments instead

## Function Design

**Size:**
- Functions kept relatively compact (5-30 lines typically)
- Larger utilities broken into logical sections with comments
- `targz()` function at ~35 lines is among the larger examples
- Most utility functions under 20 lines

**Parameters:**
- Positional parameters used: `$1`, `$2`, etc.
- Local variable binding: `local var_name="$1"`
- Validation at function start with error returns
- Example from `mc()`: checks parameter count and returns early on failure
- Optional parameters handled with defaults using `${var:-default}` pattern

**Return Values:**
- Functions return exit codes (0 for success, non-zero for failure)
- Explicit return statements: `return 1`, `return 0`
- Command output captured via command substitution `$(...)`
- Side effects documented in comments (e.g., "changes working directory")

## Module Design

**Exports:**
- ZSH files define functions and aliases directly (no export needed for shell scope)
- Python modules use clear `from module import Class` patterns
- Environment variables explicitly exported: `export VAR_NAME="value"`
- Functions exposed at file level; no private function convention observed

**Barrel Files:**
- No barrel/index files observed in ZSH configuration
- Each `.zsh` file in `zsh.d/` is self-contained
- No re-exports or aggregation patterns used
- Configuration files source directly by name

## Path Management

**Pattern Observed:**
- Helper function `add_to_path()` in `path.zsh` prevents duplicate PATH entries
- Function checks both directory existence and prevents duplicates:
  ```bash
  add_to_path() {
    if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
      export PATH="$1:$PATH"
    fi
  }
  ```
- Called repeatedly for different toolchain paths (Ruby, Node, Cargo, etc.)
- Paths added to front: `PATH="$1:$PATH"` for priority ordering

## Configuration File Patterns

**YAML Configuration:**
- Dotbot configuration in `steps/terminal.yml` follows YAML array structure
- Each configuration block is a mapping (dict) in an array
- Path specifications use Dotbot syntax with `create`, `force`, `relink` flags
- Comments used for grouping related configurations

**Brewfile Format:**
- Taps listed first (custom Homebrew repositories)
- Packages follow standard Homebrew naming
- Comments with descriptions of complex packages
- No versioning specified in main Brewfile

## ZSH-Specific Patterns

**Option Management:**
- Uses `setopt` for ZSH options (e.g., `setopt local_options BASH_REMATCH`)
- `autoload` used for ZSH builtins (e.g., `autoload -Uz colors`)
- Completion configuration via `zstyle` directives
- Example: `zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z} r:|[-_.]=**'`

**Conditional Execution:**
- Commands checked via `hash command 2> /dev/null` or `command -v command > /dev/null`
- Prevents errors when optional tools not installed
- Used extensively in external tool initialization

**Variable Expansion:**
- Parameter expansion used for defaults: `${var:-default}`
- Conditional assignment: `: "${VAR:=default}"` (colon for no-op)
- Array expansion: `${(s.:.)LS_COLORS}` for parameter expansion flags

---

*Convention analysis: 2026-01-25*
