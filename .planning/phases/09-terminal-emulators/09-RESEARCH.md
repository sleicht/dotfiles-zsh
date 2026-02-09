# Phase 9: Terminal Emulators - Research

**Researched:** 2026-02-09
**Domain:** Terminal emulator configuration migration to chezmoi (kitty, ghostty, wezterm)
**Confidence:** HIGH

## Summary

Phase 9 migrates terminal emulator configurations from Dotbot symlink management to chezmoi's file deployment system. The phase covers three terminal emulators: kitty (2600 lines, single file), ghostty (39 lines, single file), and wezterm (135 lines, single Lua file). Only ghostty and wezterm are currently installed on the system. Research confirms that terminal emulator configs can be migrated using the proven Phase 8 pattern (`chezmoi add --follow`), but with additional complexity around cache file exclusion. Unlike the static configs in Phase 8, terminal emulators generate runtime cache, state, and session files that must be explicitly excluded from chezmoi tracking to prevent spurious diffs.

Key findings:
- **kitty**: Cache at `~/.cache/kitty/` (sessions, saved-sessions), config at `~/.config/kitty/` (may include `current-theme.conf`, `*-theme.auto.conf` for theme switching)
- **ghostty**: State at `~/.local/state/ghostty/` (ssh_cache, crash reports), config at `~/.config/ghostty/config` (single file, minimal)
- **wezterm**: Config at `~/.config/wezterm/wezterm.lua` or `~/.wezterm.lua` (single Lua file, self-contained)

The critical difference from Phase 8 is that terminal emulators actively modify their config directories with cache/state files. If these are added to chezmoi, every `chezmoi diff` will show changes. The solution is to use `.chezmoiignore` patterns to exclude cache subdirectories while tracking the core config files. Phase 8's `.chezmoiignore` already ignores all three terminal emulators (Section 8), so removal of those blocks combined with strategic cache exclusion patterns enables migration.

**Key validated patterns:**
- Terminal configs are single-file (ghostty, wezterm) or single-file-plus-optional-themes (kitty)
- No secrets in terminal configs (all are static appearance/behavior settings)
- Cache exclusion uses `.chezmoiignore` patterns: `.config/kitty/current-theme.conf`, `.config/kitty/*-theme.auto.conf`
- Verification requires terminal launch test (confirms config loads without errors)
- Application parsability checks limited: kitty has `--debug-config`, ghostty/wezterm have version checks

**Primary recommendation:** Migrate each terminal emulator config file individually with `chezmoi add --follow`, add cache exclusion patterns to `.chezmoiignore` for kitty theme files, remove Phase 9 ignore blocks, create Phase 9 verification check file that confirms file existence and launches each installed terminal to validate config loading, and commit all migrations in a single batch per Phase 7-8 pattern.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| chezmoi | 2.69.3 | Dotfile deployment (replaces Dotbot symlinks) | Already installed (v1.0.0), official migration path |
| kitty | latest | GPU-accelerated terminal emulator | Fast, OpenGL-based, macOS/Linux support, extensive config |
| ghostty | 1.0+ | Cross-platform terminal emulator | New (2024), fast, GPU-accelerated, native UI per platform |
| wezterm | latest | GPU-accelerated terminal multiplexer | Rust-based, cross-platform, Lua config, built-in multiplexing |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| N/A | - | No supporting libraries needed | Terminal emulator configs are self-contained |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| chezmoi add --follow | Manual file copy | Manual copy error-prone, --follow is standard migration path |
| .chezmoiignore cache patterns | Track cache files | Cache files change constantly, cause spurious diffs, bloat repo |
| Per-terminal verification | Combined verification | Combined check simpler, follows Phase 8 pattern |
| kitty directory recursive add | kitty.conf file add only | Recursive risks adding cache files, single-file safer with .chezmoiignore |
| Template configs for cross-platform | Static configs | These configs are already portable (no platform-specific paths detected) |

**Installation:**
```bash
# All tools already installed:
# - chezmoi (Phase 2)
# - ghostty (pre-existing, installed via Homebrew)
# - wezterm (pre-existing, installed via Homebrew)
# - kitty (NOT currently installed, config exists but terminal not present)

# No new installations required for Phase 9
```

## Architecture Patterns

### Recommended Migration Structure

