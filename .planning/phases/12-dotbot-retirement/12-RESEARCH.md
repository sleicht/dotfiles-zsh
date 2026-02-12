# Phase 12: Dotbot Retirement - Research

**Researched:** 2026-02-12
**Domain:** Dotfile manager migration, git submodule removal, symlink cleanup
**Confidence:** HIGH

## Summary

Phase 12 is the final cleanup phase after a complete migration from Dotbot to chezmoi (Phases 7-11). This research covers safe removal of Dotbot infrastructure, deprecated configs (nushell, zgenom), and validation that chezmoi is the sole dotfile manager.

The critical insight: **order matters**. Dotbot symlinks must be verified as replaced by real files BEFORE removal, not after. Git submodule removal requires multi-step cleanup (deinit, remove directory, remove .gitmodules entries). The verification script pattern from Phases 8-11 provides a proven framework for success criteria.

**Primary recommendation:** Remove in phases (verify → remove deprecated configs → remove Dotbot infrastructure → verify clean state → update docs). Never remove infrastructure before verifying replacement is complete.

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| chezmoi | 2.x+ | Dotfile manager (replacement) | Already validated in Phases 7-11 |
| find | GNU/BSD | Symlink detection | Cross-platform, built-in |
| git | 2.x+ | Submodule removal | Built-in git functionality |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| readlink | GNU/BSD | Symlink target inspection | Verify symlinks point to dotfiles-zsh |
| test -L | POSIX | Symlink detection | Simple existence checks |
| rm -rf | POSIX | File/directory removal | Final cleanup |

### Alternatives Considered

N/A - This is a one-time cleanup operation using standard POSIX utilities. No alternative tooling needed.

**Installation:**
```bash
# No installation required - all tools are system built-ins
```

## Architecture Patterns

### Recommended Execution Order

```
Phase 12 Execution Flow
├── Pre-Check: Verify Phases 7-11 complete
├── Identify Remaining Dotbot Symlinks
│   ├── Find all symlinks → dotfiles-zsh
│   ├── Cross-reference with chezmoi managed
│   └── Classify: migrated vs unmigrated
├── Remove Deprecated Configs (CLEAN-01, CLEAN-02)
│   ├── Remove nushell from repo and target
│   ├── Remove zgenom from repo and target
│   └── Verify no dependencies remain
├── Remove Dotbot Infrastructure (CLEAN-03)
│   ├── Git submodule deinit (dotbot, dotbot-asdf, dotbot-brew, zgenom)
│   ├── Remove .git/modules entries
│   ├── Update .gitmodules file
│   ├── Remove submodule directories
│   ├── Remove install script
│   └── Remove steps/ directory
├── Verify Clean State
│   ├── No Dotbot symlinks remain
│   ├── chezmoi managed shows all expected configs
│   └── Fresh chezmoi apply works
└── Update Documentation
    └── README reflects chezmoi-only workflow
```

### Pattern 1: Safe Symlink Removal

**What:** Verify symlink is replaced by real file before removal, not after.

**When to use:** All Dotbot→chezmoi symlink replacements.

**Example:**
```bash
# BAD: Remove then check
rm ~/.config/bat/config
chezmoi managed | grep ".config/bat/config" || echo "MISSING!"

# GOOD: Check then remove
if chezmoi managed --include=files | grep -q "\.config/bat/config"; then
  if [ -L "$HOME/.config/bat/config" ]; then
    echo "Warning: chezmoi managing but still a symlink"
  fi
  # Safe to remove Dotbot symlink entry from terminal.yml
else
  echo "ERROR: Not managed by chezmoi yet"
  exit 1
fi
```

### Pattern 2: Git Submodule Complete Removal

**What:** Multi-step process to fully remove git submodule traces.

**When to use:** Removing dotbot, dotbot-asdf, dotbot-brew, zgenom submodules.

**Example:**
```bash
# Source: https://gist.github.com/myusuf3/7f645819ded92bda6677
# Modern Git (2.22+) simplified version

SUBMODULE="dotbot"

# 1. Deinitialize (removes from .git/config)
git submodule deinit -f "$SUBMODULE"

# 2. Remove from working tree and index
git rm -f "$SUBMODULE"

# 3. Remove Git metadata
rm -rf ".git/modules/$SUBMODULE"

# 4. Commit removal
git commit -m "feat: remove $SUBMODULE submodule"

# Repeat for: dotbot-asdf, dotbot-brew, zgenom
```

**Critical:** `.gitmodules` file is automatically updated by `git rm`. Manual editing only needed for older Git versions.

