# Phase 4: Package Management Migration - Research

**Researched:** 2026-01-27
**Domain:** Dotfile package management automation with chezmoi and Homebrew
**Confidence:** HIGH

## Summary

Phase 4 automates Homebrew package installation through chezmoi's declarative package management pattern, using `.chezmoidata.yaml` for package lists and `run_onchange_` scripts for automated installation. The standard approach combines templated Brewfile generation with brew bundle for idempotent package management. Nix removal is straightforward on macOS with established uninstallation procedures. The implementation leverages chezmoi's SHA256-based change detection to only run installation scripts when package lists change, providing fast subsequent applies while maintaining full sync capability through `brew bundle cleanup`.

**Primary recommendation:** Use `.chezmoidata.yaml` for structured package lists, template a Brewfile to `~/.Brewfile`, and use a `run_onchange_` script with brew bundle for automated installation. Include SHA256 hash comments to trigger reruns when package data changes. Use `run_once_` script to bootstrap Homebrew installation on fresh systems.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | 2.x | Dotfile management with templating | Industry standard for cross-platform dotfiles with 13k+ GitHub stars, official Homebrew package |
| Homebrew | 4.x | macOS package manager | De facto standard for macOS, 38k+ GitHub stars, excellent integration with chezmoi |
| brew bundle | bundled | Declarative package installation | Official Homebrew subcommand for Brewfile-based package management |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `.chezmoidata.yaml` | N/A | Static data storage | Store package lists, configuration data shared across templates |
| `run_onchange_` scripts | N/A | Change-triggered execution | Run installation scripts only when package lists change |
| `run_once_` scripts | N/A | One-time bootstrap | Install Homebrew on fresh systems, first-time setup tasks |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| chezmoi + Homebrew | Nix + Home Manager | Nix provides reproducibility but adds complexity, steeper learning curve, requires /nix volume |
| brew bundle | Manual brew install | Manual approach doesn't scale, no declarative state, prone to drift |
| `.chezmoidata.yaml` | Separate Brewfiles | Harder to manage machine-specific overrides, no templating benefits |

**Installation:**
```bash
# Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# chezmoi (already installed in Phase 2)
brew install chezmoi
```

## Architecture Patterns

### Recommended Project Structure
```
~/.local/share/chezmoi/
├── .chezmoidata.yaml              # Package lists and static data
├── .chezmoi.yaml.tmpl             # Machine-specific configuration
├── run_once_before_install-homebrew.sh.tmpl  # Bootstrap Homebrew
├── run_onchange_before_install-packages.sh.tmpl  # Install packages
└── dot_Brewfile.tmpl              # Generated Brewfile (optional alternative)
```

### Pattern 1: Declarative Package Management with Embedded Brewfile

**What:** Package lists in `.chezmoidata.yaml`, template script generates Brewfile inline and pipes to brew bundle
**When to use:** Standard approach recommended by chezmoi documentation, best for most users
**Example:**

`.chezmoidata.yaml`:
```yaml
# Source: chezmoi documentation
packages:
  darwin:
    taps:
    - 'homebrew/bundle'
    - 'nikitabobko/tap'
    brews:
    - 'git'
    - 'gh'
    - 'ripgrep'
    casks:
    - 'claude-code'
    - 'ghostty'
    mas:
      "Xcode": 497799835
      "Racompass": 1538380685
```

`run_onchange_before_install-packages.sh.tmpl`:
```bash
# Source: https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

set -eufo pipefail

echo "Installing Homebrew packages..."

brew bundle --no-lock --file=/dev/stdin <<EOF
{{ range .packages.darwin.taps -}}
tap {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.brews -}}
brew {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.casks -}}
cask {{ . | quote }}
{{ end -}}
{{ range $name, $id := .packages.darwin.mas -}}
mas {{ $name | quote }}, id: {{ $id }}
{{ end -}}
EOF
{{ end -}}
```

### Pattern 2: Generated Brewfile at ~/.Brewfile

**What:** Template a full Brewfile to `~/.Brewfile` for brew bundle --global compatibility
**When to use:** When you want a persistent Brewfile for manual brew bundle operations, or when integrating with existing Homebrew workflows
**Example:**

`dot_Brewfile.tmpl`:
```ruby
# Source: Adapted from chezmoi macOS documentation
{{ if eq .chezmoi.os "darwin" -}}
# Taps
{{ range .packages.darwin.taps -}}
tap {{ . | quote }}
{{ end }}
# Formulae
{{ range .packages.darwin.brews -}}
brew {{ . | quote }}
{{ end }}
# Casks
{{ range .packages.darwin.casks -}}
cask {{ . | quote }}
{{ end }}
# Mac App Store
{{ range $name, $id := .packages.darwin.mas -}}
mas {{ $name | quote }}, id: {{ $id }}
{{ end -}}
{{ end -}}
```

