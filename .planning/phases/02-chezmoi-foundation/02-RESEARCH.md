# Phase 2: chezmoi Foundation - Research

**Researched:** 2026-01-25
**Domain:** chezmoi dotfiles management, migration from Dotbot symlinks, Git repository migration
**Confidence:** HIGH

## Summary

Phase 2 establishes chezmoi as the core dotfiles manager by initializing chezmoi's source directory, migrating shell configuration files (.zshrc, .zshenv, .zprofile, zsh.d/*.zsh) and git config from Dotbot symlinks to chezmoi-managed files, and setting up Git version control with a remote repository. The research validates chezmoi 2.69.3 as the stable foundation with well-established patterns for migrating from symlink-based systems like Dotbot. The key migration approach uses `chezmoi add --follow` to convert symlinks to managed files, preserving git history through file renames, and enables an IDE-friendly workflow where users edit files in the chezmoi source directory (`~/.local/share/chezmoi`) with full editor features.

**Key validated patterns:**
- `chezmoi add --follow` is the standard approach for migrating from symlink-based dotfile managers
- Fork/migrate workflow: keep git history by renaming files with chezmoi naming conventions (e.g., `.zshrc` → `dot_zshrc`)
- IDE workflow: edit in source directory, manually run `chezmoi apply` (not auto-apply on save)
- Incremental migration: Dotbot continues managing unmigrated files during transition via .chezmoiroot