### Pattern 3: Find All Dotbot Symlinks

**What:** Locate all symlinks pointing to the dotfiles-zsh repository.

**When to use:** Pre-removal verification, cleanup validation.

**Example:**
```bash
# Source: Derived from Dotbot migration best practices
# Find all symlinks in home directory (first 3 levels) pointing to dotfiles-zsh

find ~ -maxdepth 3 -type l 2>/dev/null | while read -r link; do
  target=$(readlink "$link")
  if [[ "$target" == *"dotfiles-zsh"* ]]; then
    echo "$link -> $target"
  fi
done

# Expected before Phase 12:
# ~/.config/zgenom/zgenomrc.zsh -> .../dotfiles-zsh/.config/zgenom/zgenomrc.zsh
# ~/.config/nushell -> .../dotfiles-zsh/.config/nushell
# ~/.zgenom -> .../dotfiles-zsh/zgenom
# ~/.config/nvim -> .../dotfiles-zsh/nvim  (intentional - not managed by chezmoi)

# Expected after Phase 12 (nvim is intentionally kept):
# ~/.config/nvim -> .../dotfiles-zsh/nvim
```

### Pattern 4: Verification Script Structure

**What:** Phase 12 verification script following Phases 8-11 pattern.

**When to use:** Validating Phase 12 success criteria.

**Example structure:**
```bash
#!/usr/bin/env bash
# scripts/verify-checks/12-dotbot-retirement.sh

# Check 1: No Dotbot symlinks remain (except nvim)
find ~ -maxdepth 3 -type l | while read link; do
  target=$(readlink "$link")
  # Exclude nvim - intentionally not managed by chezmoi
  if [[ "$target" == *"dotfiles-zsh"* ]] && [[ "$link" != *"nvim"* ]]; then
    check_fail "Dotbot symlink remains: $link -> $target"
  fi
done

# Check 2: Dotbot infrastructure removed
[ ! -f "install" ] || check_fail "install script still exists"
[ ! -d "steps" ] || check_fail "steps/ directory still exists"
[ ! -d "dotbot" ] || check_fail "dotbot/ submodule still exists"
[ ! -f ".gitmodules" ] || check_fail ".gitmodules still exists"

# Check 3: Deprecated configs removed
[ ! -d ".config/nushell" ] || check_fail "nushell config still in repo"
[ ! -d ".config/zgenom" ] || check_fail "zgenom config still in repo"
[ ! -d "zgenom" ] || check_fail "zgenom submodule still exists"

# Check 4: Deprecated configs removed from target
[ ! -e "$HOME/.config/nushell" ] || check_fail "nushell config still in home"
[ ! -e "$HOME/.zgenom" ] || check_fail "zgenom still in home"

# Check 5: chezmoi-only workflow functional
chezmoi diff > /dev/null || check_fail "chezmoi diff failed"
```

### Anti-Patterns to Avoid

- **Removing infrastructure before verification:** Always verify chezmoi manages all expected files FIRST, then remove Dotbot
- **Manual .gitmodules editing:** Use `git rm` for submodules, it handles .gitmodules automatically
- **Deleting symlinks directly:** Symlinks will be automatically removed when `chezmoi apply` deploys real files
- **Removing nvim symlink:** nvim is intentionally NOT managed by chezmoi (too complex, IDE-managed)
- **Skipping .git/modules cleanup:** Leftover .git/modules directories cause "submodule already exists" errors on re-add

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Git submodule removal | Custom script with manual .gitmodules editing | `git submodule deinit -f` + `git rm -f` | Modern Git handles .gitmodules, .git/config, and index updates atomically |
| Symlink detection | Parse `ls -l` output | `find -type l` + `test -L` | Robust, handles edge cases (spaces, special chars) |
| Broken symlink detection | Check each symlink manually | `find -xtype l` or `find -L -type l` | Built-in, cross-platform, handles all edge cases |
| Verification framework | New test script from scratch | Extend verify-checks/ plugin pattern | Proven pattern from Phases 8-11, auto-discovered by verify-configs.sh |

**Key insight:** Git submodule removal is deceptively complex. Multiple layers of metadata exist (.gitmodules, .git/config, .git/modules/, working tree). `git rm` handles all layers correctly; manual removal creates inconsistent state.

## Common Pitfalls

### Pitfall 1: Removing Dotbot Before Verifying Replacement

**What goes wrong:** Deleting install script or steps/ before confirming chezmoi manages all files leaves configs orphaned.

