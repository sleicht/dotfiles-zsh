# Legacy File Reference Scan Report

**Date:** 2026-02-13
**Phase:** 13 - Remove Legacy Config Files
**Scope:** All legacy files identified in Phase 13 requirements (LEGACY-01, LEGACY-02, LEGACY-04, LEGACY-05)

## Scan Methodology

This scan checked for references to all legacy configuration files across two locations:

1. **Repository working tree** (`/Users/stephanlv_fanaka/Projects/dotfiles-zsh`)
   - Excluded: `.git/`, `.planning/`, self-references
   - Tools: ripgrep with type filters

2. **Chezmoi source directory** (`/Users/stephanlv_fanaka/.local/share/chezmoi`)
   - All files scanned for legacy path references
   - Verified file coverage for zsh.d/ migration

**Special checks performed:**
- Sheldon `plugins.toml` explicitly scanned for `zsh.d/` path references
- Every `zsh.d/` file verified to have corresponding `dot_zsh.d/` file in chezmoi
- Brewfile references checked in scripts and .gitignore

---

## Category 1: .config/ Directories (10 items)

| Directory | Status | References Found |
|-----------|--------|------------------|
| `.config/aerospace` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/atuin` | **BLOCKED** | Repo: `scripts/restore-dotfiles.sh`, `scripts/verify-checks/10-dev-tools-secrets.sh` |
| `.config/bat` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/btop` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh`<br>Chezmoi: `private_dot_config/btop/btop.conf` |
| `.config/claude` | **SAFE** | None |
| `.config/ghostty` | **BLOCKED** | Repo: `scripts/restore-dotfiles.sh`, `scripts/verify-checks/09-terminal-emulators.sh` |
| `.config/git` | **BLOCKED** | Repo: `scripts/restore-dotfiles.sh`<br>Chezmoi: `private_dot_config/git/hooks/*`, `dot_gitconfig` |
| `.config/karabiner` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/lsd` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/zsh-abbr` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |

---

## Category 2: .config/ Flat Files (17 items)

| File | Status | References Found |
|------|--------|------------------|
| `.config/aider.conf.yml` | **BLOCKED** | Repo: `scripts/verify-checks/10-dev-tools-secrets.sh`<br>Chezmoi: `dot_aider.conf.yml` |
| `.config/editorconfig` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh`, `nvim/lua/config/options.lua`<br>Chezmoi: `dot_editorconfig` |
| `.config/finicky.js` | **BLOCKED** | Repo: `scripts/verify-checks/10-dev-tools-secrets.sh`<br>Chezmoi: `dot_finicky.js` |
| `.config/gpgagent` | **SAFE** | None |
| `.config/hushlogin` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/inputrc` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/kitty.conf` | **BLOCKED** | Repo: `scripts/verify-checks/09-terminal-emulators.sh`<br>Chezmoi: `private_dot_config/kitty/kitty.conf` |
| `.config/lazygit.yml` | **SAFE** | None |
| `.config/nanorc` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh`<br>Chezmoi: `dot_nanorc` |
| `.config/oh-my-posh.omp.json` | **BLOCKED** | Repo: `zsh.d/hooks.zsh`, `scripts/verify-checks/08-basic-configs.sh`<br>Chezmoi: `dot_zsh.d/hooks.zsh` |
| `.config/psqlrc` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/sqliterc` | **BLOCKED** | Repo: `scripts/verify-checks/08-basic-configs.sh` |
| `.config/ssh_config` | **SAFE** | None |
| `.config/wezterm.lua` | **BLOCKED** | Repo: `scripts/restore-dotfiles.sh`, `scripts/verify-checks/09-terminal-emulators.sh` |
| `.config/zprofile` | **BLOCKED** | Repo: `scripts/restore-dotfiles.sh`, `scripts/backup-dotfiles.sh`<br>Chezmoi: `README.md`, `dot_zprofile` |
| `.config/zshenv` | **BLOCKED** | Repo: `scripts/restore-dotfiles.sh`, `scripts/backup-dotfiles.sh`<br>Chezmoi: `dot_zshenv`, `README.md` |
| `.config/zshrc` | **BLOCKED** | Repo: `scripts/restore-dotfiles.sh`, `scripts/backup-dotfiles.sh`<br>Chezmoi: `run_once_after_remove-nix-references.sh.tmpl`, `private_dot_config/kitty/kitty.conf`, `README.md`, `dot_zshrc`, `dot_zshenv` |

---

## Category 3: zsh.d/ Directory

### Sheldon plugins.toml Check

**Location checked:** `/Users/stephanlv_fanaka/.local/share/chezmoi/private_dot_config/sheldon/plugins.toml`

**Result:** **FOUND** - Contains explicit `zsh.d/` path references:
```toml
local = "~/.zsh.d"
local = "~/.zsh.d.private"
```

### File Coverage Verification

All 15 files in `zsh.d/` have corresponding files in chezmoi `dot_zsh.d/`:

| zsh.d/ File | Chezmoi Equivalent | Status |
|-------------|-------------------|--------|
| `aliases.zsh` | `dot_zsh.d/aliases.zsh` | ✓ |
| `atuin.zsh` | `dot_zsh.d/atuin.zsh` | ✓ |
| `carapace.zsh` | `dot_zsh.d/carapace.zsh` | ✓ |
| `completions.zsh` | `dot_zsh.d/completions.zsh` | ✓ |
| `external.zsh` | `dot_zsh.d/external.zsh` | ✓ |
| `functions.zsh` | `dot_zsh.d/functions.zsh` | ✓ |
| `hooks.zsh` | `dot_zsh.d/hooks.zsh` | ✓ |
| `intelli-shell.zsh` | `dot_zsh.d/intelli-shell.zsh` | ✓ |
| `keybinds.zsh` | `dot_zsh.d/keybinds.zsh` | ✓ |
| `lens-completion.zsh` | `dot_zsh.d/lens-completion.zsh` | ✓ |
| `path.zsh` | `dot_zsh.d/path.zsh.tmpl` | ✓ |
| `ssh.zsh` | `dot_zsh.d/ssh.zsh` | ✓ |
| `variables.zsh` | `dot_zsh.d/variables.zsh` | ✓ |
| `wt.zsh` | `dot_zsh.d/wt.zsh` | ✓ |
| `xlaude.zsh` | `dot_zsh.d/xlaude.zsh` | ✓ |

### Directory References

**Status:** **BLOCKED**

**Repository references:**
- `scripts/restore-dotfiles.sh`
- `scripts/verify-checks/08-basic-configs.sh`
- `scripts/verify-backup.sh`

**Chezmoi references:**
- `private_dot_config/sheldon/plugins.toml` (configuration - expected)
- Multiple `dot_zsh.d/*.zsh` files (source commands within scripts - expected)
- `README.md` (documentation)

**Analysis:** The sheldon `plugins.toml` contains `local = "~/.zsh.d"` which means the zsh.d/ directory is actively used by the shell plugin system. Repository scripts also reference the directory for backup/restore operations.

---

## Category 4: Brewfiles (3 items)

| File | Status | References Found |
|------|--------|------------------|
| `Brewfile` | **BLOCKED** | Chezmoi: `run_onchange_after_02-cleanup-packages.sh.tmpl` |
| `Brewfile_Client` | **SAFE** | None |
| `Brewfile_Fanaka` | **SAFE** | None |

**.gitignore Check:** No Brewfile patterns found in `.gitignore`

---

## Summary

| Category | Total | SAFE | BLOCKED |
|----------|-------|------|---------|
| .config/ directories | 10 | 1 | 9 |
| .config/ flat files | 17 | 3 | 14 |
| zsh.d/ directory | 1 | 0 | 1 |
| Brewfiles | 3 | 2 | 1 |
| **TOTAL** | **31** | **6** | **25** |

### Files Safe to Delete (6)

1. `.config/claude`
2. `.config/gpgagent`
3. `.config/lazygit.yml`
4. `.config/ssh_config`
5. `Brewfile_Client`
6. `Brewfile_Fanaka`

### Files Blocked from Deletion (25)

**Primary blockers:**
1. **Verification scripts** (`scripts/verify-checks/*.sh`) - Reference 15+ legacy files
2. **Backup/Restore scripts** (`scripts/backup-dotfiles.sh`, `scripts/restore-dotfiles.sh`, `scripts/verify-backup.sh`) - Reference 8+ legacy files
3. **Sheldon configuration** - References `~/.zsh.d` directory
4. **Chezmoi source files** - Many legacy files have corresponding `dot_*` files in chezmoi source
5. **Cleanup script** - References `Brewfile` for package cleanup

**Detailed blocked items:**
- All 9 blocked .config/ directories
- All 14 blocked .config/ flat files
- The `zsh.d/` directory (actively used by sheldon)
- The `Brewfile` (referenced by cleanup script)

---

## Next Steps for Plan 02

### Phase 1: Remove Blocking Scripts

Before ANY legacy files can be deleted, the following scripts must be removed:

1. `scripts/verify-checks/08-basic-configs.sh` (blocks 11 files)
2. `scripts/verify-checks/09-terminal-emulators.sh` (blocks 3 files)
3. `scripts/verify-checks/10-dev-tools-secrets.sh` (blocks 3 files)
4. `scripts/backup-dotfiles.sh` (blocks 3 files)
5. `scripts/restore-dotfiles.sh` (blocks 6 files)
6. `scripts/verify-backup.sh` (blocks 1 file)

These scripts are legacy Phase 8-10 verification infrastructure that predates the plugin-based verification system established in Phase 7.

### Phase 2: Update Chezmoi References

Several chezmoi source files contain references to legacy paths that need updating:

1. `run_onchange_after_02-cleanup-packages.sh.tmpl` - References `Brewfile`
2. Git hook scripts - Reference `.config/git`
3. `dot_gitconfig` - May reference `.config/git`
4. Various READMEs - Documentation references

### Phase 3: Handle zsh.d/ Special Case

The `zsh.d/` directory requires careful handling:

1. **Sheldon configuration update:** Change `local = "~/.zsh.d"` to `local = "~/.zsh.d"` (or keep if ~/.zsh.d is managed by chezmoi)
2. **Verify no .zsh.d.private references:** The scan shows sheldon also references `~/.zsh.d.private`
3. **Decision needed:** Confirm zsh.d/ is fully superseded by chezmoi's dot_zsh.d/

### Phase 4: Safe Immediate Deletions

These 6 files can be deleted immediately with no blockers:

- `.config/claude`
- `.config/gpgagent`
- `.config/lazygit.yml`
- `.config/ssh_config`
- `Brewfile_Client`
- `Brewfile_Fanaka`

---

## Scan Validation

- [x] Scanned all 10 .config/ directories from Category 1
- [x] Scanned all 17 .config/ flat files from Category 2
- [x] Scanned zsh.d/ directory coverage and references from Category 3
- [x] Scanned all 3 Brewfiles from Category 4
- [x] Excluded `.config/profile` (Phase 14 scope)
- [x] Checked both repository and chezmoi source directories
- [x] Explicitly verified sheldon `plugins.toml` for zsh.d/ references
- [x] Verified all zsh.d/ files have dot_zsh.d/ counterparts
- [x] Checked .gitignore for Brewfile patterns

**Scan complete.** All legacy files categorized as SAFE or BLOCKED based on actual reference analysis.