`run_onchange_after_install-packages.sh.tmpl`:
```bash
#!/bin/bash
# .chezmoidata.yaml hash: {{ include ".chezmoidata.yaml" | sha256sum }}
{{ if eq .chezmoi.os "darwin" -}}
set -eufo pipefail
brew bundle --global
{{ end -}}
```

### Pattern 3: Machine-Specific Package Lists

**What:** Combine common packages with machine-specific overrides using .chezmoidata structure
**When to use:** When different machines (work/personal) need different package sets
**Example:**

`.chezmoidata.yaml`:
```yaml
packages:
  # Common packages for all Darwin machines
  common_darwin:
    - git
    - gh
    - mise

  # Machine-specific additions
  machines:
    client:
      brews:
        - k9s
        - pre-commit
      casks:
        - lens
        - bruno
    fanaka:
      brews:
        - exercism
        - tailscale
      casks:
        - logseq
        - fantastical
```

Template combines them:
```bash
{{ range .packages.common_darwin -}}
brew {{ . | quote }}
{{ end -}}
{{ if eq .machine "client" -}}
{{ range .packages.machines.client.brews -}}
brew {{ . | quote }}
{{ end -}}
{{ end -}}
```

### Pattern 4: Bootstrap Homebrew Installation

**What:** Use `run_once_` script to install Homebrew on fresh systems before package installation
**When to use:** Always, for true one-command bootstrap (chezmoi init && chezmoi apply)
**Example:**

`run_once_before_install-homebrew.sh.tmpl`:
```bash
# Source: chezmoi macOS documentation pattern
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi
{{ end -}}
```

### Anti-Patterns to Avoid

- **Don't use `run_once_` for package installation**: Packages change over time, use `run_onchange_` instead. `run_once_` won't re-run when you add new packages.
- **Don't forget OS conditionals**: Always wrap Darwin-specific operations with `{{ if eq .chezmoi.os "darwin" -}}` to avoid errors on Linux.
- **Don't hardcode package lists in scripts**: Use `.chezmoidata.yaml` for data, templates for logic. Separation of concerns.
- **Don't use `brew bundle cleanup` without testing first**: Cleanup can remove dependencies if not all packages are declared. Always run without `--force` first to preview.
- **Don't template the Brewfile itself if using inline pattern**: Choose either embedded Brewfile in script OR templated `~/.Brewfile`, not both. Duplication leads to drift.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Package change detection | Custom file hash tracking | chezmoi's `run_onchange_` | Built-in SHA256 hashing, reliable state tracking, handles templates |
| Brewfile generation | Shell scripts concatenating strings | chezmoi templates with `.chezmoidata.yaml` | Type-safe, handles quoting, supports structured data |
| Cross-platform package management | Custom if/else for OS detection | chezmoi's `.chezmoi.os` variable | Standardized, works across all platforms, well-tested |
| Package cleanup logging | Custom scripts to capture output | brew bundle output + shell redirection | Homebrew shows what's removed, capture with `2>&1 | tee log.txt` |
| Machine identification | Environment variables | chezmoi's prompt mechanism + `.chezmoi.yaml.tmpl` | Persistent, version-controlled, prompts once |

**Key insight:** chezmoi's template system and script lifecycle handle 90% of dotfile automation complexity. Building custom solutions means reimplementing change detection, state tracking, and cross-platform compatibility—all already solved problems.

## Common Pitfalls

### Pitfall 1: brew bundle cleanup Removes Dependencies

**What goes wrong:** Running `brew bundle cleanup --force` removes packages that weren't explicitly listed in Brewfile but were installed as dependencies, breaking installations (e.g., ffmpeg dependencies get removed).

**Why it happens:** Homebrew doesn't distinguish between explicitly installed packages and auto-installed dependencies when using Brewfile cleanup. If you install ffmpeg (which has 50+ dependencies) but only list ffmpeg in your Brewfile, cleanup will remove those dependencies.

**How to avoid:**
- Use `brew bundle dump` FIRST to capture all currently installed packages and their dependencies before implementing cleanup
- Run `brew bundle cleanup --global` (without `--force`) to preview what would be removed
- Only use `--force` after verifying the preview list is correct
- Consider keeping cleanup disabled initially, enable only after validating package lists are complete

**Warning signs:** Packages that previously worked suddenly fail with "library not found" errors after running chezmoi apply with cleanup enabled.