**Why it happens:** Assumption that "Phase 11 complete" means "all files migrated" — but nvim, deprecated configs intentionally not migrated.

**How to avoid:**
1. Run full verification suite (Phases 8-11) BEFORE starting Phase 12
2. Identify which symlinks are INTENTIONAL (nvim) vs deprecated (zgenom, nushell)
3. Only remove Dotbot infrastructure after deprecated configs are removed

**Warning signs:**
- `chezmoi managed` shows fewer files than expected
- `find ~ -type l` shows many dotfiles-zsh symlinks
- README still references `./install` script

### Pitfall 2: Incomplete Submodule Removal

**What goes wrong:** Only running `git rm dotbot` leaves .git/modules/dotbot directory, causing errors if submodule is ever re-added.

**Why it happens:** Assumption that `git rm` is complete removal — it only removes from working tree and index, not .git/modules/.

**How to avoid:** Three-step process for each submodule:
```bash
git submodule deinit -f <path>   # Remove from .git/config
git rm -f <path>                 # Remove from working tree, index, .gitmodules
rm -rf .git/modules/<path>       # Remove cached Git metadata
```

**Warning signs:**
- `.git/modules/dotbot` directory still exists after `git rm`
- `git submodule status` shows submodule even after removal
- Re-adding submodule fails with "already exists at path" error

### Pitfall 3: Deleting Symlinks Before chezmoi apply

**What goes wrong:** Manually deleting ~/.config/bat/config symlink before chezmoi deploys real file breaks application.

**Why it happens:** Confusion between "symlink removal" (Dotbot infrastructure) vs "symlink replacement" (chezmoi responsibility).

**How to avoid:**
- NEVER manually delete symlinks in $HOME
- Let `chezmoi apply` replace symlinks with real files automatically
- Phase 12 only removes Dotbot infrastructure (install, steps/, submodules), not target symlinks

**Warning signs:**
- Config files missing from $HOME after Phase 12
- Applications fail to launch (missing config)
- `chezmoi apply` shows "creating" instead of "updating"

### Pitfall 4: Forgetting .gitmodules Removal

**What goes wrong:** `.gitmodules` file remains in repo after all submodules removed, confusing Git.

**Why it happens:** Older Git versions don't auto-remove .gitmodules when last submodule is removed.

**How to avoid:**
- After removing all submodules, check if `.gitmodules` exists
- If file is empty or contains no submodule entries, delete it
- Modern Git (2.22+) handles this automatically with `git rm`

**Warning signs:**
- `git status` shows modified `.gitmodules` after submodule removal
- `.gitmodules` exists but is empty
- `git submodule status` shows no submodules but .gitmodules exists

### Pitfall 5: Breaking README Before Dotbot Removed

**What goes wrong:** Updating README to remove Dotbot installation instructions while install script still exists, confusing future users/machines.

**Why it happens:** Documentation updates done in wrong order relative to code changes.

**How to avoid:**
- Update README LAST, after all Dotbot infrastructure is removed
- Keep Dotbot section with deprecation notice until Phase 12 complete
- README update should be in same commit as final infrastructure removal

**Warning signs:**
- README says "managed by chezmoi" but ./install script exists
- Documentation doesn't match repository state
- New machine setup fails following README instructions

## Code Examples

Verified patterns from official sources and migration best practices.

### Complete Submodule Removal (All Four Submodules)

```bash
# Source: https://gist.github.com/myusuf3/7f645819ded92bda6677
# Modern Git approach (tested on Git 2.x)

SUBMODULES=("dotbot" "dotbot-asdf" "dotbot-brew" "zgenom")

for submodule in "${SUBMODULES[@]}"; do
  echo "Removing submodule: $submodule"

  # 1. Deinitialize (removes .git/config entry)
  git submodule deinit -f "$submodule" 2>/dev/null || true

  # 2. Remove from working tree, index, .gitmodules
  git rm -f "$submodule" 2>/dev/null || true

  # 3. Remove cached metadata
  rm -rf ".git/modules/$submodule"
done

# 4. If .gitmodules is empty, remove it
if [ -f .gitmodules ] && ! grep -q '\[submodule' .gitmodules; then
  git rm .gitmodules
fi

# 5. Commit all removals
git add -A
git commit -m "feat(cleanup): remove all Dotbot submodules and infrastructure

Removed:
- dotbot submodule
- dotbot-asdf submodule
- dotbot-brew submodule
- zgenom submodule
- .gitmodules file

Dotfile management now exclusively via chezmoi."
```

### Find and Classify Dotbot Symlinks