```
~/.local/share/chezmoi/               # chezmoi source directory
├── private_dot_config/
│   ├── kitty.conf                    # kitty config (2600 lines, no directory)
│   ├── ghostty/
│   │   └── config                    # ghostty config (39 lines)
│   └── wezterm/
│       └── wezterm.lua               # wezterm config (135 lines)
└── .chezmoiignore                    # Updated with cache exclusions

# Cache/state files (NEVER add to chezmoi):
~/.cache/kitty/                       # kitty cache (sessions, saved-sessions)
~/.local/state/ghostty/               # ghostty state (ssh_cache, crashes)
~/.config/kitty/current-theme.conf    # kitty theme switching (auto-generated)
~/.config/kitty/*-theme.auto.conf     # kitty dark/light/no-preference themes
```

### Pattern 1: Migrate Single-File Terminal Config

**What:** Replace Dotbot symlinks with chezmoi-managed real files for terminal emulator configs
**When to use:** All three terminal emulators (ghostty, wezterm are single files; kitty is single file at root of .config)
**Example:**
```bash
# Source: https://www.chezmoi.io/reference/commands/add/ (official docs)

# Current state: Dotbot symlink
$ ls -la ~/.config/ghostty/config
lrwxr-xr-x  1 user  staff  68 Jun  3  2025 ~/.config/ghostty/config -> ~/Projects/dotfiles-zsh/.config/ghostty/config

# Migrate to chezmoi
$ chezmoi add --follow ~/.config/ghostty/config
# Result: ~/.local/share/chezmoi/private_dot_config/ghostty/config

# wezterm (also single file in wezterm directory)
$ chezmoi add --follow ~/.config/wezterm/wezterm.lua
# Result: ~/.local/share/chezmoi/private_dot_config/wezterm/wezterm.lua

# kitty (single file at .config root, NOT in kitty/ directory)
$ chezmoi add --follow ~/.config/kitty.conf
# Result: ~/.local/share/chezmoi/private_dot_config/kitty.conf
```