### Pitfall 2: run_onchange_ Script Doesn't Rerun When .chezmoidata.yaml Changes

**What goes wrong:** You update package lists in `.chezmoidata.yaml` but the installation script doesn't run because chezmoi doesn't detect the change.

**Why it happens:** `run_onchange_` only triggers when the script's *own* content changes. Changing `.chezmoidata.yaml` changes the script's *output* after templating, but if you're using Pattern 1 (embedded Brewfile), the template range loops generate the same hash until .chezmoidata changes enough.

**How to avoid:** Include the hash of `.chezmoidata.yaml` in a comment in the script:

```bash
#!/bin/bash
# .chezmoidata.yaml hash: {{ include ".chezmoidata.yaml" | sha256sum }}
```

This makes the script content change whenever the data file changes, triggering rerun.

**Warning signs:** Adding packages to `.chezmoidata.yaml`, running `chezmoi apply`, but packages aren't installed.

### Pitfall 3: Nix Removal Leaves Daemon Running or Volume Mounted

**What goes wrong:** After uninstalling Nix, the daemon continues running, PATH still includes `/nix/store` paths, or `diskutil` shows the Nix Store volume still mounted.

**Why it happens:** The uninstallation process has ordering dependencies. Daemon must be stopped before volume deletion, and volume must be unmounted before deletion. Shell initialization files may still source nix-daemon.sh.

**How to avoid:**
- Follow official uninstall process in exact order (restore shell files → stop daemon → remove users → edit fstab → edit synthetic.conf → remove directories → delete volume)
- Verify each step completed: `launchctl list | grep nix` should return nothing after daemon removal
- Check `diskutil list` to confirm no "Nix Store" volume exists
- Grep shell config files for nix references: `grep -r "nix" /etc/zshrc /etc/bashrc ~/.zshrc 2>/dev/null`
- Reboot if volume deletion fails with "in use" error (kernel lock issue)

**Warning signs:** After uninstall, `which nix` still returns a path, or you see `/nix/store` in `echo $PATH`.

### Pitfall 4: Using run_once_ for Package Installation

**What goes wrong:** Packages install on first run but never update when you add new packages to the list, even after modifying `.chezmoidata.yaml`.

**Why it happens:** `run_once_` is designed for true one-time operations (like installing Homebrew itself). Once run successfully, it won't run again even if the script content changes, unless the SHA256 differs from *all* previous executions. If you previously had the same package list, chezmoi won't re-run.

**How to avoid:**
- Use `run_once_` only for bootstrap operations (installing Homebrew, creating directories)
- Use `run_onchange_` for package installation, which reruns whenever content changes
- Clear distinction: `run_once_before_install-homebrew.sh` (bootstrap) + `run_onchange_after_install-packages.sh` (packages)

**Warning signs:** New packages in `.chezmoidata.yaml` never get installed no matter how many times you run `chezmoi apply`.

### Pitfall 5: Missing mas Authentication

**What goes wrong:** `brew bundle` succeeds for brews and casks but fails silently or with auth errors for Mac App Store apps, leaving them uninstalled.

**Why it happens:** `mas` requires prior authentication with the Mac App Store and the apps must already be "purchased" (even if free) under your Apple ID. Running `mas install` for an app you haven't previously downloaded fails.

**How to avoid:**
- Ensure user is signed into Mac App Store before running chezmoi apply
- Pre-install all MAS apps manually once, or "purchase" free apps from the store
- Add check in script: `mas account` returns email if authenticated, error if not
- Consider documenting MAS apps separately, as they require manual setup step

**Warning signs:** brew bundle reports success but `mas list` doesn't show apps that were in Brewfile.

### Pitfall 6: Brewfile Templating Quoting Issues

**What goes wrong:** Package installation fails with syntax errors or packages with special characters in names aren't installed correctly.

**Why it happens:** Brewfile syntax requires proper quoting, especially for package names with hyphens, spaces, or special characters. Forgetting `| quote` in template range loops generates invalid Brewfile syntax.

**How to avoid:**
- Always use `{{ . | quote }}` in template range loops
- Test generated Brewfile with `chezmoi execute-template < .local/share/chezmoi/run_onchange_install.sh.tmpl`
- Validate syntax with `brew bundle check` before running installation

**Warning signs:** Errors like `Error: No available formula with the name "pre-commit"` when the package exists, or strange parsing errors from brew bundle.

## Code Examples

Verified patterns from official sources:

### Complete Package Management Setup