```bash
# Source: Derived from Linux symlink best practices
# https://www.baeldung.com/linux/find-broken-symlinks

echo "Dotbot symlinks remaining in filesystem:"
echo ""

REPO_PATH="$HOME/Projects/dotfiles-zsh"
FOUND_COUNT=0
DEPRECATED_COUNT=0

find ~ -maxdepth 3 -type l 2>/dev/null | while read -r link; do
  target=$(readlink "$link")

  if [[ "$target" == *"dotfiles-zsh"* ]]; then
    FOUND_COUNT=$((FOUND_COUNT + 1))

    # Classify: deprecated vs intentional
    case "$link" in
      *nushell*|*zgenom*)
        echo "[DEPRECATED] $link -> $target"
        DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
        ;;
      *nvim*)
        echo "[INTENTIONAL] $link -> $target"
        ;;
      *)
        # Check if chezmoi manages this
        relative_path="${link#$HOME/}"
        if chezmoi managed --include=files | grep -q "${relative_path#./}"; then
          echo "[MIGRATED, REMOVE] $link -> $target"
        else
          echo "[UNKNOWN] $link -> $target"
        fi
        ;;
    esac
  fi
done

echo ""
echo "Total symlinks to dotfiles-zsh: $FOUND_COUNT"
echo "Deprecated configs: $DEPRECATED_COUNT (must remove)"
```

### Remove Deprecated Configs Safely

```bash
# Source: Pattern from Phase 8-11 migrations
# Order: confirm not managed → remove from repo → remove from target

remove_deprecated_config() {
  local config_name="$1"
  local repo_path="$2"
  local target_path="$3"

  echo "Removing deprecated config: $config_name"

  # 1. Verify NOT managed by chezmoi
  if chezmoi managed | grep -q "$config_name"; then
    echo "ERROR: $config_name is managed by chezmoi. Cannot remove."
    return 1
  fi

  # 2. Remove from repository
  if [ -e "$repo_path" ]; then
    git rm -rf "$repo_path"
    echo "  ✓ Removed from repo: $repo_path"
  fi

  # 3. Remove from target (home directory)
  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    rm -rf "$target_path"
    echo "  ✓ Removed from target: $target_path"
  fi

  echo "  ✓ $config_name removal complete"
}

# Example usage for CLEAN-01 and CLEAN-02
remove_deprecated_config "nushell" \
  "$HOME/Projects/dotfiles-zsh/.config/nushell" \
  "$HOME/.config/nushell"

remove_deprecated_config "zgenom config" \
  "$HOME/Projects/dotfiles-zsh/.config/zgenom" \
  "$HOME/.config/zgenom"

remove_deprecated_config "zgenom submodule" \
  "$HOME/Projects/dotfiles-zsh/zgenom" \
  "$HOME/.zgenom"
```

### Verification: No Broken Symlinks

```bash
# Source: https://www.baeldung.com/linux/find-broken-symlinks
# Find broken symlinks (symlinks pointing to non-existent targets)

echo "Checking for broken symlinks in home directory..."

# Method 1: find -xtype l (most portable)
find ~ -maxdepth 3 -xtype l 2>/dev/null | while read -r broken_link; do
  echo "BROKEN SYMLINK: $broken_link -> $(readlink "$broken_link")"
done

# Method 2: find -L -type l (alternative)
# find ~ -maxdepth 3 -L -type l 2>/dev/null

# Expected: no output after Phase 12 cleanup
# Any broken symlinks indicate incomplete migration or removal
```

### README Update Pattern

