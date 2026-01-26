# Phase 3: Templating & Machine Detection - Research

**Researched:** 2026-01-26
**Domain:** chezmoi templating, cross-platform dotfiles, machine identity detection
**Confidence:** HIGH

## Summary

Chezmoi provides powerful templating capabilities through Go's `text/template` syntax extended with Sprig functions. The standard approach for machine detection combines:

1. **`.chezmoi.yaml.tmpl`** - Generates config file during `chezmoi init` with interactive prompts for machine identity and email addresses
2. **`.chezmoidata.yaml`** - Static data (package lists, tool configs) committed to repository
3. **Template conditionals** - Use `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.osRelease.id` for platform-specific logic
4. **`chezmoi execute-template`** - Test templates before applying to prevent syntax errors

The ecosystem strongly favours composing a custom `osid` variable (e.g., "darwin", "linux-ubuntu") to simplify nested conditionals. Homebrew path detection requires both OS and architecture checks (Apple Silicon vs Intel). Files should only become templates when they actually need platform/machine logic, maintaining readability for files that don't vary.

**Primary recommendation:** Start with `.chezmoi.yaml.tmpl` for machine identity prompts, use inline conditionals for simple OS/arch checks, and leverage `chezmoi execute-template` extensively during development to catch template errors early.

## Standard Stack

The established libraries/tools for chezmoi templating:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | 2.x | Dotfile manager with templating | Official tool, actively maintained, large community |
| Go text/template | stdlib | Template syntax | Native to chezmoi, well-documented |
| Sprig | v3 | Template function library | Included with chezmoi, provides 100+ utility functions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| YAML | - | Data format for .chezmoidata | Simple hierarchical data (package lists) |
| TOML | - | Config format for .chezmoi.toml | Configuration with nested sections |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Interactive prompts | Environment variables | Prompts better UX for initial setup, env vars better for CI |
| `.chezmoidata.yaml` | Config data section | .chezmoidata better for large datasets, config better for machine-specific values |
| Inline conditionals | Separate files per OS | Inline conditionals reduce file duplication for minor differences |

**Installation:**
```bash
# chezmoi already installed in Phase 2
# No additional tools needed for templating
```

## Architecture Patterns

### Recommended Data Organization Structure
```
~/.local/share/chezmoi/
├── .chezmoi.yaml.tmpl          # Generates config with prompts (machine type, emails)
├── .chezmoidata.yaml           # Static data: package lists, shared config
├── dot_gitconfig.tmpl          # Templated files with .tmpl extension
├── dot_zshrc                   # Non-templated files (no extension)
└── .chezmoitemplates/          # Reusable template fragments
    └── homebrew-path           # Shared logic for Homebrew path detection
```