```bash
# File: ~/.local/share/chezmoi/run_once_before_install-homebrew.sh.tmpl
# Source: Adapted from https://www.chezmoi.io/user-guide/machines/macos/
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

set -eufo pipefail

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Configure Homebrew PATH for current session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi
{{ end -}}
```

```bash
# File: ~/.local/share/chezmoi/run_onchange_before_install-packages.sh.tmpl
# Source: https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

set -eufo pipefail

echo "Installing Homebrew packages..."

brew bundle --no-lock --file=/dev/stdin <<EOF
{{ range .packages.darwin.taps -}}
tap {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.brews -}}
brew {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.casks -}}
cask {{ . | quote }}
{{ end -}}
{{ range $name, $id := .packages.darwin.mas -}}
mas {{ $name | quote }}, id: {{ $id }}
{{ end -}}
EOF
{{ end -}}
```

### Package Cleanup with Audit Log

```bash
# File: ~/.local/share/chezmoi/run_onchange_after_cleanup-packages.sh.tmpl
# Source: Custom implementation based on https://docs.brew.sh/Brew-Bundle-and-Brewfile
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

set -eufo pipefail

CLEANUP_LOG="$HOME/.local/state/homebrew-cleanup.log"
mkdir -p "$(dirname "$CLEANUP_LOG")"

echo "=== Homebrew Cleanup: $(date -u +"%Y-%m-%dT%H:%M:%SZ") ===" >> "$CLEANUP_LOG"

# Preview what will be removed
echo "Packages that will be removed:"
brew bundle cleanup --global 2>&1 | tee -a "$CLEANUP_LOG"

echo ""
read -p "Proceed with cleanup? (yes/no) " -n 3 -r
echo
if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Removing packages not in Brewfile..."
    brew bundle cleanup --global --force 2>&1 | tee -a "$CLEANUP_LOG"
    echo "Cleanup completed at $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$CLEANUP_LOG"
else
    echo "Cleanup cancelled" | tee -a "$CLEANUP_LOG"
fi
{{ end -}}
```

### Combining Common and Machine-Specific Packages

```yaml
# File: ~/.local/share/chezmoi/.chezmoidata.yaml
packages:
  darwin:
    taps:
      - 'homebrew/bundle'
      - 'koekeishiya/formulae'
      - 'nikitabobko/tap'

    # Common packages for ALL Darwin machines
    common_brews:
      - 'git'
      - 'gh'
      - 'mise'
      - 'chezmoi'
      - 'ripgrep'
      - 'bat'
      - 'fzf'
      - 'sheldon'
      - 'zoxide'

    common_casks:
      - 'claude-code'
      - 'ghostty'
      - 'raycast'

    # Machine-specific overrides
    client_brews:
      - 'k9s'
      - 'pre-commit'
      - 'dive'

    client_casks:
      - 'lens'
      - 'bruno'
      - 'visual-studio-code'

    fanaka_brews:
      - 'exercism'
      - 'tailscale'

    fanaka_casks:
      - 'logseq'
      - 'fantastical'
      - 'google-chrome'

    mas:
      "Xcode": 497799835
      "Racompass": 1538380685
```