```bash
# Source: Project CLAUDE.md guidance
# README update is LAST step, after all infrastructure removed

# BAD: Update README before removal
git commit -m "docs: update README for chezmoi-only workflow"
# ... install script still exists, confusing!

# GOOD: Update README with infrastructure removal
git rm install
git rm -rf steps/
# ... remove all submodules ...
# ... update README ...
git add README.md
git commit -m "feat(cleanup): complete Dotbot retirement

Removed:
- install script
- steps/ directory
- All Dotbot submodules

Updated:
- README.md: chezmoi-only workflow, removed Dotbot references

Completes Phase 12 (CLEAN-01, CLEAN-02, CLEAN-03)."
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `git rm <submodule>` only | `git submodule deinit` + `git rm` + `rm .git/modules` | Git 1.8.5+ (2013) | Complete removal prevents "already exists" errors |
| Manual .gitmodules editing | `git rm` auto-updates .gitmodules | Git 1.8.5+ (2013) | Atomic updates, no inconsistent state |
| Delete symlinks manually | `chezmoi apply` replaces automatically | chezmoi design | Safer, no manual tracking needed |
| `find -type l` + manual target check | `find -xtype l` for broken symlinks | GNU findutils 4.3.0 (2005) | Built-in broken symlink detection |

**Deprecated/outdated:**
- **Manual .gitmodules editing**: Pre-Git 1.8.5 required manual removal from .gitmodules, .git/config, and .git/modules/. Modern Git handles all three with `git submodule deinit` + `git rm`.
- **Dotbot "clean" command**: Dotbot's clean directive only handles broken symlinks within tracked directories, not full infrastructure removal.
- **Symlink-first dotfile managers (Dotbot, GNU Stow)**: Modern managers (chezmoi, yadm) use file deployment with templating, avoiding symlink fragility.

## Open Questions

1. **Should nvim config be migrated to chezmoi in the future?**
   - What we know: nvim is complex (50+ files, plugins, lazy.nvim), currently a Dotbot symlink
   - What's unclear: Is the complexity worth migrating? Does chezmoi handle vim plugin managers well?
   - Recommendation: Keep as intentional exception for now. Future Phase (post-v1.1) could migrate if needed.

2. **What if a user runs `./install` after Phase 12?**
   - What we know: install script will be deleted, but repository could be cloned by new user
   - What's unclear: Should we add a deprecation notice to install script before removal?
   - Recommendation: Add `echo "DEPRECATED: Use chezmoi instead"` to install script in Phase 12 before deleting. Helps users who bookmarked old install command.

3. **Are there other Dotbot symlinks not in terminal.yml?**
   - What we know: terminal.yml shows explicit symlinks, but users may have created custom ones
   - What's unclear: How to detect all possible Dotbot-created symlinks
   - Recommendation: Use `find ~ -type l` verification (Pattern 3) to catch all dotfiles-zsh symlinks, classify as deprecated/intentional/migrated.

## Sources

### Primary (HIGH confidence)

- Git official documentation: [git-submodule](https://git-scm.com/docs/git-submodule) - Submodule management
- Git official documentation: [gitsubmodules](https://git-scm.com/docs/gitsubmodules/2.27.0) - Submodule internals
- chezmoi official documentation: [Migrating from another dotfile manager](https://www.chezmoi.io/migrating-from-another-dotfile-manager/) - Migration best practices
- Project repository: `.planning/phases/11-claude-code/11-02-PLAN.md` - Verification script pattern
- Project repository: `scripts/verify-checks/08-basic-configs.sh` - Verification framework example
- Project repository: `install` script - Current Dotbot infrastructure
- Project repository: `steps/terminal.yml` - Dotbot symlink definitions

### Secondary (MEDIUM confidence)

- [How effectively delete a git submodule - GitHub Gist](https://gist.github.com/myusuf3/7f645819ded92bda6677) - Comprehensive removal steps
- [How to remove Git submodules - TheServerSide](https://www.theserverside.com/blog/Coffee-Talk-Java-News-Stories-and-Opinions/How-to-remove-git-submodules) - Modern Git approach
- [Linux Commands – Find Broken Symlinks - Baeldung](https://www.baeldung.com/linux/find-broken-symlinks) - Symlink detection methods
- [How to Find and Delete Broken Symlinks on Linux - How-To Geek](https://www.howtogeek.com/698838/how-to-find-and-delete-broken-symlinks-on-linux/) - Cleanup patterns
- [chezmoi: Migrate away from chezmoi](https://www.chezmoi.io/user-guide/advanced/migrate-away-from-chezmoi/) - Reverse migration insights (shows what NOT to do)

### Tertiary (LOW confidence)

- [Dotbot Issue #152: Option to uninstall/clean files?](https://github.com/anishathalye/dotbot/issues/152) - Community discussion on Dotbot cleanup (no official solution provided)

## Metadata

**Confidence breakdown:**
- Git submodule removal: HIGH - Official Git docs + verified GitHub Gist + project has 4 submodules to test
- Symlink detection: HIGH - POSIX standard + official Linux documentation + cross-platform
- Verification pattern: HIGH - Proven in Phases 8-11, directly observed in project
- chezmoi migration completion: MEDIUM - Official docs exist, but Phase 12-specific testing not yet done
- Deprecated config removal: HIGH - Straightforward file removal, terminal.yml shows exact paths

**Research date:** 2026-02-12
**Valid until:** 2026-03-14 (30 days - stable domain, Git and POSIX tools change slowly)
