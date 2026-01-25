# Features Analysis: chezmoi + mise Migration

Research for migrating from Nix/Home Manager + Dotbot + asdf to chezmoi + mise.

**Date**: 2026-01-25
**Context**: Evaluating migration features and capabilities for dotfiles management consolidation.

---

## Migration Essentials

### chezmoi Migration Features

**Complexity**: Low to Medium
**Priority**: Critical

#### Import Mechanisms

1. **Basic File Import** ([Setup Guide](https://www.chezmoi.io/user-guide/setup/))
   - `chezmoi add <file>` - Copies files to chezmoi's source state
   - Creates `~/.local/share/chezmoi` git repository
   - Renames files with `.` prefix to `dot_` prefix
   - Git preserves rename history for per-file tracking

2. **Symlink Migration** ([Migration Guide](https://www.chezmoi.io/migrating-from-another-dotfile-manager/))
   - `chezmoi add --follow <symlink>` - Adds symlink targets, not symlinks themselves
   - **Critical for Dotbot migration**: Dotbot uses symlinks extensively
   - Without `--follow`, chezmoi would add symlinks instead of actual files

3. **Incremental Migration with .chezmoiroot** ([Quick Start](https://www.chezmoi.io/quick-start/))
   - Allows gradual migration by specifying root directory
   - Preserves existing git repository history
   - Example workflow:
     ```bash
     git clone https://github.com/user/dotfiles.git ~/.local/share/chezmoi
     cd ~/.local/share/chezmoi
     mkdir home
     echo home > .chezmoiroot
     chezmoi add --follow ~/.bashrc
     ```

#### Key Migration Challenges

1. **Workflow Adjustment** ([Hacker News Discussion](https://news.ycombinator.com/item?id=18902090))
   - Requires editing files in `~/.local/share/chezmoi` first, then applying
   - Different from symlink-based systems where you edit files in place
   - Can use `chezmoi edit` to edit and apply in one step

2. **File Structure Changes** ([GitHub Issue #753](https://github.com/twpayne/chezmoi/issues/753))
   - Uses `dot_` prefix convention instead of directory-based organization
   - May appear less organized than symlink-based `.config/` structure
   - Trade-off: Enables powerful templating and per-file attributes

### mise Migration Features

**Complexity**: Very Low
**Priority**: Critical

#### asdf Compatibility

1. **Drop-in Replacement** ([Comparison Guide](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html))
   - Reads existing `.tool-versions` files natively
   - Supports asdf plugin ecosystem (210/846 tools still use asdf backend as of 2026)
   - Command compatibility: `mise install node 20.0.0` works like asdf

2. **Configuration Migration** ([FAQ](https://mise.jdx.dev/faq.html))
   - Automatic: Continue using `.tool-versions` files
   - Manual conversion script for global config:
     ```bash
     mv ~/.tool-versions ~/.tool-versions.bak
     cat ~/.tool-versions.bak | tr -s ' ' | tr ' ' '@' | xargs -n2 mise use -g
     ```
   - Recommended: Convert to `~/.config/mise/config.toml` for full feature access

3. **Backend Evolution** ([Supply Chain Security Discussion](https://github.com/jdx/mise/discussions/4054))
   - Modern tools use aqua/ubi backends (75% of registry)
   - Legacy asdf backend maintained for compatibility
   - Seamless transition: Tools work regardless of backend

#### Migration Path

1. **Install mise**: `brew install mise`
2. **Continue using .tool-versions**: No changes required immediately
3. **Optional**: Convert to mise.toml for advanced features
4. **Gradual backend migration**: Tools automatically upgrade to modern backends when available

---

## Templating Capabilities

### chezmoi Templating

**Complexity**: Medium
**Priority**: Essential for cross-platform support

#### Core Template Engine

1. **Go text/template + Sprig** ([Templating Guide](https://www.chezmoi.io/user-guide/templating/))
   - Standard Go templating with 100+ helper functions
   - Sprig extension library for advanced operations
   - Full programming capabilities: conditionals, loops, string manipulation

2. **Platform Detection** ([Machine Differences Guide](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/))
   - `.chezmoi.os`: Operating system (darwin, linux, windows)
   - `.chezmoi.arch`: Architecture (amd64, arm64)
   - `.chezmoi.osRelease`: Linux distribution info
   - `.chezmoi.hostname`: Hostname (up to first dot)
   - Example:
     ```
     {{ if eq .chezmoi.os "darwin" }}
     # macOS-specific configuration
     {{ else if eq .chezmoi.os "linux" }}
     # Linux-specific configuration
     {{ end }}
     ```

#### Cross-Platform Patterns

1. **Separate Files per OS** ([Cross-Platform Guide](https://alfonsofortunato.com/posts/dotfile/))
   - Use `include` function for completely different files
   - Example: `.bashrc` template includes `.bashrc_darwin` on macOS
   - Benefits: Clean separation, easier to maintain OS-specific configs

2. **OS-Specific File Variants** ([Linux Guide](https://www.chezmoi.io/user-guide/machines/linux/))
   - Naming convention: `file.tmpl`, `file_darwin.tmpl`, `file_linux.tmpl`
   - chezmoi automatically selects correct variant
   - Reduces conditional logic in templates

3. **Distribution-Specific Logic** ([Machine Management](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/))
   - Custom variables combining OS and distro:
     ```
     {{ .chezmoi.os }}-{{ .chezmoi.osRelease.id }}
     ```
   - Handles Ubuntu, Arch, Fedora, etc. differences

#### Machine-Specific Configuration

1. **chezmoidata Files** ([Variables Reference](https://www.chezmoi.io/reference/templates/variables/))
   - `.chezmoidata.toml`, `.chezmoidata.yaml`, `.chezmoidata.json`
   - Define custom variables per machine
   - Read in alphabetical order, later values override

2. **Configuration File** ([Configuration Reference](https://www.chezmoi.io/reference/configuration-file/))
   - `~/.config/chezmoi/chezmoi.toml` per machine
   - Not tracked in git (machine-local settings)
   - Define email, name, machine type, custom variables
   - Example:
     ```toml
     [data]
         email = "work@company.com"
         machineType = "work"
     ```

3. **View All Variables** ([Managing Dotfiles](https://anshumantripathi.com/blog/managing-dotfiles-with-chezmoi-guide/))
   - `chezmoi data` shows all available template variables
   - Helpful for debugging template issues
   - Shows OS, arch, hostname, username, plus custom data

### mise Environment Configuration

**Complexity**: Low to Medium
**Priority**: Important for multi-environment workflows

#### Config Environments

1. **Environment-Specific Files** ([Config Environments](https://mise.jdx.dev/configuration/environments.html))
   - `mise.<env>.toml` files (e.g., `mise.development.toml`)
   - Set via `MISE_ENV=development`
   - Multiple environments: `MISE_ENV=ci,test` (comma-separated)
   - Use case: Different tool versions per environment

2. **Early-Init Setting** ([Environments Guide](https://mise.jdx.dev/environments/))
   - MISE_ENV must be set in `.miserc.toml`, environment variables, or `-E` flag
   - Setting in `mise.toml` has no effect (determines which files to load)
   - Hierarchical merging: Specific configs override general ones

3. **CLI Integration** ([mise set](https://mise.jdx.dev/cli/set.html))
   - `mise set -E dev KEY=value` - Sets variable in environment-specific config
   - `mise use -E production node@20` - Adds tool to specific environment
   - Enables scripted environment setup

---

## Secret Management

### chezmoi Secret Options

**Complexity**: Medium to High (depending on method)
**Priority**: Essential for credentials and tokens

#### 1Password Integration

**Complexity**: Low
**Recommended for**: Existing 1Password users

- **Template Functions** ([1Password Guide](https://www.chezmoi.io/user-guide/password-managers/1password/))
  - `onepasswordRead`: Reads secret from `op://` URI
  - `onepassword`: Fetches item as JSON, enables field selection
  - Example:
    ```
    export CF_API_TOKEN='{{ onepasswordRead "op://Personal/cloudflare-api-token/password" }}'
    ```

- **Advanced Features** ([1Password Functions](https://www.chezmoi.io/reference/templates/1password-functions/))
  - 1Password Connect support (for automation)
  - Service Account support (CI/CD pipelines)
  - **Limitation**: Connect/Service Accounts don't support multiple 1Password accounts

- **Benefits** ([GitHub Example](https://github.com/abrauner/dotfiles))
  - Secrets never stored in git
  - Automatic fetching on apply
  - Cross-platform support

#### age Encryption

**Complexity**: Low
**Recommended for**: Simple, modern encryption

- **Builtin Support** ([age Guide](https://www.chezmoi.io/user-guide/encryption/age/))
  - chezmoi has builtin age encryption (no external command needed)
  - File naming: `encrypted_file.age` or `encrypted_private_file.tmpl.age`
  - Automatic decryption when generating target state

- **Features** ([Switching to age](https://luke.hsiao.dev/blog/gpg-to-age/))
  - Multiple identities and recipients supported
  - Symmetric encryption with passphrase (external age command)
  - Much simpler than GPG setup
  - User report: "age setup was surprisingly trivial" vs. hours for GPG/YubiKey

- **Limitations** ([age Reference](https://www.chezmoi.io/user-guide/encryption/age/))
  - Builtin version doesn't support passphrases or SSH keys
  - External age command required for full features

#### GPG Encryption

**Complexity**: High
**Recommended for**: Existing GPG infrastructure

- **Full-Featured** ([GPG Guide](https://www.chezmoi.io/user-guide/encryption/gpg/))
  - Symmetric encryption support
  - Public/private key encryption
  - Integration with hardware tokens (YubiKey)
  - Encrypted file naming: `encrypted_file.gpg`

- **Trade-offs** ([Encryption FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/))
  - More complex setup and maintenance
  - Better for teams with existing GPG workflows
  - Migration possible: Can switch from GPG to age with re-encryption script

#### Other Password Managers

**Complexity**: Medium
**Options**: Bitwarden, LastPass, Pass, Vault, etc.

- **Template Functions** ([Password Managers](https://www.chezmoi.io/user-guide/password-managers/))
  - Similar patterns to 1Password
  - Manager-specific template functions
  - CLI tool integration required

- **Full File Encryption Alternatives** ([Encryption Options](https://www.chezmoi.io/user-guide/frequently-asked-questions/encryption/))
  - git-crypt: Transparent encryption in git
  - transcrypt: Another git-based encryption tool
  - Trade-off: Less flexible than template-based secret retrieval

---

## Cross-Platform Support

### chezmoi Cross-Platform Features

**Complexity**: Low to Medium
**Priority**: Critical for macOS/Linux usage

#### OS Detection Variables

1. **Core Platform Variables** ([Templating Reference](https://www.chezmoi.io/user-guide/templating/))
   - `.chezmoi.os`: darwin, linux, windows, freebsd, openbsd
   - `.chezmoi.osRelease.id`: ubuntu, arch, fedora, debian (Linux only)
   - `.chezmoi.osRelease.versionID`: Distribution version
   - `.chezmoi.kernel.ostype`, `.chezmoi.kernel.osrelease`

2. **Hardware Detection** ([General Guide](https://www.chezmoi.io/user-guide/machines/general/))
   - `.chezmoi.arch`: amd64, arm64, 386
   - Custom chassisType detection (desktop vs laptop)
   - Example:
     ```
     {{ $chassisType := "desktop" }}
     {{ if eq .chezmoi.os "darwin" }}
     {{   $chassisType = output "sh" "-c" "system_profiler SPHardwareDataType | grep 'Model Name' | grep -q MacBook && echo laptop || echo desktop" }}
     {{ end }}
     ```

#### Package Management Integration

1. **Script-Based Installation** ([Scripts Guide](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/))
   - `run_once_before_install-packages.sh.tmpl`
   - Platform-specific package managers:
     ```bash
     {{ if eq .chezmoi.os "darwin" }}
     brew bundle --file=- <<EOF
     {{ include "Brewfile" }}
     EOF
     {{ else if eq .chezmoi.os "linux" }}
     {{ if eq .chezmoi.osRelease.id "ubuntu" }}
     sudo apt-get update && sudo apt-get install -y {{ .packages.ubuntu }}
     {{ else if eq .chezmoi.osRelease.id "arch" }}
     sudo pacman -S --noconfirm {{ .packages.arch }}
     {{ end }}
     {{ end }}
     ```

2. **chezmoidata Package Lists** ([Advanced Guide](https://kidoni.dev/using-templates-with-chezmoi))
   - Define package lists in `.chezmoidata.toml`
   - Map package names across distributions
   - Example:
     ```toml
     [packages]
     darwin = ["neovim", "ripgrep", "fd"]
     ubuntu = ["neovim", "ripgrep", "fd-find"]
     arch = ["neovim", "ripgrep", "fd"]
     ```

#### Platform-Specific Files

1. **File Variants** ([Cross-Platform Example](https://github.com/lkdm/dotfiles))
   - Suffix-based selection: `_darwin`, `_linux`, `_windows`
   - `zshrc_darwin`, `zshrc_linux`
   - Automatically selected based on OS
   - No template logic needed in files

2. **Conditional Inclusion** ([Include Files](https://www.chezmoi.io/user-guide/include-files-from-elsewhere/))
   - Include platform-specific partials
   - Cleaner than large conditional blocks
   - Easier to maintain OS-specific configurations

### mise Cross-Platform Behavior

**Complexity**: Very Low
**Priority**: Important

#### Platform Support

1. **Unified Tool Management** ([GitHub Repository](https://github.com/jdx/mise))
   - Single command works across macOS, Linux, Windows
   - Tool backends handle platform differences
   - aqua and ubi backends include Windows support

2. **Backend Selection by Platform** ([Backend Architecture](https://mise.jdx.dev/dev-tools/backend_architecture.html))
   - Modern backends (aqua, ubi): Cross-platform
   - asdf backend: macOS and Linux only (no Windows)
   - Automatic fallback when tools unavailable on platform

---

## Nice-to-Have Features

### chezmoi Advanced Features

**Complexity**: Varies
**Priority**: Enhance workflow but not critical for migration

#### 1. Script Execution System

**Complexity**: Low to Medium

- **Script Types** ([Scripts Guide](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/))
  - `run_`: Executes every `chezmoi apply`
  - `run_onchange_`: Executes only when script content changes
  - `run_once_`: Executes once per unique script version
  - Timing: `before_` or `after_` attributes control execution order

- **Use Cases** ([Target Types](https://www.chezmoi.io/reference/target-types/))
  - Install dependencies before applying dotfiles
  - Run post-installation setup scripts
  - Configure system settings (macOS defaults)
  - Example: `run_once_before_install-homebrew.sh`

#### 2. Hooks System

**Complexity**: Medium

- **Event Hooks** ([Hooks Reference](https://www.chezmoi.io/reference/configuration-file/hooks/))
  - Pre/post hooks for chezmoi events
  - `read-source-state.pre`: Run before reading source (install prerequisites)
  - Always run, even with `--dry-run`
  - Should be fast and idempotent

- **Benefits** ([GitHub Discussion #1817](https://github.com/twpayne/chezmoi/discussions/1817))
  - Install tools needed for template processing
  - Validate environment before applying
  - Trigger external integrations (backups, notifications)

#### 3. Diff and Preview

**Complexity**: Low

- **Safe Application** ([Usage FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/))
  - `chezmoi diff`: Shows what would change
  - `chezmoi apply --dry-run`: Simulates application
  - `chezmoi apply --verbose`: Shows detailed changes
  - Prevents accidental overwrites

#### 4. External File Inclusion

**Complexity**: Low

- **Include from URLs** ([Include Files Guide](https://www.chezmoi.io/user-guide/include-files-from-elsewhere/))
  - Fetch configuration from external sources
  - Share common configs across repositories
  - Example: Include team-wide configurations

- **Use Case**: Organization-wide standards
  - Shared linting configs
  - Common shell functions
  - Team conventions

#### 5. File Removal Management

**Complexity**: Low

- **Declarative Removal** ([Application Order](https://www.chezmoi.io/reference/application-order/))
  - Prefix files with `.chezmoiremove`
  - chezmoi removes files from target state
  - Useful for cleaning up deprecated configs

### mise Advanced Features

**Complexity**: Varies
**Priority**: Enhance development workflow

#### 1. Task Runner

**Complexity**: Low to Medium

- **Built-in Task System** ([Tasks Guide](https://mise.jdx.dev/tasks/))
  - Define tasks in `[tasks]` section of `mise.toml`
  - Alternative: Standalone shell scripts in `.mise/tasks/`
  - Example:
    ```toml
    [tasks.test]
    description = "Run tests"
    run = "pytest tests/"
    depends = ["lint"]
    ```

- **Features** ([Task Configuration](https://mise.jdx.dev/tasks/task-configuration.html))
  - Task dependencies
  - Parallel execution (default: 4 jobs)
  - Access to mise environment (tools and env vars)
  - Alternative to `make`, `just`, or `npm scripts`

#### 2. Environment Variable Management

**Complexity**: Low

- **Per-Directory Env Vars** ([mise env](https://mise.jdx.dev/cli/set.html))
  - Like direnv, but integrated with tool management
  - Set in `mise.toml`: `[env]` section
  - Auto-activation when entering directory
  - Export formats: shell, JSON, dotenv

- **Benefits** ([Environments](https://mise.jdx.dev/environments/))
  - Consolidates direnv functionality
  - Single tool for versions + env vars + tasks
  - Better integration with mise tools

#### 3. Security Features (aqua backend)

**Complexity**: Low (automatic)

- **Supply Chain Security** ([Aqua Backend](https://mise.jdx.dev/dev-tools/backends/aqua.html))
  - Cosign verification
  - SLSA attestation
  - Minisign support
  - GitHub attestation verification
  - Automatic for aqua-based tools

- **Benefits** ([Security Discussion](https://github.com/jdx/mise/discussions/4054))
  - Protection against supply chain attacks
  - Verifiable tool downloads
  - Better than asdf's shell script approach

#### 4. Global Configuration Profiles

**Complexity**: Low

- **Config Hierarchy** ([Configuration Guide](https://mise.jdx.dev/configuration.html))
  - `~/.config/mise/config.toml`: Global defaults
  - Project-level: `mise.toml` in project root
  - Environment-specific: `mise.<env>.toml`
  - Recursive upward merging (project overrides global)

- **Use Case**: Shared configuration
  - Organization-wide tool versions
  - Team conventions
  - Personal defaults across all projects

#### 5. Backend Flexibility

**Complexity**: Low (automatic)

- **Multiple Backend Support** ([Plugins Guide](https://mise.jdx.dev/plugins.html))
  - aqua: Modern, secure, Windows support
  - ubi: Simple GitHub releases
  - asdf: Legacy compatibility
  - vfox: asdf-like with Windows support
  - Automatic backend selection per tool

- **Benefits** ([Backend Discussion](https://github.com/jdx/mise/discussions/2441))
  - Best backend for each tool
  - Gradual migration from asdf
  - No user intervention required

---

## Migration Complexity Summary

### Critical Path (Must-Have)

| Feature | Tool | Complexity | Blocker? |
|---------|------|------------|----------|
| Import existing dotfiles | chezmoi | Low-Medium | No |
| Symlink migration | chezmoi | Low | No |
| asdf compatibility | mise | Very Low | No |
| Basic templating | chezmoi | Medium | No |
| OS detection | chezmoi | Low | No |
| Secret management | chezmoi | Medium-High | Depends on requirements |

### Important (Recommended)

| Feature | Tool | Complexity | Value |
|---------|------|------------|-------|
| Machine-specific config | chezmoi | Medium | High |
| Cross-platform files | chezmoi | Low-Medium | High |
| Environment configs | mise | Low | Medium |
| Task runner | mise | Low-Medium | Medium |
| Script execution | chezmoi | Low-Medium | High |

### Nice-to-Have (Optional)

| Feature | Tool | Complexity | Value |
|---------|------|------------|-------|
| Hooks system | chezmoi | Medium | Low-Medium |
| External includes | chezmoi | Low | Low |
| mise env vars | mise | Low | Medium |
| Supply chain security | mise | Low (auto) | Medium |
| File removal management | chezmoi | Low | Low |

---

## Dependencies Between Features

```
Migration Foundation
├── chezmoi add --follow (enables symlink import)
│   └── Basic templating (enables OS-specific configs)
│       ├── Machine-specific config (extends templating)
│       ├── Secret management (uses templating)
│       └── Cross-platform support (uses templating)
│
└── mise .tool-versions compatibility (enables asdf migration)
    ├── mise.toml conversion (optional upgrade path)
    └── Environment configs (requires mise.toml)

Advanced Features (independent)
├── chezmoi scripts (standalone)
├── chezmoi hooks (standalone)
├── mise tasks (standalone)
└── mise backends (automatic)
```

---

## Recommendations

### Phase 1: Essential Migration (Low Risk)

1. **Install chezmoi and mise**
   - Complexity: Very Low
   - No changes to existing setup

2. **Initialize chezmoi with --follow**
   - Migrate symlink-based dotfiles
   - Preserve git history
   - Test in parallel with existing setup

3. **Continue using .tool-versions with mise**
   - Drop-in asdf replacement
   - Verify tool availability
   - No configuration changes needed

### Phase 2: Templating (Medium Risk)

4. **Add basic OS detection**
   - Start with simple conditionals
   - Focus on macOS/Linux differences
   - Test with `chezmoi diff`

5. **Implement machine-specific configs**
   - Create `~/.config/chezmoi/chezmoi.toml` per machine
   - Define work/personal variables
   - Use in templates

### Phase 3: Secrets (Medium-High Risk)

6. **Choose secret management strategy**
   - **If using 1Password**: Use template functions (recommended)
   - **If not**: Consider age encryption (simpler than GPG)
   - Test secret retrieval before full migration

### Phase 4: Advanced Features (Optional)

7. **Add installation scripts**
   - `run_once_before_install-packages.sh.tmpl`
   - Automate Homebrew bundle

8. **Migrate to mise.toml**
   - Convert for environment-specific configs
   - Add task runner if useful

9. **Implement mise tasks**
   - Replace Makefile or script commands
   - Consolidate workflow

---

## Sources

- [chezmoi Documentation](https://www.chezmoi.io/)
- [mise Documentation](https://mise.jdx.dev/)
- [chezmoi Migration Guide](https://www.chezmoi.io/migrating-from-another-dotfile-manager/)
- [mise vs asdf Comparison](https://mise.jdx.dev/dev-tools/comparison-to-asdf.html)
- [1Password Integration](https://www.chezmoi.io/user-guide/password-managers/1password/)
- [age Encryption](https://www.chezmoi.io/user-guide/encryption/age/)
- [Cross-Platform Templating](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [mise Task Runner](https://mise.jdx.dev/tasks/)
- [Backend Architecture](https://mise.jdx.dev/dev-tools/backend_architecture.html)
- [Community Examples](https://github.com/abrauner/dotfiles)
