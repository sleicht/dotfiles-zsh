# Phase 8: Basic Configs & CLI Tools - Research

**Researched:** 2026-02-09
**Domain:** Static config file migration to chezmoi (dotfiles, CLI tool configs, window manager, shell abbreviations)
**Confidence:** HIGH

## Summary

Phase 8 migrates 13 low-risk static configuration files from Dotbot symlink management to chezmoi's file deployment system. This includes basic dotfiles (hushlogin, inputrc, editorconfig, nanorc), CLI tool configs (bat, lsd, btop, oh-my-posh), a macOS-only window manager (aerospace), keyboard remapping (karabiner), database tool configs (psqlrc, sqliterc), and zsh abbreviations. Research confirms that chezmoi's `add --follow` command is the standard migration path from symlink-based systems, file naming follows the `dot_` prefix convention for hidden files and `private_dot_config/` for .config directory contents, and OS-conditional deployment uses `.chezmoiignore` template syntax already established in Phase 7. All configs are static (no secrets requiring Bitwarden templating), most are portable across machines without modification, and two have minor portability concerns (nanorc has hardcoded Homebrew path, aerospace has machine-specific app launch list). The migration follows proven v1.0.0 patterns: add files with `chezmoi add --follow`, update .chezmoiignore to remove phase ignore blocks, verify with `chezmoi diff`, apply with `chezmoi apply`, and confirm with verification checks.

**Key validated patterns:**
- `chezmoi add --follow` replaces symlinks with real file content (standard migration from Dotbot)
- File naming: `dot_hushlogin` for ~/.hushlogin, `private_dot_config/bat/config` for ~/.config/bat/config
- OS-conditional deployment via .chezmoiignore template blocks (aerospace macOS-only)
- Static configs (no templating needed) migrate as-is unless portability issues discovered
- Verification framework from Phase 7 provides reusable check-exists/check-parsable helpers

**Primary recommendation:** Use `chezmoi add --follow` for all 13 configs, remove Phase 8 ignore blocks from .chezmoiignore, create Phase 8 verification check file that confirms file existence + app parsability (bat --config-file, psql -c '\set', sqlite3 .help, aerospace --check, btop --help), and commit all migrations in a single batch per Phase 7 pattern.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | 2.69.3 | Dotfile deployment (replaces Dotbot symlinks) | Already installed (v1.0.0), official migration path |
| bat | latest | Syntax-highlighted cat replacement | Already installed, user-configured in .config/bat/config |
| lsd | latest | Modern ls replacement | Already installed, user-configured in .config/lsd/config.yaml |
| btop | latest | System monitor | Already installed, user-configured in .config/btop/btop.conf |
| oh-my-posh | latest | Shell prompt theming | Already installed, user-configured in .config/oh-my-posh.omp.json |
| aerospace | latest | macOS tiling window manager | macOS-only, user-configured in .config/aerospace/aerospace.toml |
| karabiner-elements | latest | Keyboard remapping (macOS) | macOS-only, manages own config at .config/karabiner/karabiner.json |
| zsh-abbr | latest | Fish-like abbreviations for zsh | Already installed, user abbreviations in .config/zsh-abbr/user-abbreviations |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| psql | latest | PostgreSQL CLI | Config at ~/.psqlrc for prompt/history customization |
| sqlite3 | latest | SQLite CLI | Config at ~/.sqliterc for output formatting |
| readline | latest | Input library | Config at ~/.inputrc for shell input behavior (tab completion, etc.) |
| nano | latest | Simple text editor | Config at ~/.nanorc for editor preferences |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| chezmoi add --follow | Manual file copy | Manual copy error-prone, --follow is standard migration path |
| Static configs | Templated configs | Templating adds complexity where not needed (these configs are portable) |
| Single-batch migration | Incremental per-config | Single batch follows v1.0.0 phase pattern, simpler verification |
| Karabiner copy | Karabiner symlink | Karabiner overwrites symlinks, must use real file per official docs |
| OS conditionals in .chezmoiignore | Template modifiers on files | .chezmoiignore already established pattern (Phase 7) |