```bash
# File: ~/.local/share/chezmoi/run_onchange_before_install-packages.sh.tmpl
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

set -eufo pipefail

echo "Installing Homebrew packages for {{ .machine }} machine..."

brew bundle --no-lock --file=/dev/stdin <<EOF
{{ range .packages.darwin.taps -}}
tap {{ . | quote }}
{{ end -}}

# Common packages
{{ range .packages.darwin.common_brews -}}
brew {{ . | quote }}
{{ end -}}

# Machine-specific packages
{{ if eq .machine "client" -}}
{{ range .packages.darwin.client_brews -}}
brew {{ . | quote }}
{{ end -}}
{{ else if eq .machine "fanaka" -}}
{{ range .packages.darwin.fanaka_brews -}}
brew {{ . | quote }}
{{ end -}}
{{ end -}}

# Common casks
{{ range .packages.darwin.common_casks -}}
cask {{ . | quote }}
{{ end -}}

# Machine-specific casks
{{ if eq .machine "client" -}}
{{ range .packages.darwin.client_casks -}}
cask {{ . | quote }}
{{ end -}}
{{ else if eq .machine "fanaka" -}}
{{ range .packages.darwin.fanaka_casks -}}
cask {{ . | quote }}
{{ end -}}
{{ end -}}

# Mac App Store
{{ range $name, $id := .packages.darwin.mas -}}
mas {{ $name | quote }}, id: {{ $id }}
{{ end -}}
EOF
{{ end -}}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual Brewfile + cron | chezmoi `run_onchange_` scripts | 2020-2021 | Automated package management, change-triggered updates |
| Separate Brewfiles per machine | `.chezmoidata.yaml` with machine-specific overrides | 2021-2022 | Single source of truth, template-driven customization |
| `brew bundle dump` to commit | `.chezmoidata.yaml` as canonical source | 2022+ | Cleaner git history, structured data over generated files |
| Nix/Home Manager for reproducibility | Homebrew + mise for pragmatic simplicity | 2023+ | Lower complexity, faster setup, broader macOS compatibility |
| XDG non-compliance for global Brewfile | `${XDG_CONFIG_HOME}/homebrew/Brewfile` support | 2025-2026 | Standards compliance, better directory organization |

**Deprecated/outdated:**
- **Nix for macOS package management**: While powerful, adds significant complexity (flakes, nix-darwin, /nix volume). Homebrew + mise provides 95% of benefits with 20% of complexity.
- **Manual brew install loops**: Pre-dates brew bundle. Use Brewfile-based installation exclusively.
- **Dotbot for package installation**: Dotbot excellent for symlinks but lacks package management features. chezmoi + brew bundle is standard now.

## Open Questions

Things that couldn't be fully resolved:

1. **Deleted packages audit trail format**
   - What we know: brew bundle cleanup shows what's removed in output, can be captured with `tee`
   - What's unclear: No native audit trail feature in Homebrew, format is up to implementation
   - Recommendation: Use simple timestamped log format: `~/.local/state/homebrew-cleanup.log` with date headers and captured output. Consider JSON format if programmatic analysis needed.

2. **brew bundle cleanup dependency handling**
   - What we know: GitHub issue #1099 and #21350 indicate cleanup can remove dependencies of explicitly installed packages
   - What's unclear: Whether this has been fixed in recent Homebrew versions (4.x), or if workaround needed
   - Recommendation: ALWAYS run `brew bundle dump --global --force` FIRST to capture complete current state before enabling cleanup. Test cleanup without `--force` extensively before automating.

3. **VS Code extensions in .chezmoidata**
   - What we know: brew bundle supports vscode extensions, user wants Settings Sync instead
   - What's unclear: Whether to document VS Code extension syntax for future use
   - Recommendation: Skip VS Code extensions in this phase, document in comment that Settings Sync handles it. Future phase can add if needed.

4. **nix-darwin uninstaller reliability**
   - What we know: Official `nix-darwin#darwin-uninstaller` exists, manual process also documented
   - What's unclear: Whether uninstaller handles all edge cases or if manual cleanup needed
   - Recommendation: Run uninstaller first, then verify with manual steps (check for Nix Store volume, shell configs, daemon). Belt-and-suspenders approach for safety.

## Sources

### Primary (HIGH confidence)
- [/twpayne/chezmoi Context7](https://github.com/twpayne/chezmoi) - Script execution, package management patterns
- [chezmoi macOS Documentation](https://www.chezmoi.io/user-guide/machines/macos/) - brew bundle integration
- [chezmoi Install Packages Declaratively](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/) - Standard pattern with .chezmoidata
- [Homebrew Brew Bundle Documentation](https://docs.brew.sh/Brew-Bundle-and-Brewfile) - brew bundle cleanup, global Brewfile location
- [Nix 2.31.3 Uninstallation Guide](https://nix.dev/manual/nix/2.31/installation/uninstall) - Official macOS uninstall steps

### Secondary (MEDIUM confidence)
- [Homebrew brew(1) Manual](https://docs.brew.sh/Manpage) - General Homebrew operations
- [NixOS Discourse: Uninstalling Nix on macOS](https://discourse.nixos.org/t/uninstalling-nix-on-macos/15686) - Community uninstall experiences
- [GitHub Issue: brew bundle cleanup dependency handling](https://github.com/Homebrew/homebrew-bundle/issues/1099) - Known issues with cleanup

### Tertiary (LOW confidence)
- Community blog posts (2024-2026) showing real-world chezmoi + Homebrew implementations
- GitHub dotfiles repositories demonstrating patterns (justin/dotfiles, tak848/dotfiles)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Context7 documentation, official chezmoi patterns, 40k+ Homebrew stars
- Architecture: HIGH - Verified patterns from official docs, multiple real-world implementations
- Pitfalls: HIGH - Documented in GitHub issues, official warnings in documentation
- Nix removal: HIGH - Official Nix documentation, step-by-step process
- brew bundle cleanup audit: MEDIUM - No native feature, requires custom implementation

**Research date:** 2026-01-27
**Valid until:** 60 days (stable domain, chezmoi and Homebrew are mature tools with infrequent breaking changes)