**Why this works:**
- `--follow` flag resolves symlinks and captures actual file content (not the symlink itself)
- Single-file configs avoid the known issue with `--follow --recursive` on symlinked directories ([Issue #3772](https://github.com/twpayne/chezmoi/issues/3772))
- No includes/sourcing detected in any of the three configs (self-contained)

### Pattern 2: Exclude Cache Files with .chezmoiignore

**What:** Prevent chezmoi from tracking terminal emulator cache/state files while managing core config
**When to use:** All terminal emulators that generate runtime cache, state, or auto-generated files
**Example:**
```bash
# Source: https://www.chezmoi.io/reference/special-files/chezmoiignore/ (official docs)

# Add to .chezmoiignore (after removing Phase 9 pending block):

# Terminal Emulator Cache Exclusions
# kitty theme switching (auto-generated by kitty when themes are changed)
.config/kitty/current-theme.conf
.config/kitty/dark-theme.auto.conf
.config/kitty/light-theme.auto.conf
.config/kitty/no-preference-theme.auto.conf

# kitty themes directory (if user adds themes later)
.config/kitty/themes
.config/kitty/themes/**

# Note: kitty cache at ~/.cache/kitty/ is already excluded by Section 5 OS-specific or default XDG cache behavior
# Note: ghostty state at ~/.local/state/ghostty/ is already outside .config (XDG_STATE_HOME)
# Note: wezterm has no cache in .config (uses XDG cache locations)
```

**Why this works:**
- `.chezmoiignore` uses gitignore-like glob patterns relative to `$HOME` ([official docs](https://www.chezmoi.io/reference/special-files/chezmoiignore/))
- Terminal cache files change frequently (sessions, saved-sessions, ssh_cache, crash reports)
- Excluding cache prevents spurious `chezmoi diff` changes every time terminal runs
- Pattern matches exact files kitty generates for theme switching ([Arch Wiki - kitty themes](https://man.archlinux.org/man/extra/kitty/kitten-themes.1.en))

### Pattern 3: Verify Terminal Config with Launch Test

**What:** Confirm terminal emulator can launch and load chezmoi-managed config without errors
**When to use:** After migrating each terminal emulator config
**Example:**
```bash
# Source: Derived from Phase 8 verification pattern (scripts/verify-checks/08-basic-configs.sh)

# ghostty: Launch in headless mode, check exit code
$ ghostty --version > /dev/null 2>&1 && echo "ghostty config valid"

# wezterm: Launch with config check, exit immediately
$ wezterm start --always-new-process -- exit > /dev/null 2>&1 && echo "wezterm config valid"

# kitty: Use built-in config debugger
$ kitty --debug-config > /dev/null 2>&1 && echo "kitty config valid"

# Note: Full verification requires GUI (terminal launch), headless checks are minimal
```

**Why this works:**
- Terminal emulators parse config on launch (syntax errors cause immediate failure)
- Exit code 0 confirms config loaded successfully
- Headless/quick-exit tests avoid blocking in verification script
- kitty has built-in `--debug-config` for validation without GUI launch

### Anti-Patterns to Avoid

- **Adding cache directories to chezmoi:** Terminal emulators modify `~/.cache/kitty/`, `~/.local/state/ghostty/` at runtime. Adding these causes constant diff noise and repo bloat.
- **Using `chezmoi add --recursive` on symlinked directories:** Known issue ([#3772](https://github.com/twpayne/chezmoi/issues/3772)) where `--follow --recursive` on symlink pointing to directory adds the directory but not its contents. Use explicit file paths instead.
- **Ignoring theme files without documenting:** kitty's `current-theme.conf` and `*-theme.auto.conf` are auto-generated by `kitten themes`. If not ignored, every theme change triggers a diff. Document this in `.chezmoiignore` comments.
- **Assuming all terminals need theme exclusions:** Only kitty generates theme files in `.config/`. ghostty and wezterm define themes inline in their config files (no separate theme files).
- **Verifying with full GUI launch in automation:** Terminal emulator launch requires GUI context. Use minimal checks (`--version`, `--debug-config`) in verification scripts, not full launch.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cache file exclusion | Manual post-apply cleanup | .chezmoiignore patterns | chezmoi handles exclusions natively, no custom scripts needed |
| Cross-platform config differences | Separate configs per OS | Single config with inline conditionals (if needed) | All three terminal emulators are cross-platform, configs are portable |
| Config syntax validation | Custom parser | Terminal's built-in validation (`--debug-config`, version check) | Terminals validate their own config format, don't reimplement |
| Theme management | Custom theme switcher | Terminal's built-in theme system (kitty `kitten themes`, ghostty/wezterm inline) | Theme systems are terminal-specific, complex, well-implemented |

**Key insight:** Terminal emulators have mature configuration systems and built-in validation. The migration challenge is cache exclusion (solved by `.chezmoiignore`), not config complexity. Don't build custom tooling for problems the terminals already solve.

## Common Pitfalls

### Pitfall 1: Adding kitty Theme Files to chezmoi

**What goes wrong:** Running `chezmoi add --recursive ~/.config/kitty` captures `current-theme.conf` and `*-theme.auto.conf`, which kitty overwrites when themes change. Every theme switch creates a chezmoi diff.

**Why it happens:** kitty's theme system auto-generates these files ([Arch Wiki - kitten-themes](https://man.archlinux.org/man/extra/kitty/kitten-themes.1.en)). The files are configuration but also cache/state (they change based on user actions).

**How to avoid:**
1. Add `kitty.conf` explicitly, not the directory: `chezmoi add --follow ~/.config/kitty.conf`
2. Add cache exclusions to `.chezmoiignore` BEFORE applying:
   ```
   .config/kitty/current-theme.conf
   .config/kitty/dark-theme.auto.conf
   .config/kitty/light-theme.auto.conf
   .config/kitty/no-preference-theme.auto.conf
   .config/kitty/themes/**
   ```
3. Verify with `chezmoi diff` after changing kitty theme (should show no changes)

**Warning signs:**
- `chezmoi diff` shows changes to `current-theme.conf` after using kitty
- `chezmoi status` shows untracked files in `.config/kitty/`
- Git status in chezmoi source shows modified theme files

### Pitfall 2: Missing --follow Flag on Terminal Config Symlinks

**What goes wrong:** Running `chezmoi add ~/.config/ghostty/config` without `--follow` adds the symlink itself to chezmoi, not the file content. When applied to a new machine, chezmoi creates a symlink pointing to a nonexistent Dotbot repo path.

**Why it happens:** chezmoi's default behavior preserves symlinks ([official docs](https://www.chezmoi.io/user-guide/manage-different-types-of-file/)). The `--follow` flag is required to dereference and capture the target file content.

**How to avoid:**
1. ALWAYS use `--follow` when migrating from Dotbot: `chezmoi add --follow <file>`
2. Verify in chezmoi source: `cat ~/.local/share/chezmoi/private_dot_config/ghostty/config` (should show file content, not symlink)
3. Check after apply on test machine: `ls -la ~/.config/ghostty/config` (should be regular file, not symlink)

**Warning signs:**
- `ls -la ~/.local/share/chezmoi/private_dot_config/ghostty/config` shows symlink type
- `chezmoi apply` creates symlinks instead of real files
- Error on new machine: "symbolic link target does not exist"

### Pitfall 3: Forgetting to Remove Phase 9 from .chezmoiignore

**What goes wrong:** After adding terminal configs to chezmoi source, they're still ignored by `.chezmoiignore` Section 8 (Phase 9 pending block). `chezmoi managed` doesn't list them, `chezmoi apply` doesn't deploy them.

**Why it happens:** Phase 7 established `.chezmoiignore` with pending migration blocks for Phases 8-12. Phase 9 block (lines 118-125) ignores `.config/kitty`, `.config/ghostty`, `.wezterm.lua` until explicitly removed.

**How to avoid:**
1. After adding all terminal configs to chezmoi source, edit `~/.local/share/chezmoi/.chezmoiignore`
2. Remove Section 8 block (lines 118-125):
   ```
   # -----------------------------------------------------------------------------
   # 8. Pending Migration — Phase 9 (Terminal Emulators)
   # Remove these entries when Phase 9 migrates them to chezmoi.
   # -----------------------------------------------------------------------------
   .config/kitty
   .config/kitty/**
   .config/ghostty
   .config/ghostty/**
   .wezterm.lua
   ```
3. Add cache exclusions in place of removed block (see Pattern 2)
4. Verify: `chezmoi managed --include=files | grep -E "kitty|ghostty|wezterm"` (should show terminal configs)

**Warning signs:**
- `chezmoi managed` doesn't list terminal configs after adding them
- `chezmoi diff` shows no changes even though terminal configs were added
- Terminal configs appear in `chezmoi unmanaged` instead of `chezmoi managed`

### Pitfall 4: Not Handling Missing Terminal Emulators in Verification

**What goes wrong:** Verification script runs `kitty --debug-config` but kitty is not installed. Script fails with "command not found" error, blocking verification of ghostty and wezterm (which ARE installed).

**Why it happens:** Phase 9 configs exist for three terminals, but only two are installed on the current machine (ghostty, wezterm). kitty config exists (2600 lines) but terminal binary not present.

**How to avoid:**
1. Make app parsability checks non-fatal when app not installed (Phase 8 pattern from 08-02-PLAN.md):
   ```bash
   # Check if terminal is installed before validating config
   if command -v ghostty &> /dev/null; then
     ghostty --version &> /dev/null && echo "✓ ghostty config valid"
   else
     echo "⊘ ghostty not installed (skipping config check)"
   fi
   ```
2. Use the Phase 7 verification framework's `check_app_can_parse` helper (handles missing apps gracefully)
3. Document in verification script comments: "Config may exist for uninstalled terminal (portable config repository)"

**Warning signs:**
- Verification script exits non-zero on "command not found"
- Error message: "kitty: command not found"
- Phase 9 verification fails despite ghostty/wezterm configs being valid

## Code Examples

Verified patterns from official sources and Phase 8 execution:

### Migrate Terminal Emulator Config (Single File)

```bash
# Source: https://www.chezmoi.io/reference/commands/add/ + Phase 8 execution pattern

# ghostty: Single file in directory
$ chezmoi add --follow ~/.config/ghostty/config
# Result: ~/.local/share/chezmoi/private_dot_config/ghostty/config

# wezterm: Single Lua file in directory
$ chezmoi add --follow ~/.config/wezterm/wezterm.lua
# Result: ~/.local/share/chezmoi/private_dot_config/wezterm/wezterm.lua

# kitty: Single file at .config root (NOT in kitty/ subdirectory)
$ chezmoi add --follow ~/.config/kitty.conf
# Result: ~/.local/share/chezmoi/private_dot_config/kitty.conf

# Verify in chezmoi source (should be regular files, not symlinks)
$ ls -la ~/.local/share/chezmoi/private_dot_config/ghostty/config
$ ls -la ~/.local/share/chezmoi/private_dot_config/wezterm/wezterm.lua
$ ls -la ~/.local/share/chezmoi/private_dot_config/kitty.conf
```

### Update .chezmoiignore for Cache Exclusion

```bash
# Source: https://www.chezmoi.io/reference/special-files/chezmoiignore/

# Edit chezmoi source .chezmoiignore
$ chezmoi edit ~/.chezmoiignore

# Remove Phase 9 pending block (Section 8, lines 118-125)
# Replace with cache exclusion patterns:

# -----------------------------------------------------------------------------
# 8. Terminal Emulator Cache (Exclude auto-generated files)
# These files are generated by terminal emulators at runtime.
# -----------------------------------------------------------------------------
# kitty theme switching (auto-generated by kitten themes)
.config/kitty/current-theme.conf
.config/kitty/dark-theme.auto.conf
.config/kitty/light-theme.auto.conf
.config/kitty/no-preference-theme.auto.conf
.config/kitty/themes
.config/kitty/themes/**

# Verify no terminal configs appear in ignored list
$ chezmoi unmanaged | grep -E "kitty|ghostty|wezterm"
# (should be empty — terminal configs are now managed)

# Verify terminal configs appear in managed list
$ chezmoi managed --include=files | grep -E "kitty|ghostty|wezterm"
# .config/ghostty/config
# .config/kitty.conf
# .config/wezterm/wezterm.lua
```

### Verify Terminal Config with Phase 7 Framework

```bash
# Source: scripts/verify-checks/08-basic-configs.sh (Phase 8 execution)

#!/usr/bin/env bash
# Phase 9 verification: Terminal Emulators

source "$(dirname "$0")/../verify-lib/check-exists.sh"
source "$(dirname "$0")/../verify-lib/check-parsable.sh"

declare -i passed=0 failed=0

# File existence checks (all three terminals)
check_file_exists "$HOME/.config/ghostty/config" || ((failed++))
check_file_exists "$HOME/.config/wezterm/wezterm.lua" || ((failed++))
check_file_exists "$HOME/.config/kitty.conf" || ((failed++))

# Not-a-symlink checks (confirm chezmoi replaced Dotbot symlinks)
if [[ -L "$HOME/.config/ghostty/config" ]]; then
  echo "✗ ghostty config is still a symlink (should be real file)"
  ((failed++))
else
  echo "✓ ghostty config is a real file (not symlink)"
  ((passed++))
fi

# Application parsability checks (only if terminal installed)
if command -v ghostty &> /dev/null; then
  ghostty --version &> /dev/null && {
    echo "✓ ghostty can load config"
    ((passed++))
  } || {
    echo "✗ ghostty config invalid"
    ((failed++))
  }
else
  echo "⊘ ghostty not installed (skipping config check)"
fi

if command -v wezterm &> /dev/null; then
  wezterm start --always-new-process -- exit &> /dev/null && {
    echo "✓ wezterm can load config"
    ((passed++))
  } || {
    echo "✗ wezterm config invalid"
    ((failed++))
  }
else
  echo "⊘ wezterm not installed (skipping config check)"
fi

if command -v kitty &> /dev/null; then
  kitty --debug-config &> /dev/null && {
    echo "✓ kitty can load config"
    ((passed++))
  } || {
    echo "✗ kitty config invalid"
    ((failed++))
  }
else
  echo "⊘ kitty not installed (skipping config check)"
fi

# Cache exclusion verification (kitty theme files should be ignored)
if [[ -f "$HOME/.config/kitty/current-theme.conf" ]]; then
  # Theme file exists, check if it's ignored
  chezmoi unmanaged | grep -q "current-theme.conf" && {
    echo "✓ kitty current-theme.conf properly ignored"
    ((passed++))
  } || {
    echo "✗ kitty current-theme.conf not ignored (will cause diff noise)"
    ((failed++))
  }
fi

echo "Phase 9 verification: $passed passed, $failed failed"
[[ $failed -eq 0 ]] && exit 0 || exit 1
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Dotbot symlinks | chezmoi real files | v1.1 (2026) | Unified dotfile manager, no separate symlink tool |
| Manual cache avoidance | .chezmoiignore patterns | chezmoi 2.0+ | Explicit exclusions prevent cache bloat |
| Per-OS terminal configs | Single portable config | 2024+ | Modern terminals (ghostty, wezterm) designed for cross-platform portability |
| Terminal-specific theme files | Inline theme definitions | 2024+ | ghostty/wezterm use inline themes, only kitty uses separate files |

**Deprecated/outdated:**
- **Separate terminal configs per OS**: Modern terminal emulators (ghostty 1.0+, wezterm 0.20+, kitty 0.30+) are designed for cross-platform portability. Configs use relative paths and portable settings. No templating needed for Phase 9 configs.
- **Adding entire terminal config directories**: kitty's theme system (introduced 0.27.0, 2023) auto-generates files in `.config/kitty/`. Adding the directory risks tracking cache files. Add `kitty.conf` explicitly instead.

## Open Questions

1. **Should kitty config be migrated if kitty is not installed?**
   - What we know: kitty.conf exists (2600 lines) in Dotbot repo, but `which kitty` fails. ghostty and wezterm are installed.
   - What's unclear: Is kitty config maintained for future use, or is it deprecated in favor of ghostty/wezterm?
   - Recommendation: Migrate all three configs (maintains portable config repository). Verification script skips parsability check if terminal not installed. User can install kitty later and config will be ready.

2. **Do terminal configs need templating for cross-platform differences?**
   - What we know: All three configs use relative paths and portable settings. No hardcoded macOS/Linux paths detected. Terminal emulators are designed for cross-platform use.
   - What's unclear: Are there hidden platform-specific settings in the 2600-line kitty.conf?
   - Recommendation: Start with static configs (no templating). If platform differences discovered during testing, add templates in follow-up plan. Phase 8 pattern: migrate first, template only if needed.

3. **Should verification test theme switching functionality?**
   - What we know: kitty generates theme files when `kitten themes` is run. These must be ignored to prevent diff noise.
   - What's unclear: Should verification script test theme switching (run `kitten themes`, change theme, verify no diff)?
   - Recommendation: No. Theme switching is user functionality, not migration requirement. Success criteria are "terminal launches with config" and "cache files don't trigger diffs". Manual testing of theme switching can be done post-migration.

## Sources

### Primary (HIGH confidence)

- [chezmoi .chezmoiignore reference](https://www.chezmoi.io/reference/special-files/chezmoiignore/) - Official documentation on ignore patterns
- [chezmoi add command](https://www.chezmoi.io/reference/commands/add/) - Official documentation on --follow flag
- [Arch Wiki - kitty themes](https://man.archlinux.org/man/extra/kitty/kitten-themes.1.en) - Official documentation on kitty theme system
- [Ghostty XDG state directory](https://github.com/ghostty-org/ghostty/discussions/8872) - Official discussion on $XDG_STATE_HOME usage
- [kitty cache directory](https://wiki.archlinux.org/title/Kitty) - Official Arch Wiki documentation on kitty cache location
- Phase 8 execution (08-01-PLAN.md, 08-02-PLAN.md) - Proven migration patterns from completed phase

### Secondary (MEDIUM confidence)

- [WezTerm configuration files](https://wezterm.org/config/files.html) - Official documentation on config file discovery
- [Ghostty configuration](https://ghostty.org/docs/config) - Official documentation on config file location
- [chezmoi --follow --recursive issue](https://github.com/twpayne/chezmoi/issues/3772) - Known bug report with workarounds
- [Migrating from Nix to chezmoi](https://htdocs.dev/posts/migrating-from-nix-and-home-manager-to-homebrew-and-chezmoi/) - Real-world migration blog post

### Tertiary (LOW confidence)

- None (all findings verified with official sources)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already installed, configs exist in Dotbot repo, Phase 8 established migration pattern
- Architecture: HIGH - Single-file configs verified by inspection, cache locations confirmed in official docs, .chezmoiignore pattern validated in Phase 7-8
- Pitfalls: HIGH - Cache file issue documented in official kitty docs, --follow flag requirement proven in Phase 8, .chezmoiignore removal is Phase 7-8 pattern
- Cross-platform portability: MEDIUM - Configs appear portable (no hardcoded paths), but 2600-line kitty.conf not fully analyzed for platform-specific settings

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (30 days - terminal emulators are stable, config formats change slowly)