**Primary recommendation:** Initialize chezmoi with existing repo structure, use `chezmoi add --follow` for symlinked files, migrate in atomic groups (shell core → git config → etc.), verify each group works before next migration, commit per group for easy rollback.

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| chezmoi | 2.69.3 | Dotfiles management with templating | Most recent stable release (Jan 2025), mature cross-platform support, 560+ code examples in docs |
| Git | 2.x+ | Version control for source directory | Universal VCS, chezmoi designed around git workflows with autoCommit/autoPush |
| Zsh | 5.x+ | Shell environment | Target shell for configuration migration |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| delta | Latest | Git diff viewer | Optional: enhanced diff viewing with `chezmoi diff` |
| age/gpg | Latest | File encryption | Optional: Phase 2 scope excludes secrets, but framework present |
| .chezmoiignore | N/A | Exclude patterns | Control which files chezmoi manages vs Dotbot during migration |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| chezmoi | Continue Dotbot | Dotbot has no templating (can't handle OS/machine differences), no secret management |
| `chezmoi add --follow` | Manual copy + add | Manual loses symlink resolution, error-prone for large migrations |
| Fork repo approach | Fresh repo | Fresh repo loses git history, harder to track changes over time |
| Manual `chezmoi apply` | Auto-apply on edit | Auto-apply surprises users, IDE editing breaks with auto-apply (file changes while editor open) |

**Installation:**
```bash
# macOS (Homebrew)
brew install chezmoi

# Verify version
chezmoi --version  # Should show 2.69.3 or newer
```

## Architecture Patterns

### Recommended Migration Structure

```
Current (Dotbot):
~/.dotfiles/
├── .config/
│   ├── zshrc          # Symlink target
│   ├── zshenv         # Symlink target
│   ├── zprofile       # Symlink target
│   └── git/gitconfig  # Symlink target
├── zsh.d/             # Symlink target directory
│   ├── aliases.zsh
│   ├── functions.zsh
│   └── ...
└── steps/terminal.yml # Dotbot config (defines symlinks)

Target (chezmoi):
~/.local/share/chezmoi/              # Source directory
├── .git/                            # Version controlled (forked from dotfiles repo)
├── dot_zshrc.tmpl                   # Was: .config/zshrc → ~/.zshrc symlink
├── dot_zshenv.tmpl                  # Was: .config/zshenv → ~/.zshenv symlink
├── dot_zprofile.tmpl                # Was: .config/zprofile → ~/.zshprofile symlink
├── dot_zsh.d/                       # Was: zsh.d → ~/.zsh.d symlink
│   ├── aliases.zsh
│   ├── functions.zsh
│   ├── variables.zsh
│   └── ...
├── dot_config/
│   └── git/
│       ├── gitconfig.tmpl           # Was: .config/git/gitconfig → ~/.gitconfig symlink
│       ├── gitignore                # Global gitignore
│       └── gitattributes            # Global gitattributes
└── .chezmoiignore                   # Excludes: files still managed by Dotbot

Home directory (targets):
~/
├── .zshrc              # Real file (chezmoi managed)
├── .zshenv             # Real file (chezmoi managed)
├── .zprofile           # Real file (chezmoi managed)
├── .zsh.d/             # Real directory (chezmoi managed)
│   ├── aliases.zsh
│   ├── functions.zsh
│   └── ...
├── .gitconfig          # Real file (chezmoi managed)
└── .config/            # Mixed: some chezmoi, some Dotbot
    ├── nvim → ~/.dotfiles/nvim      # Still Dotbot symlink (unmigrated)
    ├── atuin → ~/.dotfiles/.config/atuin  # Still Dotbot symlink (unmigrated)
    └── git/
        ├── gitconfig   # Real file (chezmoi managed)
        ├── gitignore   # Real file (chezmoi managed)
        └── gitattributes # Real file (chezmoi managed)
```

### Pattern 1: Fork and Migrate (Preserve History)

**What:** Keep git history when migrating existing dotfiles repo to chezmoi structure

**When to use:** Migrating from existing version-controlled dotfiles (like this Dotbot setup)

**Example:**
```bash
# Step 1: Initialize chezmoi with existing repo
cd ~/.dotfiles
chezmoi init --source=~/.local/share/chezmoi

# Step 2: Copy existing files to chezmoi source
# Rename files to follow chezmoi conventions
cp .config/zshrc ~/.local/share/chezmoi/dot_zshrc
cp .config/zshenv ~/.local/share/chezmoi/dot_zshenv
cp .config/zprofile ~/.local/share/chezmoi/dot_zprofile
cp -r zsh.d ~/.local/share/chezmoi/dot_zsh.d
cp -r .config/git ~/.local/share/chezmoi/dot_config/git

# Step 3: Initialize git in chezmoi source
cd ~/.local/share/chezmoi
git init
git add .
git commit -m "chore: initial chezmoi migration from dotbot"

# Step 4: Connect to remote (fork of original repo or new)
git remote add origin git@github.com:username/dotfiles.git
git push -u origin main
```

**Why this works:** Git detects file renames, preserving per-file history. Starting with clean chezmoi structure simplifies future management.

### Pattern 2: Incremental Migration with .chezmoiignore

**What:** Migrate files in groups while Dotbot continues managing unmigrated files

**When to use:** Minimizing risk by migrating critical files first, testing, then adding more

**Example:**
```bash
# .chezmoiignore - tells chezmoi to ignore files still managed by Dotbot
# Paths relative to home directory

# Still managed by Dotbot - ignore these
.config/nvim
.config/nvim/**
.config/atuin
.config/atuin/**
.config/sheldon
.config/sheldon/**
.config/kitty
.wezterm.lua
.config/ghostty
# ... all other Dotbot-managed files

# NOT ignored (chezmoi manages these):
# .zshrc, .zshenv, .zprofile, .zsh.d/*, .gitconfig, .config/git/*
```

**Migration steps:**
1. Add Phase 2 files to chezmoi: `chezmoi add --follow ~/.zshrc ~/.zshenv ~/.zprofile ~/.gitconfig`
2. Add to .chezmoiignore: everything else Dotbot manages
3. Test: `chezmoi diff` (should only show Phase 2 files)
4. Apply: `chezmoi apply`
5. Verify shell works: open new terminal, test aliases/functions
6. Remove Dotbot symlinks for migrated files: edit `steps/terminal.yml`, comment out migrated entries
7. Commit both repos: dotfiles (updated Dotbot config) and chezmoi source

**Why this works:** .chezmoiignore prevents conflicts between Dotbot and chezmoi. Gradual migration means each step is testable and reversible.

### Pattern 3: Symlink-to-File Migration

**What:** Convert Dotbot symlinks to chezmoi-managed real files using `--follow`

**When to use:** Migrating from any symlink-based dotfile manager (Dotbot, stow, yadm, etc.)

**Example:**
```bash
# Current state: ~/.zshrc is a symlink
ls -la ~/.zshrc
# lrwxr-xr-x  1 user  staff  30 Jan 20 10:00 /Users/user/.zshrc -> /Users/user/.dotfiles/.config/zshrc

# Add with --follow (tells chezmoi: manage the TARGET, not the symlink)
chezmoi add --follow ~/.zshrc

# Check what chezmoi created
ls ~/.local/share/chezmoi/
# dot_zshrc  (contains file contents, not symlink)

# Before applying: verify diff
chezmoi diff
# Shows: symlink will be replaced with real file (same content)

# Apply the change
chezmoi apply

# Result: ~/.zshrc is now a real file
ls -la ~/.zshrc
# -rw-r--r--  1 user  staff  2048 Jan 25 12:00 /Users/user/.zshrc
```

**Why this works:** `--follow` dereferences symlinks, adding the target file content to chezmoi. When applied, chezmoi replaces the symlink with the real file.

### Pattern 4: IDE-Friendly Editing Workflow

**What:** Edit chezmoi source files directly in IDE/editor, manually apply changes

**When to use:** Always — best practice for understanding changes before applying

**Example:**
```bash
# Open chezmoi source as IDE project
code ~/.local/share/chezmoi

# Edit files in IDE (e.g., dot_zshrc.tmpl)
# Save changes

# Review what would change
chezmoi diff

# Apply if happy
chezmoi apply -v

# Or edit + apply in one step (for quick iterations)
chezmoi edit --apply ~/.zshrc
```

**Configuration for this workflow:**
```toml
# ~/.config/chezmoi/chezmoi.toml
[edit]
  apply = false  # Don't auto-apply on edit (manual chezmoi apply)

[git]
  autoCommit = true   # Auto-commit source changes
  autoPush = false    # Don't auto-push (prevents accidental secret exposure)
```

**Why this works:** IDE provides full features (autocomplete, linting, git integration). Manual apply gives control and awareness of what's changing. Auto-commit keeps source history without auto-push risk.

### Pattern 5: Verification Before Apply

**What:** Use chezmoi's built-in verification commands before making changes

**When to use:** Every migration step, before every `chezmoi apply`

**Example:**
```bash
# Step 1: Check health
chezmoi doctor
# Verifies: git installed, editor configured, no common problems

# Step 2: See what would change
chezmoi diff
# Shows unified diff of all changes (like git diff)

# Step 3: Dry run
chezmoi apply --dry-run --verbose
# Lists every operation without executing

# Step 4: Apply if happy
chezmoi apply --verbose
# Verbose shows each file operation

# Step 5: Verify result
chezmoi verify
# Confirms target state matches source state
```

**Why this works:** Layered verification (doctor → diff → dry-run → apply → verify) catches problems at each stage. Never surprises with unexpected changes.

### Anti-Patterns to Avoid

- **Editing target files directly:** Never edit `~/.zshrc` after migration — always edit `~/.local/share/chezmoi/dot_zshrc`. chezmoi will overwrite direct edits on next apply.
- **Auto-apply on edit:** Setting `edit.apply = true` breaks IDE workflows (file changes under editor's feet) and removes opportunity to review changes.
- **Auto-push without review:** `git.autoPush = true` risks pushing secrets to public repos. Only enable for private repos after secret management is in place.
- **Migrating everything at once:** Big-bang migration is hard to test and hard to rollback. Incremental migration (core shell → git → tools → etc.) is safer.
- **Forgetting .chezmoiignore during incremental migration:** Without ignore patterns, chezmoi and Dotbot will conflict on unmigrated files.
- **Not testing shell after apply:** Always open new terminal and test aliases/functions/completions after migrating shell files.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File naming conventions | Manual renaming scripts | `chezmoi add` with `chattr` | chezmoi handles all naming edge cases (private_, executable_, .tmpl, etc.) |
| Template detection | Custom template markers | `chezmoi add --autotemplate` | Auto-detects user email, hostname, etc. for templating |
| Symlink resolution | Manual `readlink` + copy | `chezmoi add --follow` | Handles nested symlinks, broken symlinks, edge cases |
| Diff viewing | Custom diff scripts | `chezmoi diff` | Integrates with delta/diff-so-fancy, unified format |
| Cross-platform conditionals | Shell case statements | chezmoi templates (`{{ if eq .chezmoi.os "darwin" }}`) | Template engine is robust, handles all platforms |
| Git history preservation | Complex git filter-branch | File renames (git auto-detects) | Git's rename detection preserves history automatically |

**Key insight:** chezmoi has solved the "dotfile manager" problem domain with 5+ years of edge case handling. Custom scripts will miss cases that chezmoi handles automatically (special characters in filenames, permission preservation, atomic operations, etc.).

## Common Pitfalls

### Pitfall 1: Editing Target Files Instead of Source

**What goes wrong:** User migrates `.zshrc` to chezmoi, then edits `~/.zshrc` directly. Next `chezmoi apply` overwrites changes.

**Why it happens:** Muscle memory from pre-chezmoi workflow. File exists in home directory, so editor opens it naturally.

**How to avoid:**
- **Never edit target files after migration** — always edit source
- Use `chezmoi edit ~/.zshrc` (opens source file in editor)
- Or: open `~/.local/share/chezmoi` as IDE project
- Set up shell reminder (first-time message) directing to chezmoi workflow

**Warning signs:** Changes to dotfiles don't persist after running `chezmoi apply`. chezmoi diff shows unexpected changes.

### Pitfall 2: Applying Without Reviewing Diff

**What goes wrong:** Run `chezmoi apply` without checking `chezmoi diff` first. Unexpected files get modified or removed.

**Why it happens:** Rushing through workflow, trusting chezmoi too much without verifying.

**How to avoid:**
- **Always run `chezmoi diff` before `chezmoi apply`**
- Use dry-run: `chezmoi apply --dry-run --verbose`
- Create alias: `alias cza='chezmoi diff && read -q "REPLY?Apply? (y/n) " && chezmoi apply'`

**Warning signs:** None (silent surprise) — that's the problem. Prevention is key.

### Pitfall 3: Forgetting to Remove Dotbot Symlinks

**What goes wrong:** Migrate files to chezmoi but leave Dotbot symlink configuration. Next `./install` (Dotbot) recreates symlinks, overwriting chezmoi-managed files.

**Why it happens:** Dotbot config (`steps/terminal.yml`) not updated to reflect migration.

**How to avoid:**
- **Update Dotbot config immediately after each migration:**
  - Comment out migrated symlinks in `steps/terminal.yml`
  - Add comment: `# Migrated to chezmoi - see ~/.local/share/chezmoi`
- Test Dotbot still works: `./install` (should not touch migrated files)
- Eventually remove Dotbot entirely (Phase 4 scope)

**Warning signs:** Running `./install` breaks shell. Symlinks reappear for chezmoi-managed files.

### Pitfall 4: Wrong File Naming Conventions

**What goes wrong:** Manual copy to chezmoi source using wrong names. File `~/.zshrc` copied as `zshrc` instead of `dot_zshrc`. chezmoi can't map it to home directory.

**Why it happens:** Not understanding chezmoi naming conventions (dot_ prefix for hidden files, private_ for permissions, etc.).

**How to avoid:**
- **Always use `chezmoi add` instead of manual copy** — it handles naming automatically
- If manual copy needed: learn conventions from official docs
  - Hidden files (`.zshrc`) → `dot_zshrc`
  - Private files (`.ssh/config`) → `private_dot_ssh/config`
  - Executable scripts → `executable_script.sh`
  - Templates → append `.tmpl` suffix
- Use `chezmoi chattr` to fix attributes after adding

**Warning signs:** `chezmoi diff` shows no changes for files you added. `chezmoi apply` doesn't create expected files in home directory.

### Pitfall 5: Auto-Push Exposing Secrets

**What goes wrong:** Enable `git.autoPush = true` in config. Accidentally add file with API key/token. chezmoi auto-commits and auto-pushes to public GitHub repo before you notice.

**Why it happens:** Convenience setting (autoPush) enabled before secret management in place.

**How to avoid:**
- **Never enable autoPush until Phase 6 (secrets)** is complete
- Phase 2 config: `autoCommit = true`, `autoPush = false`
- Use pre-commit hooks with gitleaks (Phase 6) before enabling autoPush
- For private repos: autoPush acceptable after secret management

**Warning signs:** None until too late (secret in public repo history). Prevention critical.

### Pitfall 6: Shell Breaks After Migration

**What goes wrong:** Migrate shell files (`.zshrc`, `.zshenv`, `.zprofile`, `zsh.d/`) to chezmoi. Open new terminal — shell doesn't load, aliases missing, completions broken.

**Why it happens:**
- Template syntax errors (unclosed `{{ }}`)
- Missing files (forgot to migrate entire `zsh.d/` directory)
- Permissions wrong (file not executable)
- Wrong .chezmoi.os value in templates

**How to avoid:**
- **Test shell after each migration step:**
  1. `chezmoi apply`
  2. Open new terminal
  3. Test: `alias` (check aliases load), `which sheldon` (check PATH), tab completion
- **Don't template initially** — migrate as plain files first (no `.tmpl` suffix)
  - Add templates in Phase 3 (after basic migration works)
- Keep backup terminal open during migration
- Have recovery script ready (Phase 1 safety net)

**Warning signs:** New terminal shows errors on startup. Aliases/functions undefined. Command completions missing.

### Pitfall 7: Losing Git History During Migration

**What goes wrong:** Create fresh chezmoi git repo instead of migrating existing. Lose all commit history for dotfiles.

**Why it happens:** `chezmoi init` creates empty git repo. User doesn't realize they should preserve existing repo.

**How to avoid:**
- **Use fork/migrate approach:**
  1. Copy files to chezmoi source with proper naming
  2. `git init` in chezmoi source
  3. Commit initial structure
  4. Push to fork of original repo (or new repo with history)
- Git detects renames (`.zshrc` → `dot_zshrc`) and preserves per-file history
- Alternative: use `.chezmoiroot` to keep existing repo structure (more complex)

**Warning signs:** `git log` in chezmoi source shows only initial commit, not full dotfiles history.

## Code Examples

Verified patterns from official sources:

### Initialize chezmoi with Existing Dotfiles

```bash
#!/usr/bin/env bash
# Source: https://www.chezmoi.io/user-guide/setup/
# Initialize chezmoi source directory

# Create chezmoi source directory (default location)
chezmoi init --source=$HOME/.local/share/chezmoi

# Or specify custom source location
chezmoi init --source=$HOME/.dotfiles

# Verify initialization
chezmoi doctor
```

### Migrate Shell Files from Dotbot Symlinks

```bash
#!/usr/bin/env bash
# Source: https://www.chezmoi.io/migrating-from-another-dotfile-manager/
# Migrate core shell configuration from Dotbot to chezmoi

# Step 1: Verify current state (Dotbot symlinks)
ls -la ~ | grep -E '\.(zshrc|zshenv|zprofile)'
# Should show symlinks to ~/.dotfiles/.config/*

# Step 2: Add files to chezmoi (--follow resolves symlinks)
chezmoi add --follow ~/.zshrc
chezmoi add --follow ~/.zshenv
chezmoi add --follow ~/.zprofile

# Step 3: Add zsh.d directory recursively
chezmoi add --recursive --follow ~/.zsh.d

# Step 4: Verify what was added
ls ~/.local/share/chezmoi/
# Should show: dot_zshrc, dot_zshenv, dot_zprofile, dot_zsh.d/

# Step 5: Check what will change
chezmoi diff

# Step 6: Apply (replaces symlinks with real files)
chezmoi apply --verbose

# Step 7: Test in new terminal
zsh -l
# Test aliases, functions, completions

# Step 8: Commit to chezmoi source
cd ~/.local/share/chezmoi
git add dot_zsh*
git commit -m "feat: migrate core shell configuration to chezmoi"
```

### Migrate Git Configuration

```bash
#!/usr/bin/env bash
# Source: chezmoi add command patterns
# Migrate git config from Dotbot symlinks to chezmoi

# Add git config files (following symlinks)
chezmoi add --follow ~/.gitconfig
chezmoi add --follow ~/.gitignore_global
chezmoi add --follow ~/.gitattributes_global

# Verify chezmoi created correct structure
ls ~/.local/share/chezmoi/
# Should show: dot_gitconfig, dot_gitignore_global, dot_gitattributes_global

# Preview changes
chezmoi diff

# Apply
chezmoi apply

# Verify git still works
git config --list --show-origin
git config user.email  # Should show your email

# Commit
cd ~/.local/share/chezmoi
git add dot_git*
git commit -m "feat: migrate git configuration to chezmoi"
```

### Set Up .chezmoiignore for Incremental Migration

```bash
# .chezmoiignore
# Source: https://www.chezmoi.io/reference/special-files/chezmoiignore/
# Files that chezmoi should NOT manage (still managed by Dotbot)

# Editor configs (unmigrated)
.config/nvim
.config/nvim/**

# Tool configs (unmigrated)
.config/atuin
.config/atuin/**
.config/sheldon
.config/sheldon/**
.config/kitty
.config/kitty.conf
.config/ghostty
.config/ghostty/**
.wezterm.lua

# Terminal emulator configs
.config/aerospace
.config/aerospace/**

# ZSH plugin manager (unmigrated)
.zgenom
.zgenom/**

# Claude configs (unmigrated)
.claude
.claude/**

# SSH config (Phase 6 scope - secrets)
.ssh
.ssh/**

# Other Dotbot-managed files
.hushlogin
.inputrc
.config/zsh-abbr
.config/oh-my-posh.omp.json
.config/bat
.config/lsd
.config/btop
.psqlrc
.sqliterc
.aider.conf.yml
.finicky.js
.editorconfig
.nanorc
.gnupg
```

### Configure chezmoi for IDE Workflow

```toml
# ~/.config/chezmoi/chezmoi.toml
# Source: https://www.chezmoi.io/reference/configuration-file/
# Configuration for manual-apply IDE workflow

[edit]
  # Don't auto-apply on edit (prefer manual chezmoi apply)
  apply = false

  # Use system editor (e.g., VSCode, IntelliJ, etc.)
  # If not set, uses $EDITOR environment variable
  # command = "code"
  # args = ["--wait"]

[git]
  # Auto-commit changes to source directory
  autoCommit = true

  # Don't auto-push (prevents accidental secret exposure)
  # Enable in Phase 6 after secret management
  autoPush = false

[diff]
  # Use delta for better diff output (if installed)
  pager = "delta"

# Data for templates (Phase 3 scope, but framework present)
[data]
  # Will be populated in Phase 3 with OS/machine detection
```

### Verification Workflow

```bash
#!/usr/bin/env bash
# Source: chezmoi command overview
# Complete verification workflow before applying changes

# 1. Check chezmoi health
chezmoi doctor
# Verifies: git installed, editor configured, no permission issues

# 2. See what would change (detailed)
chezmoi diff
# Shows unified diff of all changes

# 3. Dry run (what operations would execute)
chezmoi apply --dry-run --verbose
# Lists: add, modify, remove operations without executing

# 4. Apply changes (if happy with diff)
chezmoi apply --verbose
# Verbose shows each file operation

# 5. Verify applied state matches source
chezmoi verify
# Exits 0 if everything matches, non-zero if drift detected

# 6. Test shell in new terminal
zsh -l
# Verify aliases, functions, completions work

# Shorthand for common workflow
alias czd='chezmoi diff'
alias cza='chezmoi diff && read -q "REPLY?Apply changes? (y/n) " && echo && chezmoi apply -v'
```

### Update Dotbot Configuration After Migration

```yaml
# steps/terminal.yml
# Updated after migrating core shell files to chezmoi

---
- clean: ['~']

- link:
  # Terminal - MIGRATED TO CHEZMOI
  # .zshrc, .zshenv, .zprofile, .zsh.d/ now managed by chezmoi
  # See: ~/.local/share/chezmoi/dot_zsh*

  # Still managed by Dotbot (unmigrated):
    ~/.hushlogin: .config/hushlogin
    ~/.inputrc: .config/inputrc
    ~/.config/aerospace/aerospace.toml:
      create: true
      force: true
      path: .config/aerospace/aerospace.toml
    # ... other unmigrated configs

  # Git - MIGRATED TO CHEZMOI
  # .gitconfig, .gitignore_global, .gitattributes_global now managed by chezmoi
  # See: ~/.local/share/chezmoi/dot_git*

  # Tools - still managed by Dotbot:
    ~/.config/nvim:
      create: true
      path: nvim
    # ... other tools
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Symlink-based managers (Dotbot, stow) | chezmoi with real files + templates | 2019-2020 | Templates enable OS/machine-specific configs impossible with symlinks |
| Manual git operations | `autoCommit` / `autoPush` config | chezmoi 2.x (2020+) | Automated source versioning, but autoPush risky without secrets management |
| Manual file naming | `chezmoi add` auto-naming | Since chezmoi 1.0 | Eliminates naming errors (dot_, private_, executable_ conventions) |
| Global config templates | `.chezmoi.toml.tmpl` | chezmoi 2.x | Config itself can be templated for first-time setup prompts |
| File-by-file migration | Bulk `--recursive` + `--follow` | Since chezmoi 1.0 | Faster migration from symlink-based systems |

**Deprecated/outdated:**
- **mode = "symlink":** chezmoi supports symlink mode (behaves like Dotbot), but defeats purpose of templating/encryption features
- **`chezmoi source-path`:** Deprecated in v2, use `chezmoi cd` instead
- **Manual template detection:** `--autotemplate` flag auto-detects user email, hostname for templating

## Open Questions

Things that couldn't be fully resolved:

1. **Remote repository timing**
   - What we know: chezmoi supports git remote from initialization
   - What's unclear: Whether to push immediately after Phase 2 or wait until Phase 3 (templates)
   - Recommendation: Push after Phase 2 verification (working shell) — enables multi-machine testing early, history preserved

2. **Template vs plain files in Phase 2**
   - What we know: Files can be added with or without `.tmpl` suffix
   - What's unclear: Should Phase 2 files be templates (`.tmpl`) even if no variables yet
   - Recommendation: Add as plain files (no `.tmpl`) in Phase 2, convert to templates in Phase 3 — simplifies migration testing

3. **Dotbot removal timing**
   - What we know: .chezmoiignore enables coexistence
   - What's unclear: Whether to remove Dotbot configs after Phase 2 or keep until Phase 4
   - Recommendation: Keep Dotbot active until Phase 4 (package migration) — manages unmigrated tool configs safely

4. **Shell reminder implementation**
   - What we know: Users need workflow reminder (don't edit target files)
   - What's unclear: Best UX for first-time reminder (shell message vs README vs both)
   - Recommendation: Both — shell message for immediate feedback, README section for reference (removable after comfortable)

## Sources

### Primary (HIGH confidence)

- [chezmoi Official Documentation](https://www.chezmoi.io/) - Complete reference for all commands and patterns
- [chezmoi GitHub Repository](https://github.com/twpayne/chezmoi) - Source code, issues, discussions
- [Context7: /twpayne/chezmoi](https://context7.com/twpayne/chezmoi/llms.txt) - 925 code snippets, official examples
- [Migrating from another dotfile manager - chezmoi](https://www.chezmoi.io/migrating-from-another-dotfile-manager/) - Official migration guide
- [Setup - chezmoi](https://www.chezmoi.io/user-guide/setup/) - Official setup patterns
- [Quick start - chezmoi](https://www.chezmoi.io/quick-start/) - Getting started guide
- [Target types - chezmoi](https://www.chezmoi.io/reference/target-types/) - File naming conventions reference
- [Source state attributes - chezmoi](https://www.chezmoi.io/reference/source-state-attributes/) - Attribute prefix/suffix rules
- [Configuration file - chezmoi](https://www.chezmoi.io/reference/configuration-file/) - All config options documented

### Secondary (MEDIUM confidence)

- [Taking Control of My Dotfiles with chezmoi (2026-01-13)](https://blog.cmmx.de/2026/01/13/taking-control-of-my-dotfiles-with-chezmoi/) - Recent 2026 migration experience
- [Managing dotfiles with Chezmoi - Nathaniel Landau](https://natelandau.com/managing-dotfiles-with-chezmoi/) - Comprehensive setup guide
- [How To Manage Dotfiles With Chezmoi - jerrynsh.com](https://jerrynsh.com/how-to-manage-dotfiles-with-chezmoi/) - Best practices guide
- [Migrating a pre-existing dotfiles repository · Discussion #2330](https://github.com/twpayne/chezmoi/discussions/2330) - Community migration patterns
- [Design - chezmoi FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/) - Design philosophy and tradeoffs
- [Usage - chezmoi FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/) - Common usage patterns
- [Troubleshooting - chezmoi FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/troubleshooting/) - Common problems and solutions
- [Daily operations - chezmoi](https://www.chezmoi.io/user-guide/daily-operations/) - Workflow patterns including autoCommit/autoPush
- [Editor - chezmoi](https://www.chezmoi.io/user-guide/tools/editor/) - Editor integration patterns

### Tertiary (LOW confidence - marked for validation)

- [shunk031/dotfiles](https://github.com/shunk031/dotfiles) - Example chezmoi + mise + sheldon integration (not official)
- Community blog posts (various) - Individual experiences, not authoritative

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - chezmoi 2.69.3 is current stable release, well-documented with official sources
- Architecture patterns: HIGH - All migration patterns verified from official docs and Context7 code examples
- Pitfalls: HIGH - Common mistakes documented in official FAQ and community discussions with consistent recommendations
- Git workflow: HIGH - Fork/migrate approach verified in official discussions and git rename detection is established behavior

**Research date:** 2026-01-25
**Valid until:** ~90 days (April 2026) — chezmoi stable with backward compatibility guarantees, patterns unlikely to change