### Pattern 1: Machine Identity via Interactive Prompts
**What:** Prompt user during `chezmoi init` to set machine type and email addresses
**When to use:** Initial setup on a new machine
**Example:**
```yaml
# .chezmoi.yaml.tmpl
{{- $interactive := stdinIsATTY -}}

{{- $machineType := "personal" -}}
{{- if $interactive -}}
{{-   $machineType = promptString "Machine type (client/personal/server)" "personal" -}}
{{- end -}}

{{- $personalEmail := "user@example.com" -}}
{{- if $interactive -}}
{{-   $personalEmail = promptString "Personal email address" -}}
{{- end -}}

{{- $workEmail := "" -}}
{{- if eq $machineType "client" -}}
{{-   if $interactive -}}
{{-     $workEmail = promptString "Work email address" -}}
{{-   end -}}
{{- end -}}

data:
  machine_type: {{ $machineType | quote }}
  personal_email: {{ $personalEmail | quote }}
{{- if eq $machineType "client" }}
  work_email: {{ $workEmail | quote }}
{{- end }}
```
**Source:** [Official chezmoi documentation - .chezmoi.format.tmpl](https://www.chezmoi.io/reference/special-files/chezmoi-format-tmpl/)

### Pattern 2: Simplified OS Detection with Custom Variable
**What:** Create composite `osid` variable to avoid nested conditionals
**When to use:** When supporting multiple Linux distributions
**Example:**
```yaml
# .chezmoi.yaml.tmpl (after prompts)
{{- $osid := .chezmoi.os -}}
{{- if hasKey .chezmoi "osRelease" -}}
{{-   if hasKey .chezmoi.osRelease "id" -}}
{{-     $osid = printf "%s-%s" .chezmoi.os .chezmoi.osRelease.id -}}
{{-   end -}}
{{- end -}}

data:
  osid: {{ $osid | quote }}
  # ... machine_type, emails, etc.
```

**Usage in templates:**
```bash
# dot_zshrc.tmpl
{{ if eq .osid "darwin" -}}
# macOS-specific configuration
{{- else if eq .osid "linux-ubuntu" -}}
# Ubuntu-specific configuration
{{- else if eq .osid "linux-fedora" -}}
# Fedora-specific configuration
{{- end }}
```
**Source:** [Official chezmoi Linux documentation](https://www.chezmoi.io/user-guide/machines/linux/)

### Pattern 3: Homebrew Path Detection
**What:** Detect correct Homebrew installation path based on OS and architecture
**When to use:** Shell initialization files that need to source Homebrew
**Example:**
```bash
# dot_zshrc.tmpl or .chezmoitemplates/homebrew-path
{{- if eq .chezmoi.os "darwin" }}
# macOS: Different paths for Apple Silicon vs Intel
{{-   if eq .chezmoi.arch "arm64" }}
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
{{-   else }}
if [ -f "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
{{-   end }}
{{- else if eq .chezmoi.os "linux" }}
# Linux: Linuxbrew standard path
if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
{{- end }}
```
**Source:** [Community blog - Taking Control of My Dotfiles with chezmoi (2026)](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/)

### Pattern 4: Git Config Email Based on Machine Type
**What:** Set git user.email conditionally based on machine type
**When to use:** Work laptops need work email, personal machines need personal email
**Example:**
```gitconfig
# dot_gitconfig.tmpl
# Managed by chezmoi - do not edit directly

[user]
  name = Your Name
{{- if eq .machine_type "client" }}
  email = {{ .work_email | quote }}
{{- else }}
  email = {{ .personal_email | quote }}
{{- end }}

# ... rest of git config
```
**Source:** [Community article - Managing machine-specific gitconfig](https://jpcaparas.medium.com/dotfiles-managing-machine-specific-gitconfig-with-chezmoi-user-defined-template-variables-400071f663c0)

### Pattern 5: Package Lists in .chezmoidata
**What:** Store platform-specific package declarations in structured YAML
**When to use:** Phase 4 (Package Management), but structure decided now
**Example:**
```yaml
# .chezmoidata.yaml
packages:
  darwin:
    brews:
      - git
      - gh
      - mise
    casks:
      - visual-studio-code
  linux:
    apt:  # For Ubuntu/Debian
      - git
      - build-essential
    dnf:  # For Fedora
      - git
      - gcc
```
**Source:** [Official chezmoi - Install packages declaratively](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/)

### Anti-Patterns to Avoid
- **Over-templating:** Don't add `.tmpl` to files that don't vary across platforms - reduces readability
- **Deeply nested conditionals:** Use the `osid` pattern instead of `if eq .chezmoi.os "linux" | if eq .chezmoi.osRelease.id "ubuntu"`
- **Forgetting whitespace control:** Use `{{-` and `-}}` to prevent unwanted blank lines, especially critical for shebangs
- **Hardcoded shebangs in templates:** Use `{{ lookPath "bash" }}` instead of `#!/bin/bash` for Nix/Termux compatibility
- **Testing templates in production:** Always use `chezmoi execute-template` before `chezmoi apply`

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Machine identity persistence | Custom config files | `.chezmoi.yaml.tmpl` with prompts | chezmoi handles config generation, caching, and re-prompting logic |
| OS detection | Manual `uname` parsing | `.chezmoi.os`, `.chezmoi.arch`, `.chezmoi.osRelease` | Handles edge cases like Rosetta 2, WSL, missing os-release files |
| Template testing | Shell script validation | `chezmoi execute-template` | Catches syntax errors, type mismatches, missing variables before deployment |
| Cross-platform path handling | Platform-specific symlinks | Template conditionals | Single source of truth, git tracks actual differences |
| Package list management | Separate per-OS Brewfiles | `.chezmoidata.yaml` with nested structure | Enables cross-platform package declarations, reusable in scripts |

**Key insight:** Chezmoi's template system is purpose-built for dotfile edge cases. The `.chezmoi` namespace provides battle-tested detection logic covering architectures, distributions, and environments that custom scripts would need months to handle correctly.

## Common Pitfalls

### Pitfall 1: Template Syntax Errors Break Shell
**What goes wrong:** Template syntax error in `.zshrc.tmpl` causes shell to fail on startup, potentially locking user out
**Why it happens:** Templates are applied directly to home directory; syntax errors create invalid shell files
**How to avoid:**
- ALWAYS test templates with `chezmoi execute-template < dot_zshrc.tmpl` before applying
- Use `chezmoi diff` to preview changes before `chezmoi apply`
- Keep emergency recovery script from Phase 1 accessible
**Warning signs:** chezmoi errors mentioning "template execution failed", "unexpected <EOF>", "function not defined"

### Pitfall 2: .chezmoidata vs .chezmoi Config Confusion
**What goes wrong:** Putting machine-specific data in `.chezmoidata.yaml` instead of `.chezmoi.yaml.tmpl`
**Why it happens:** Both files provide template data, but `.chezmoidata` cannot be templated and is committed to git
**How to avoid:**
- `.chezmoidata.yaml`: Static data committed to repository (package lists, shared tool configs)
- `.chezmoi.yaml.tmpl`: Generates per-machine config with prompts (machine type, email addresses)
- Rule of thumb: "Would this value differ on my work vs personal laptop?" → `.chezmoi.yaml.tmpl`
**Warning signs:** Git wanting to commit machine-specific values, different machines overwriting each other's data

### Pitfall 3: Whitespace Disasters in Shell Scripts
**What goes wrong:** Template conditionals leave blank lines, breaking shebangs or causing unexpected script behavior
**Why it happens:** Template blocks like `{{ if }}` consume lines but leave the newline character
**How to avoid:**
- Use `{{-` (strip left) and `-}}` (strip right) consistently
- Critical for shebangs: `{{- if eq .chezmoi.os "linux" -}}` (no newline before `#!/bin/bash`)
- Test with `cat -A` to visualize invisible whitespace
**Warning signs:** "exec format error" on scripts, unexpected blank lines in `git diff`

### Pitfall 4: Architecture Misdetection on Apple Silicon
**What goes wrong:** `.chezmoi.arch` returns "x86_64" on Apple Silicon when running under Rosetta 2
**Why it happens:** If chezmoi binary is x86_64, it reports emulated architecture not native hardware
**How to avoid:**
- Install native ARM64 chezmoi binary: `brew install chezmoi` (Homebrew handles arch)
- Verify with: `chezmoi execute-template "{{ .chezmoi.arch }}"` (should be "arm64")
- For Homebrew paths, check both arch AND existence: `{{ if eq .chezmoi.arch "arm64" }}{{ if lookPath "/opt/homebrew/bin/brew" }}`
**Warning signs:** Homebrew not found despite being installed, performance issues from Rosetta translation

### Pitfall 5: Negative Logic Confusion in .chezmoiignore
**What goes wrong:** Using `eq` instead of `ne` in `.chezmoiignore` causes files to be ignored on wrong machines
**Why it happens:** chezmoi applies everything by default; `.chezmoiignore` specifies what to EXCLUDE
**How to avoid:**
- Think "ignore X UNLESS condition": `{{ if ne .machine_type "client" }}.work{{ end }}`
- NOT "include X IF condition": `{{ if eq .machine_type "client" }}.work{{ end }}` ← WRONG
- Test with `chezmoi ignored` to verify which files are excluded
**Warning signs:** Work configs appearing on personal machines, personal configs missing on work machines

### Pitfall 6: Forgetting to Test on Linux Before Phase 5
**What goes wrong:** Templates work on macOS but break on Linux due to untested conditionals
**Why it happens:** Primary development on macOS, Linux testing deferred until "later"
**How to avoid:**
- Test EVERY templated file on Linux VM (from Phase 1) before marking phase complete
- Use Ubuntu container: `docker exec -it dotfiles-test zsh` to verify shell templates
- Document Linux-specific differences as you discover them
**Warning signs:** Phase 5 blocked by broken shell initialization, time pressure to rush fixes

## Code Examples

Verified patterns from official sources:

### Testing a Template Before Applying
```bash
# Test inline template expression
chezmoi execute-template '{{ .chezmoi.os }}/{{ .chezmoi.arch }}'
# Output: darwin/arm64

# Test entire template file
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl

# Test .chezmoi.yaml.tmpl with custom prompt values
chezmoi execute-template --init \
  --promptString "Machine type=client" \
  --promptString "Work email=user@company.com" \
  < ~/.local/share/chezmoi/.chezmoi.yaml.tmpl

# Preview what would be applied
chezmoi diff

# Apply single file for testing
chezmoi apply ~/.gitconfig
```
**Source:** [Official chezmoi - Templating guide](https://www.chezmoi.io/user-guide/templating/)

### Converting Existing File to Template
```bash
# Method 1: Add template attribute to existing managed file
chezmoi chattr +template ~/.gitconfig

# Method 2: Manually rename in source directory
cd ~/.local/share/chezmoi
mv dot_gitconfig dot_gitconfig.tmpl

# Method 3: Add new file as template
chezmoi add --template ~/.zshrc

# Edit template in $EDITOR with syntax highlighting
chezmoi edit ~/.gitconfig
```
**Source:** [Official chezmoi - Templating guide](https://www.chezmoi.io/user-guide/templating/)

### Reusable Template Fragment
```bash
# .chezmoitemplates/header
# Managed by chezmoi - do not edit directly
# Last generated: {{ now | date "2006-01-02 15:04:05" }}
# Machine: {{ .chezmoi.hostname }} ({{ .osid }})

# dot_gitconfig.tmpl
{{- template "header" . }}

[user]
  name = Your Name
  email = {{ if eq .machine_type "client" }}{{ .work_email }}{{ else }}{{ .personal_email }}{{ end }}
```
**Source:** [Official chezmoi - Templating guide](https://www.chezmoi.io/user-guide/templating/)

### Safe Error Handling with HasKey
```bash
# Check if variable exists before using it
{{ if hasKey . "work_email" -}}
[user]
  work_email = {{ .work_email | quote }}
{{- else -}}
# Work email not configured
{{- end }}

# Provide fallback default
{{ $email := "default@example.com" -}}
{{ if hasKey . "personal_email" -}}
{{   $email = .personal_email -}}
{{ end -}}
email = {{ $email | quote }}
```
**Source:** [Official chezmoi - Template functions](https://www.chezmoi.io/reference/templates/functions/)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate dotfile repos per OS | Single repo with templates | chezmoi 1.0+ (2019) | Eliminates duplication, single source of truth |
| `hostname` checks | `.chezmoi.hostname` | chezmoi 1.0+ | Stable hostnames on macOS (not network-dependent) |
| Manual config files | `.chezmoi.yaml.tmpl` with prompts | chezmoi 1.8+ (2020) | Interactive setup, no manual file editing |
| Nested `if` for distros | Custom `osid` variable pattern | Community best practice (2021+) | Readable templates, easier maintenance |
| Hardcoded shebangs | `lookPath` function | chezmoi 2.0+ (2021) | Nix/Termux compatibility |
| String-based arch checks | `.chezmoi.arch` variable | chezmoi 1.0+ | Apple Silicon support, Rosetta detection |

**Deprecated/outdated:**
- **`{{ .chezmoi.osRelease.idLike }}`**: Removed in chezmoi 2.x - use `.chezmoi.osRelease.id` and handle distro families manually
- **`{{ .chezmoi.group }}`**: Removed - use `stat` function to check file ownership
- **Separate branch per machine**: Anti-pattern - use templates in single branch instead

## Open Questions

Things that couldn't be fully resolved:

1. **Distro Family Detection**
   - What we know: `.chezmoi.osRelease.id` gives specific distro (ubuntu, fedora, arch)
   - What's unclear: Best way to group into families (debian-like, redhat-like) for package management
   - Recommendation: Create explicit mapping in `.chezmoi.yaml.tmpl` based on `.chezmoi.osRelease.id`, document known distros

2. **mise Tool Config Templating Needs**
   - What we know: mise uses `~/.config/mise/config.toml` for global settings
   - What's unclear: Which mise settings actually differ between macOS/Linux (Phase 5 will reveal)
   - Recommendation: Don't template mise config preemptively - audit in Phase 5, add templating if needed

3. **Server Machine Type Use Cases**
   - What we know: User defined three types (client, personal, server) in Phase discussion
   - What's unclear: What config differences "server" machines need vs "personal"
   - Recommendation: Treat "server" same as "personal" for now (minimal configs, no GUI tools), differentiate when actual server setup happens

## Sources

### Primary (HIGH confidence)
- [chezmoi.io - Templating user guide](https://www.chezmoi.io/user-guide/templating/)
- [chezmoi.io - Managing machine-to-machine differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [chezmoi.io - .chezmoidata format reference](https://www.chezmoi.io/reference/special-files/chezmoidata-format/)
- [chezmoi.io - .chezmoi.format.tmpl reference](https://www.chezmoi.io/reference/special-files/chezmoi-format-tmpl/)
- [chezmoi.io - Linux machines guide](https://www.chezmoi.io/user-guide/machines/linux/)
- [chezmoi.io - macOS machines guide](https://www.chezmoi.io/user-guide/machines/macos/)
- [chezmoi.io - Template functions reference](https://www.chezmoi.io/reference/templates/functions/)
- [chezmoi.io - Troubleshooting FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/troubleshooting/)
- [chezmoi.io - Install packages declaratively](https://www.chezmoi.io/user-guide/advanced/install-packages-declaratively/)

### Secondary (MEDIUM confidence)
- [chezmoi/dotfiles - .chezmoi.yaml.tmpl example (GitHub)](https://github.com/chezmoi/dotfiles/blob/master/.chezmoi.yaml.tmpl) - Official example repository
- [Taking Control of My Dotfiles with chezmoi (2026 blog post)](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/) - Recent community implementation
- [Managing machine-specific gitconfig (Medium article)](https://jpcaparas.medium.com/dotfiles-managing-machine-specific-gitconfig-with-chezmoi-user-defined-template-variables-400071f663c0) - Practical git email templating example

### Tertiary (LOW confidence)
- Various GitHub dotfiles repositories - Cross-referenced for common patterns, but not individually authoritative

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - chezmoi is the official tool, Go templates are native, Sprig is included
- Architecture patterns: HIGH - All patterns from official documentation or verified community examples
- Pitfalls: MEDIUM-HIGH - Most from official troubleshooting guide, some from community reports

**Research limitations:**
- mise config templating needs unknown until Phase 5 implementation
- Sheldon config templating needs not yet investigated (likely minimal - plugin list probably doesn't vary by OS)
- Specific Linux distro coverage limited to Ubuntu/Debian and Fedora examples in docs

**Research date:** 2026-01-26
**Valid until:** ~60 days (chezmoi stable, infrequent breaking changes)