**Installation:**
```bash
# All tools already installed via Homebrew (v1.0.0 or earlier):
# - chezmoi (Phase 2)
# - bat, lsd, btop, oh-my-posh, aerospace, karabiner-elements (pre-existing)
# - postgresql, sqlite (pre-existing)
# - nano (system default on macOS)

# No new installations required for Phase 8
```

## Architecture Patterns

### Recommended Migration Structure

```
~/.local/share/chezmoi/          # chezmoi source directory
├── dot_hushlogin                # Basic dotfiles (root level)
├── dot_inputrc
├── dot_editorconfig
├── dot_nanorc
├── dot_psqlrc
├── dot_sqliterc
├── private_dot_config/          # .config directory contents
│   ├── bat/
│   │   └── config               # bat configuration
│   ├── lsd/
│   │   └── config.yaml          # lsd configuration
│   ├── btop/
│   │   └── btop.conf            # btop configuration (233 lines)
│   ├── aerospace/
│   │   └── aerospace.toml       # macOS tiling window manager
│   ├── karabiner/
│   │   └── karabiner.json       # Keyboard remapping config
│   ├── zsh-abbr/
│   │   └── user-abbreviations   # Shell abbreviations
│   └── oh-my-posh.omp.json      # Prompt theme (root of .config)
└── .chezmoiignore               # Remove Phase 8 ignore blocks
```

### Pattern 1: Migrate Symlinked Config to chezmoi

**What:** Replace Dotbot symlinks with chezmoi-managed real files
**When to use:** All Phase 8 configs (currently Dotbot-symlinked)
**Example:**
```bash
# Source: https://www.chezmoi.io/migrating-from-another-dotfile-manager
# Current state: ~/.hushlogin -> ~/Projects/dotfiles-zsh/.config/hushlogin (symlink)
# Desired state: ~/.hushlogin (real file, managed by chezmoi)

# Add to chezmoi (--follow resolves symlink to actual content)
chezmoi add --follow ~/.hushlogin

# Verify in chezmoi source
ls -l ~/.local/share/chezmoi/dot_hushlogin

# Apply (replaces symlink with real file)
chezmoi apply ~/.hushlogin

# Verify (should be real file now, not symlink)
ls -l ~/.hushlogin
```

### Pattern 2: Migrate .config Directory Files

**What:** Add nested .config files to chezmoi with proper naming
**When to use:** All .config/* files (bat, lsd, btop, aerospace, karabiner, zsh-abbr, oh-my-posh)
**Example:**
```bash
# Source: https://context7.com/twpayne/chezmoi/llms.txt
# Current: ~/.config/bat/config -> ~/Projects/dotfiles-zsh/.config/bat/config (symlink)
# Target: ~/.local/share/chezmoi/private_dot_config/bat/config

# Add recursively (preserves directory structure)
chezmoi add --follow ~/.config/bat/config

# Or add entire tool config directory at once
chezmoi add --follow --recursive ~/.config/btop

# chezmoi automatically creates private_dot_config/ directory structure
# Files appear as: private_dot_config/bat/config, private_dot_config/btop/btop.conf
```

### Pattern 3: OS-Conditional Deployment

**What:** Deploy configs only on matching OS (aerospace macOS-only)
**When to use:** Platform-specific configs (aerospace, karabiner)
**Example:**
```chezmoiignore
# Source: https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences
# Current .chezmoiignore already has (Phase 7):
{{- if ne .chezmoi.os "darwin" }}
# macOS-only configs — ignore on Linux
.config/aerospace
.config/aerospace/**
.finicky.js
{{- end }}

# Phase 8 migration: Remove aerospace from Phase 8 pending block in .chezmoiignore
# OS conditional block remains (aerospace deploys on macOS, skipped on Linux)
```

### Pattern 4: Verification After Migration

**What:** Confirm configs deployed correctly and apps can parse them
**When to use:** After every chezmoi apply in Phase 8
**Example:**
```bash
# Source: Phase 7 verification framework
# Create scripts/verify-checks/08-basic-configs.sh:

#!/usr/bin/env bash
source "$(dirname "$0")/../verify-lib/check-exists.sh"
source "$(dirname "$0")/../verify-lib/check-parsable.sh"

# Basic dotfiles - existence check
check_exists "$HOME/.hushlogin" "hushlogin"
check_exists "$HOME/.inputrc" "inputrc"
check_exists "$HOME/.editorconfig" "editorconfig"
check_exists "$HOME/.nanorc" "nanorc"

# CLI tools - parsability check
check_parsable "bat" "bat --config-file=$HOME/.config/bat/config --list-themes" "bat config"
check_parsable "lsd" "lsd --help" "lsd config"
check_parsable "btop" "btop --help" "btop config"
check_parsable "psql" "psql -c '\\set'" "psqlrc"
check_parsable "sqlite3" "sqlite3 :memory: '.help'" "sqliterc"

if [[ "$OSTYPE" == "darwin"* ]]; then
  check_parsable "aerospace" "aerospace --check" "aerospace config"
fi
```

### Anti-Patterns to Avoid

- **Symlink preservation:** Don't `chezmoi add` the symlink itself — always use `--follow` flag to capture actual file content
- **Manual file copying:** Don't `cp` files to chezmoi source — use `chezmoi add` to maintain proper metadata
- **Templating without cause:** Don't add `.tmpl` suffix to static configs — only template when needed (secrets, machine-specific values)
- **Karabiner symlink:** Don't symlink karabiner.json — Karabiner-Elements overwrites symlinks instead of editing them
- **Partial .chezmoiignore updates:** Don't leave Phase 8 configs in ignore blocks after migration — remove them so chezmoi tracks changes

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symlink migration | Manual cp + git add | `chezmoi add --follow` | Handles symlink resolution, creates correct file names, preserves metadata |
| Config validation | Custom parsers per tool | Verification framework + app --help/--check | Apps validate their own configs, framework provides structure |
| OS conditionals | Duplicate configs per OS | .chezmoiignore template syntax | Single source, chezmoi handles OS detection, already established pattern |
| File deployment | rsync/cp scripts | `chezmoi apply` | Atomic updates, diff preview, rollback via git, proper permissions |
| Config portability | sed/awk path replacement | Manual review + optional templates | Most configs portable as-is, templating adds complexity |

**Key insight:** chezmoi's migration path from symlink-based dotfile managers is well-established (--follow flag, official migration guide), and the verification framework from Phase 7 provides reusable building blocks for parsability checks. Don't reinvent migration workflows or validation logic — use what's already proven.

## Common Pitfalls

### Pitfall 1: Forgetting --follow Flag

**What goes wrong:** Running `chezmoi add ~/.hushlogin` when ~/.hushlogin is a symlink adds the symlink itself to chezmoi, not the file content. On `chezmoi apply`, the symlink is recreated, still pointing to the old Dotbot location.

**Why it happens:** chezmoi's default behavior is to preserve symlinks (useful for some workflows). Dotbot migration requires the opposite — replace symlinks with real files.

**How to avoid:** Always use `chezmoi add --follow` when migrating from Dotbot. The --follow flag tells chezmoi to resolve the symlink and add the target file's content.

**Warning signs:** After chezmoi apply, `ls -l ~/.hushlogin` still shows symlink arrow (→). Should be a regular file (-rw-r--r--).

### Pitfall 2: Karabiner-Elements Config Symlink Trap

**What goes wrong:** Symlinking karabiner.json causes Karabiner-Elements to overwrite the symlink with a regular file when saving settings via GUI, breaking the dotfile link.

**Why it happens:** Karabiner-Elements uses an atomic write pattern (write to temp, move to karabiner.json) which can't preserve symlinks. This is documented in official Karabiner GitHub issues.

**How to avoid:** Always use `chezmoi add --follow` for karabiner.json. Deploy as a real file managed by chezmoi. Accept that GUI edits will modify the target file, which chezmoi will detect as changes (chezmoi diff). This is expected behavior — manually commit GUI changes back to chezmoi source.

**Warning signs:** After editing keyboard settings in Karabiner-Elements GUI, `ls -l ~/.config/karabiner/karabiner.json` shows regular file instead of symlink, and dotfile manager no longer tracks changes.

### Pitfall 3: Incomplete .chezmoiignore Cleanup

**What goes wrong:** After migrating Phase 8 configs to chezmoi, forgetting to remove them from the "Pending Migration - Phase 8" block in .chezmoiignore means chezmoi still ignores them. `chezmoi status` won't show changes, `chezmoi apply` won't deploy them.

**Why it happens:** .chezmoiignore was set up in Phase 7 to PREVENT chezmoi from touching Phase 8-12 configs until their migration phase. Once migrated, those ignore patterns must be removed.

**How to avoid:** After adding all Phase 8 configs to chezmoi source, edit ~/.local/share/chezmoi/.chezmoiignore and DELETE the entire "Pending Migration - Phase 8" section (lines listing .hushlogin, .inputrc, .config/bat/, etc.). Keep the file header and other sections intact.

**Warning signs:** `chezmoi managed | grep hushlogin` returns nothing even after `chezmoi add --follow ~/.hushlogin`. Or `chezmoi diff` shows no changes despite editing a migrated config.

### Pitfall 4: Hardcoded Paths in Configs

**What goes wrong:** The nanorc file contains `include /opt/homebrew/opt/nano/share/nano/*.nanorc` which assumes Homebrew installed at /opt/homebrew (Apple Silicon Macs). On Intel Macs, Homebrew is at /usr/local, causing nano to fail finding syntax files.

**Why it happens:** Config was created on Apple Silicon Mac without considering cross-architecture portability.

**How to avoid:** Review all configs for hardcoded paths before migration. For nanorc, options: (1) use chezmoi template with {{ .chezmoi.arch }} conditional, (2) use `$(brew --prefix)` variable expansion (nano doesn't support this), or (3) accept single-architecture setup if you only use Apple Silicon Macs. Decision: Document in verification that nanorc requires Apple Silicon (or update to template if multi-arch needed).

**Warning signs:** nano command fails with "Error in /Users/you/.nanorc on line 23: File 'include /opt/homebrew/opt/nano/share/nano/*.nanorc' not found". Running `which nano` and `brew --prefix` reveals path mismatch.

### Pitfall 5: Aerospace Machine-Specific App List

**What goes wrong:** The aerospace.toml after-startup-command launches specific apps ("Google Chrome", "Zen", "Spark Desktop", "Threema", "WhatsApp", etc.). On a new machine or work vs. personal setup, these apps may not exist, causing aerospace startup errors.

**Why it happens:** Current config is personalized for one machine's app collection. Not inherently wrong, but reduces portability.

**How to avoid:** Decision: Accept machine-specific aerospace config as-is (it's a window manager, personalization expected). Alternative: Use chezmoi template to conditionally launch apps based on hostname or custom .chezmoi.toml data variable. For Phase 8, migrate as-is and document in verification that aerospace config is machine-specific (not a bug).

**Warning signs:** On fresh machine setup, aerospace logs show "Application 'Threema' not found" errors. Window manager still functions, but warnings clutter logs.

## Code Examples

Verified patterns from official sources:

### Migrate All Phase 8 Configs at Once

```bash
# Source: https://www.chezmoi.io/migrating-from-another-dotfile-manager
# Migrate basic dotfiles (currently symlinked via Dotbot)
chezmoi add --follow ~/.hushlogin
chezmoi add --follow ~/.inputrc
chezmoi add --follow ~/.editorconfig
chezmoi add --follow ~/.nanorc
chezmoi add --follow ~/.psqlrc
chezmoi add --follow ~/.sqliterc

# Migrate .config directory files
chezmoi add --follow ~/.config/bat/config
chezmoi add --follow ~/.config/lsd/config.yaml
chezmoi add --follow --recursive ~/.config/btop    # Entire dir (btop.conf inside)
chezmoi add --follow ~/.config/oh-my-posh.omp.json
chezmoi add --follow --recursive ~/.config/aerospace
chezmoi add --follow --recursive ~/.config/karabiner
chezmoi add --follow --recursive ~/.config/zsh-abbr

# Verify all files added to chezmoi source
ls -la ~/.local/share/chezmoi/ | grep dot_
ls -la ~/.local/share/chezmoi/private_dot_config/
```

### Update .chezmoiignore to Remove Phase 8 Blocks

```bash
# Source: Phase 7 .chezmoiignore setup pattern
# Edit the ignore file
chezmoi edit ~/.chezmoiignore

# DELETE these lines from "Pending Migration - Phase 8" section:
# .hushlogin
# .inputrc
# .nanorc
# .editorconfig (home-level)
# .config/bat/
# .config/bat/**
# .config/lsd/
# .config/lsd/**
# .config/btop/
# .config/btop/**
# .config/oh-my-posh.omp.json
# .psqlrc
# .sqliterc
# .config/zsh-abbr/
# .config/zsh-abbr/**
# .config/karabiner/
# .config/karabiner/**

# KEEP the OS-conditional block in Section 5 (aerospace remains there):
# {{- if ne .chezmoi.os "darwin" }}
# .config/aerospace
# .config/aerospace/**
# {{- end }}

# Verify ignore file parses correctly
chezmoi execute-template < ~/.local/share/chezmoi/.chezmoiignore

# Verify Phase 8 configs now managed
chezmoi managed | grep -E '(hushlogin|inputrc|bat|lsd|btop|psqlrc|sqliterc|zsh-abbr|karabiner|oh-my-posh)'
```

### Preview and Apply Phase 8 Migration

```bash
# Source: https://context7.com/twpayne/chezmoi/llms.txt
# Always diff before apply (Phase 7 workflow requirement)
chezmoi diff

# Expected output: Symlinks -> regular files for all 13 configs
# Example:
# -/Users/you/.hushlogin (symlink to ~/Projects/dotfiles-zsh/.config/hushlogin)
# +/Users/you/.hushlogin (file)
# + # The mere presence of this file in the home directory...

# Apply all changes
chezmoi apply

# Verify files are now real files, not symlinks
ls -l ~/.hushlogin ~/.inputrc ~/.editorconfig ~/.nanorc ~/.psqlrc ~/.sqliterc
ls -l ~/.config/bat/config ~/.config/lsd/config.yaml ~/.config/btop/btop.conf
ls -l ~/.config/oh-my-posh.omp.json ~/.config/zsh-abbr/user-abbreviations
ls -l ~/.config/karabiner/karabiner.json ~/.config/aerospace/aerospace.toml

# All should show regular files (-rw-r--r--), no symlink arrows (->)
```

### Verify Configs Load Correctly

```bash
# Source: Phase 7 verification framework pattern
# Run the Phase 8 verification check
./scripts/verify-configs.sh --phase 08

# Expected output:
# ✓ File exists: /Users/you/.hushlogin
# ✓ File exists: /Users/you/.inputrc
# ✓ Config parsable: bat (bat --config-file=... --list-themes)
# ✓ Config parsable: btop (btop --help)
# ✓ Config parsable: psql (psql -c '\set')
# ✓ Config parsable: sqlite3 (sqlite3 :memory: '.help')
# ✓ Config parsable: aerospace (aerospace --check)  [macOS only]
# All checks passed (13/13)

# Manual functional verification
bat --list-themes | grep gruvbox-dark  # Should show selected theme
lsd --help                             # Should run without error
btop --version                         # Should show version
psql -c '\set' 2>&1 | grep PROMPT1     # Should show custom prompt var
sqlite3 :memory: '.help' | grep headers # Should show .headers on
zsh -c 'abbr' | grep '^l='             # Should show lsd abbreviation
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Dotbot symlinks | chezmoi real files | Phase 2 (v1.0.0) | Shell configs migrated, Phase 8 finishes basic dotfiles |
| Zgenom plugin manager | Sheldon plugin manager | Phase 5 (v1.0.0) | Shell plugins migrated, Phase 8 handles zsh-abbr data |
| Manual config copying | `chezmoi add --follow` | chezmoi adoption | Standard migration path, replaces rsync/cp workflows |
| Symlink-based dotfiles | Template-driven deployment | Phase 2-8 (v1.0-v1.1) | Supports cross-platform, secrets, machine-specific configs |
| Global .chezmoiignore | Phase-based ignore blocks | Phase 7 (v1.1) | Prevents accidental migration, removed per-phase |

**Deprecated/outdated:**
- **Dotbot symlinks for Phase 8 configs**: Symlinks will be removed in Phase 12 after verification. chezmoi now manages these files.
- **Zgenom directory**: Phase 12 cleanup. Sheldon replaced zgenom in Phase 5, but zgenom directory remains symlinked. Out of Phase 8 scope.
- **.editorconfig at repo root**: REPO .editorconfig remains (for editing dotfiles repo itself). HOME .editorconfig is separate (Phase 8 scope).

## Open Questions

1. **Nanorc Homebrew Path Portability**
   - What we know: Current config has `include /opt/homebrew/...` (Apple Silicon path)
   - What's unclear: Do we need Intel Mac support (/usr/local) or Linux support (different nano paths)?
   - Recommendation: Migrate as-is for Phase 8. Document in verification notes that nanorc assumes Apple Silicon Homebrew. If Intel/Linux support needed later, convert to template with arch conditionals.

2. **Aerospace Machine-Specific Apps**
   - What we know: after-startup-command launches 12 specific apps (Chrome, Zen, Threema, etc.)
   - What's unclear: Should we template this for work vs. personal machines, or accept single-config?
   - Recommendation: Migrate as-is for Phase 8. Window manager personalization expected. If multi-profile support needed later, use chezmoi data variables (e.g., {{ if .personal }} launch personal apps {{ else }} launch work apps).

3. **Oh-My-Posh Config Location**
   - What we know: Current location is .config/oh-my-posh.omp.json, Dotbot symlinks it there
   - What's unclear: Is this the standard location, or should it be elsewhere?
   - Recommendation: Keep current location. Research shows oh-my-posh supports any path via --config flag in shell init. Current .zshrc likely references this path. Migrate as-is.

4. **Karabiner Config GUI Edits**
   - What we know: Karabiner GUI overwrites files (can't preserve symlinks), so chezmoi-managed file will show diffs after GUI edits
   - What's unclear: Should we document a "pull changes back" workflow, or warn users to edit JSON directly?
   - Recommendation: Document in Phase 8 PLAN that Karabiner GUI edits are OK, they'll appear in `chezmoi diff`, user should commit changes back to chezmoi source with `chezmoi add ~/.config/karabiner/karabiner.json` (re-add) after GUI edits. This is expected workflow.

## Sources

### Primary (HIGH confidence)

- **/twpayne/chezmoi** (Context7) - File management, add command, follow flag, naming conventions
- **/websites/chezmoi_io** (Context7) - Migration guide, .chezmoiignore conditionals, symlink handling
- **AeroSpace Guide** - Config location (~/.config/aerospace/aerospace.toml or ~/.aerospace.toml)
- **Karabiner-Elements Docs** - Config location, symlink incompatibility, file overwrite behavior
- **Phase 7 RESEARCH.md** - Verification framework patterns, .chezmoiignore template syntax

### Secondary (MEDIUM confidence)

- [How To Setup And Use The Aerospace Tiling Window Manager On macOS](https://www.josean.com/posts/how-to-setup-aerospace-tiling-window-manager) - Aerospace config setup patterns
- [Customize | Oh My Posh](https://ohmyposh.dev/docs/installation/customize) - oh-my-posh config location and usage
- [zsh-abbr GitHub](https://github.com/olets/zsh-abbr) - Abbreviations file location and dotfiles integration
- [Taking Control of My Dotfiles with chezmoi](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/) - Real-world chezmoi migration experience
- **Existing Dotbot config** (steps/terminal.yml) - Current symlink setup for Phase 8 configs

### Tertiary (LOW confidence)

- None required — all critical information verified via Context7 or official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already installed and user-configured, chezmoi v2.69.3 verified
- Architecture: HIGH - chezmoi add --follow is documented migration path, .chezmoiignore patterns verified in Phase 7
- Pitfalls: HIGH - Karabiner symlink issue documented in official GitHub issues, nanorc path verified in user's actual config file
- Portability: MEDIUM - Nanorc Homebrew path and aerospace app list identified as machine-specific, solutions proposed but not tested

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (30 days — stable tools, no fast-moving dependencies)
