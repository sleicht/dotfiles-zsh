# Domain Pitfalls: Completing Dotbot-to-chezmoi Migration

**Domain:** Dotfiles management - completing transition from Dotbot symlinks to chezmoi for remaining configs
**Milestone Context:** SUBSEQUENT milestone - chezmoi already managing core files (zsh, mise, Brewfile), now adding remaining Dotbot-managed configs
**Researched:** 2026-02-08
**Overall Confidence:** MEDIUM (official docs HIGH, repo-as-source scenario MEDIUM, specific config types LOW)

## Critical Context

This analysis focuses on pitfalls when ADDING remaining config migrations to an EXISTING chezmoi setup. Key constraints:
- The dotfiles-zsh repo (`/Users/stephanlv_fanaka/Projects/dotfiles-zsh`) **IS** the chezmoi source directory
- chezmoi already manages core files (.zshrc, .zshenv, mise config, Brewfile)
- Dotbot still manages many configs via symlinks from `.config/` to `~/.config/`
- Removing Dotbot infrastructure from repo = removing from chezmoi source

**See also:** `.planning/research/PITFALLS.md` for general chezmoi migration pitfalls (workflow shifts, templates, PATH issues, etc.). This document covers pitfalls specific to completing the migration.

---

## Critical Pitfalls

### Pitfall 1: Repo-is-Source Deletion Cascade
**What goes wrong:** Removing Dotbot infrastructure files from the repo (install script, steps/, dotbot submodules) directly removes them from chezmoi's source directory. chezmoi may interpret this as "user wants these files removed from target locations" and attempt to delete them from home directory or cause tracking errors.

**Why it happens:**
- Typical chezmoi setup: source dir (`~/.local/share/chezmoi`) ≠ git repo
- **Your setup:** source dir = git repo
- chezmoi tracks **everything** in source dir by default unless explicitly ignored
- Removing Dotbot files changes chezmoi source state
- `exact_` directories make this worse (will delete unmanaged files)
- `.git` directory is special-cased by chezmoi, but `.gitmodules` is not

**Consequences:**
- CRITICAL: chezmoi may try to apply Dotbot infrastructure as dotfiles
- Removing dotbot submodule without `.chezmoiignore` causes confusion
- `chezmoi diff` shows unexpected changes when Dotbot files are removed
- Git history corruption if panicked removal/re-add happens
- Migration impossible to rollback cleanly

**Prevention:**
1. **BEFORE ANY Dotbot infrastructure removal**, add to `.chezmoiignore`:
   ```
   # .chezmoiignore
   # Dotbot infrastructure (not dotfiles)
   install
   install.conf.yaml
   steps/
   dotbot/
   .gitmodules
   ```

2. Test that chezmoi doesn't track these files:
   ```bash
   chezmoi managed | grep -E "install|steps|dotbot"
   # Should return NOTHING
   ```

3. Verify with dry-run BEFORE committing `.chezmoiignore`:
   ```bash
   chezmoi apply -n -v  # Should show no Dotbot infrastructure changes
   ```

4. Commit `.chezmoiignore` separately BEFORE removing any files:
   ```bash
   git add .chezmoiignore
   git commit -m "chore: ignore Dotbot infrastructure in chezmoi"
   ```

5. Only THEN remove Dotbot infrastructure (final phase):
   ```bash
   git rm -r dotbot steps install
   git commit -m "chore: remove Dotbot infrastructure after migration complete"
   ```

**Detection:**
- **Before damage:** `chezmoi managed` lists Dotbot infrastructure files
- **Before damage:** `chezmoi diff` shows Dotbot files as changes
- **After damage:** Dotbot infrastructure appears in home directory
- **After damage:** `chezmoi apply` fails with unexpected file operations

**Phase recommendation:** Phase 0 (Preparation) - establish `.chezmoiignore` before ANY config migrations begin. Phase 4 (Retirement) - remove Dotbot infrastructure only after ALL other phases complete.

**Confidence:** HIGH (inferred from official docs + repo structure, validated by repo-as-source use case)

**Sources:**
- [Customize your source directory - chezmoi](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)
- [.chezmoiignore - chezmoi](https://www.chezmoi.io/reference/special-files/chezmoiignore/)
- [Design FAQ - chezmoi](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/)

---

### Pitfall 2: Orphaned Symlink Accumulation
**What goes wrong:** After migrating configs to chezmoi, Dotbot-created symlinks remain in place. If migration is incomplete or configs later change, you end up with: symlinks pointing to non-existent files, configs loaded from wrong location, or chezmoi/Dotbot fighting over same files.

**Why it happens:**
- Dotbot creates symlinks: `~/.config/kitty/kitty.conf -> ~/Projects/dotfiles-zsh/.config/kitty/kitty.conf`
- `chezmoi add --follow ~/.config/kitty/kitty.conf` adds the TARGET content to chezmoi
- `chezmoi apply` replaces symlink with a REGULAR FILE containing that content
- BUT: If migration is incremental, some symlinks remain while others are replaced
- If Dotbot install script runs again (accidentally), it recreates symlinks, clobbering chezmoi-managed files
- If files are removed from repo before chezmoi manages them, symlinks become broken

**Consequences:**
- Config changes in chezmoi don't take effect (file is actually a symlink to old location)
- Editing file in target location edits wrong source (in repo, not chezmoi source)
- `chezmoi diff` shows no changes because symlink target matches
- Hard to debug: `ls -la` shows symlink, but config "looks" fine
- Cross-machine confusion: one machine has symlinks, another has chezmoi-managed files

**Prevention:**
1. **Audit symlinks BEFORE starting migration:**
   ```bash
   # Find all Dotbot-created symlinks
   find ~/.config -type l -ls | grep "dotfiles-zsh"
   find ~ -maxdepth 1 -name ".*" -type l -ls | grep "dotfiles-zsh"

   # Save inventory
   find ~/.config ~/.* -type l 2>/dev/null | grep "dotfiles-zsh" > ~/dotbot-symlinks-inventory.txt
   ```

2. **For EACH config being migrated:**
   ```bash
   # 1. Verify current state
   ls -la ~/.config/kitty/kitty.conf  # Confirm it's a symlink

   # 2. Add with --follow
   chezmoi add --follow ~/.config/kitty/kitty.conf

   # 3. Verify chezmoi will replace symlink with file
   chezmoi diff  # Should show symlink -> regular file change

   # 4. Test with dry-run
   chezmoi apply -n -v  # Should show symlink removal + file creation

   # 5. Apply
   chezmoi apply

   # 6. Verify result
   ls -la ~/.config/kitty/kitty.conf  # Should be regular file now
   file ~/.config/kitty/kitty.conf    # Should NOT say "symbolic link"
   ```

3. **After migration phase completes, audit symlinks again:**
   ```bash
   # Should show fewer symlinks than before
   find ~/.config -type l -ls | grep "dotfiles-zsh"
   ```

4. **NEVER run Dotbot's `./install` script after migrating files to chezmoi**

5. **Document symlink transition in migration log:**
   ```markdown
   ## Phase 2: Terminal Emulators
   - kitty: symlink replaced ✓
   - ghostty: symlink replaced ✓
   - wezterm: symlink replaced ✓
   ```

**Detection:**
- **Before migration:** `ls -la ~/.config/[tool]/` shows `->` arrows
- **Incomplete migration:** Some files are symlinks, others are regular files
- **Symlink points to wrong location:** `readlink ~/.config/[tool]/[file]` shows unexpected path
- **Broken symlink:** File shows red in `ls` or "No such file or directory" when reading
- **chezmoi not taking effect:** `chezmoi apply` succeeds but config doesn't change

**Recovery:**
```bash
# If symlinks interfere with chezmoi
rm ~/.config/[tool]/[file]  # Remove symlink
chezmoi apply               # Let chezmoi recreate as regular file

# If you need to rollback
chezmoi forget ~/.config/[tool]/[file]  # Remove from chezmoi
cd ~/Projects/dotfiles-zsh
./install  # Recreate Dotbot symlink
```

**Phase recommendation:** Phases 1-3 (each config migration) - check for symlinks before and after EVERY config type migration.

**Confidence:** HIGH (official docs + real-world symlink migration patterns)

**Sources:**
- [Migrating from another dotfile manager - chezmoi](https://www.chezmoi.io/migrating-from-another-dotfile-manager/)
- [Target types - chezmoi](https://www.chezmoi.io/reference/target-types/)
- [Design FAQ - chezmoi](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/)

---

### Pitfall 3: Accidental Local Settings Exposure (.claude/ Risk)
**What goes wrong:** Large directories like `.claude/` (50+ files) contain mix of shared settings (`.claude/commands/`) and machine-local settings (`.claude/settings.local.json`). Running `chezmoi add ~/.claude/` adds EVERYTHING, including local settings with absolute paths, API keys, or machine-specific values. These get committed to public repo, exposing secrets or causing config breakage on other machines.

**Why it happens:**
- `chezmoi add <directory>` is recursive by default
- Large directories are hard to audit manually (50+ files)
- `.gitignore` in repo doesn't prevent chezmoi from managing files
- `.claude/settings.local.json` is explicitly meant to be machine-local (per Claude Code docs)
- Absolute paths like `/Users/stephanlv_fanaka/...` break on other machines or users
- API keys, tokens in config files not obvious without careful inspection

**Consequences:**
- CRITICAL: API keys, tokens leaked to git history (requires force-push to fix)
- Machine-specific paths break configs on other machines
- Local preferences applied to all machines (unwanted)
- Git history rewrite needed to remove leaked secrets (difficult, breaks forks)
- Public dotfiles repo exposes private project paths, usernames, etc.

**Prevention:**
1. **BEFORE adding any large directory, establish `.chezmoiignore` patterns:**
   ```
   # .chezmoiignore
   # Claude Code local settings
   .claude/settings.local.json
   .claude/**/local_*
   .claude/cache/
   .claude/**/*.log

   # Any file with "local" or "secret" in name
   **/*local*
   **/*secret*
   **/*credentials*
   .env
   .env.local
   *.pem
   *.key
   ```

2. **Audit directory contents BEFORE adding:**
   ```bash
   # See what would be added
   find ~/.claude -type f | head -20

   # Check for sensitive patterns
   grep -r "token\|key\|password\|secret" ~/.claude/ 2>/dev/null | grep -v ".git"

   # Check for absolute paths
   grep -r "/Users/$(whoami)" ~/.claude/ 2>/dev/null
   ```

3. **Add directory contents selectively, not all at once:**
   ```bash
   # DON'T: chezmoi add ~/.claude/

   # DO: Add specific subdirectories
   chezmoi add ~/.claude/commands/
   chezmoi add ~/.claude/CLAUDE.md
   # Explicitly skip settings.local.json
   ```

4. **For machine-specific values, use chezmoi templates:**
   ```yaml
   # .claude/settings.json.tmpl
   {
     "workingDirectory": "{{ .chezmoi.homeDir }}/Projects",
     "defaultModel": "{{ .claude.defaultModel }}",
     "apiEndpoint": "{{ .claude.apiEndpoint }}"
   }
   ```

   Then in `~/.config/chezmoi/chezmoi.toml`:
   ```toml
   [data.claude]
     defaultModel = "claude-opus-4"
     apiEndpoint = "https://api.anthropic.com"
   ```

5. **For secrets, use encryption or password manager integration:**
   ```bash
   # Option 1: Encrypt sensitive files
   chezmoi add --encrypt ~/.claude/api-key.json

   # Option 2: Use password manager template
   # .claude/api-key.json.tmpl
   # {{ onepasswordRead "op://Private/Claude API Key/credential" }}
   ```

6. **ALWAYS run `chezmoi diff` before applying:**
   ```bash
   chezmoi diff | grep -E "token|key|password|/Users/"
   # Should return nothing if secrets are properly ignored
   ```

7. **NEVER enable auto-push - only auto-commit at most:**
   ```toml
   # ~/.config/chezmoi/chezmoi.toml
   [git]
     autoCommit = true  # OK - allows review before push
     autoPush = false   # CRITICAL - prevents accidental secret exposure
   ```

8. **Audit git staging before pushing:**
   ```bash
   cd ~/.local/share/chezmoi
   git status
   git diff --staged
   git diff --staged | grep -E "token|key|password|secret"
   ```

**Detection:**
- **Before commit:** `git diff --cached | grep -i "token\|key\|password\|secret"`
- **Before commit:** `git diff --cached | grep "/Users/"`
- **In repo:** `grep -r "$(whoami)" ~/.local/share/chezmoi/ | grep -v ".git"`
- **In history:** `git log -p | grep -E "password|token|key" | head -20`

**Recovery if secrets leaked:**
```bash
# 1. IMMEDIATELY rotate all leaked credentials
#    - API keys: regenerate in provider dashboard
#    - SSH keys: generate new keypair
#    - Tokens: revoke and regenerate

# 2. Remove from Git history (BFG Repo-Cleaner recommended)
brew install bfg
cd ~/.local/share/chezmoi
git clone --mirror . /tmp/dotfiles-backup.git  # Backup first

# Remove specific file from history
bfg --delete-files settings.local.json

# OR remove lines matching pattern
bfg --replace-text patterns.txt  # patterns.txt contains: "API_KEY=.*"

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (DESTRUCTIVE)
git push --force

# 3. Notify anyone who cloned/forked - their copies still have secrets!
```

**Phase recommendation:** Phase 0 (Preparation) - establish `.chezmoiignore` patterns for all known local-only files BEFORE adding any configs. Phases 1-3 (per-config) - review `.chezmoiignore` before adding each large directory.

**Confidence:** HIGH (official docs + Claude Code docs + real-world secret leakage patterns)

**Sources:**
- [Setup - chezmoi](https://www.chezmoi.io/user-guide/setup/)
- [.chezmoiignore - chezmoi](https://www.chezmoi.io/reference/special-files/chezmoiignore/)
- [Sync Claude Code commands and hooks across machines](https://www.arun.blog/sync-claude-code-with-chezmoi-and-age/)
- [Claude Code settings - Claude Code Docs](https://docs.claude.com/en/docs/claude-code/settings)

---

### Pitfall 4: exact_ Directory Data Loss
**What goes wrong:** Using `exact_` attribute on directories tells chezmoi to DELETE any files not explicitly in source. If external tools (IDE, CLI apps, caches) add files to managed directories, they silently disappear on next `chezmoi apply`. Documented case: user lost `~/.bashrc.d/additional` contents when using `exact_` with externals.

**Why it happens:**
- `exact_` means: "target directory should contain ONLY what's in chezmoi source, delete everything else"
- Useful for ensuring clean state, but dangerous with directories that have external writes
- `.claude/` generates cache files, logs, temp files during use
- `aerospace` may write runtime state
- Some tools write per-machine config on first launch
- Easy to forget which directories have external writes

**Consequences:**
- CRITICAL: Silent data loss - files deleted from filesystem, not recoverable except from backups
- Cache files deleted and regenerated repeatedly (performance impact)
- User-created files in managed directories vanish without warning
- Documented incident (GitHub Issue #3414): User lost config files due to `exact_` + externals combination
- Difficult to debug: no error message, files just disappear

**Prevention:**
1. **AVOID `exact_` directories entirely during migration**
   - Only consider after system is stable and well-understood
   - Not needed for most use cases

2. **If considering `exact_`, audit directory for external writes first:**
   ```bash
   # Monitor directory for 24 hours
   ls -la ~/.config/[tool]/ > /tmp/before.txt
   # (use system normally for a day)
   ls -la ~/.config/[tool]/ > /tmp/after.txt
   diff /tmp/before.txt /tmp/after.txt
   # Any new files? DON'T use exact_
   ```

3. **Use `.chezmoiignore` to exclude dynamic files instead of `exact_`:**
   ```
   # .chezmoiignore
   # Exclude caches from ALL config dirs (safer than exact_)
   .config/**/cache/
   .config/**/tmp/
   .config/**/*.log
   .config/**/.DS_Store

   # Specific to .claude
   .claude/cache/
   .claude/**/*.log
   ```

4. **Never use `exact_` with directories containing git externals:**
   ```bash
   # BAD: exact_ + externals = data loss (Issue #3414)
   # Don't do this
   chezmoi add --exact ~/.config/tool-with-git-subdir/
   ```

5. **Never use `chezmoi add --exact --recursive` on nested directories:**
   ```bash
   # DANGEROUS: Will remove files in ALL subdirectories
   # Don't do this
   chezmoi add --exact --recursive ~/.config/
   ```

6. **If using `exact_`, test with dry-run first:**
   ```bash
   chezmoi apply -n -v | grep "^rm"
   # Review EVERY file that will be deleted
   # If unexpected files appear, DON'T apply
   ```

7. **Document which directories use `exact_` and why:**
   ```markdown
   # ARCHITECTURE.md
   ## Directories with exact_ attribute
   - NONE during migration
   - After migration stable: TBD (evaluate case-by-case)
   ```

**Detection:**
- **Before applying:** `chezmoi diff` shows files marked for deletion (`-` prefix)
- **Before applying:** `chezmoi apply -n -v | grep "^rm"` lists files to be deleted
- **In source:** `find ~/.local/share/chezmoi -name "exact_*"` shows directories using exact_
- **After damage:** Files missing, no error message, check `chezmoi apply` output history

**Recovery:**
```bash
# If files were deleted by exact_
# 1. Check if chezmoi has them in source
ls -la ~/.local/share/chezmoi/.config/[tool]/

# 2. If not in source, files are gone - restore from backup
rsync -av /path/to/backup/.config/[tool]/ ~/.config/[tool]/

# 3. Add files to chezmoi (if should be managed)
chezmoi add ~/.config/[tool]/recovered-file

# 4. Or add to .chezmoiignore (if should NOT be managed)
echo ".config/[tool]/recovered-file" >> ~/.local/share/chezmoi/.chezmoiignore
```

**Phase recommendation:** ALL phases - avoid `exact_` entirely. Only revisit after Phase 4 (Retirement) complete and system is stable for 1+ month.

**Confidence:** HIGH (documented real-world data loss incident + official docs)

**Sources:**
- [Chezmoi confused with exact_ and externals - GitHub Issue #3414](https://github.com/twpayne/chezmoi/issues/3414)
- [Target types - chezmoi](https://www.chezmoi.io/reference/target-types/)
- [Manage different types of file - chezmoi](https://www.chezmoi.io/user-guide/manage-different-types-of-file/)

---

## Moderate Pitfalls

### Pitfall 5: Permission Mismatch After Symlink Conversion
**What goes wrong:** Dotbot preserves permissions via symlinks (symlink → file with original perms). chezmoi copies files and resets permissions based on umask or explicit attributes. Executable scripts lose execute bit, private files become world-readable.

**Why it happens:**
- Symlink permissions don't matter (OS uses target file's permissions)
- chezmoi creates NEW files with default umask permissions (usually 644)
- `private_`, `executable_`, `readonly_` must be explicitly set via filename prefixes
- Group and other permissions can't be controlled per-file in chezmoi (limitation)
- Easy to miss permission changes during migration

**Consequences:**
- Scripts fail with "permission denied" error
- Private configs (API keys, SSH config) become world-readable (security risk)
- Read-only files become writable, allowing accidental edits
- Cross-machine inconsistency if permissions not encoded in source

**Prevention:**
1. **Audit permissions BEFORE migration:**
   ```bash
   # Find executable files
   find ~/.config -type f -executable | grep -v ".git"

   # Find private files (600 or 700)
   find ~/.config -type f \( -perm 600 -o -perm 700 \) | grep -v ".git"

   # Find read-only files (444)
   find ~/.config -type f -perm 444

   # Save permission inventory
   find ~/.config -type f -exec stat -f "%Sp %N" {} \; > ~/config-permissions-before.txt
   ```

2. **Use explicit prefixes when adding files:**
   ```bash
   # Executable script
   chezmoi add ~/.config/tool/executable_script.sh
   # Results in: ~/.local/share/chezmoi/.config/tool/executable_script.sh
   # Applied as: ~/.config/tool/script.sh with 755 permissions

   # Private config
   chezmoi add ~/.config/tool/private_config.conf
   # Applied as: ~/.config/tool/config.conf with 600 permissions

   # Combine attributes
   chezmoi add ~/.config/tool/private_executable_deploy.sh
   # Applied as: ~/.config/tool/deploy.sh with 700 permissions
   ```

3. **For directories, use `private_` prefix:**
   ```bash
   chezmoi add ~/.ssh/
   # Rename in source to: private_dot_ssh/
   # Applied as: ~/.ssh/ with 700 permissions
   ```

4. **Test permissions after apply:**
   ```bash
   chezmoi apply

   # Verify executable scripts
   ls -la ~/.config/tool/script.sh
   # Should show: -rwxr-xr-x

   # Verify private configs
   ls -la ~/.ssh/config
   # Should show: -rw-------
   ```

5. **Create post-apply verification script:**
   ```bash
   # .chezmoiscripts/run_after_verify-permissions.sh
   #!/bin/bash
   set -e

   echo "Verifying critical file permissions..."

   # Check SSH config
   if [ "$(stat -f "%A" ~/.ssh/config 2>/dev/null)" != "600" ]; then
     echo "ERROR: ~/.ssh/config should be 600"
     exit 1
   fi

   # Check private keys
   find ~/.ssh -name "id_*" -not -name "*.pub" -type f | while read key; do
     if [ "$(stat -f "%A" "$key")" != "600" ]; then
       echo "ERROR: $key should be 600"
       exit 1
     fi
   done

   echo "✓ Permissions verified"
   ```

6. **Document permission requirements:**
   ```markdown
   # ARCHITECTURE.md
   ## File Permissions
   | Path | Permissions | Reason |
   |------|-------------|--------|
   | ~/.ssh/config | 600 | SSH requires private |
   | ~/.ssh/id_* | 600 | SSH keys must be private |
   | ~/.config/tool/script.sh | 755 | Executable script |
   ```

**Detection:**
- **After migration:** `ls -la ~/.config/[tool]/` shows unexpected permissions
- **Scripts fail:** `./script.sh` returns "permission denied"
- **Security scan:** `find ~ -type f -perm -004 | grep -v ".git"` finds world-readable files in configs
- **Compare:** `diff ~/config-permissions-before.txt <(find ~/.config -type f -exec stat -f "%Sp %N" {} \;)`

**Recovery:**
```bash
# If permissions are wrong after chezmoi apply

# Option 1: Fix in source (permanent)
cd ~/.local/share/chezmoi
mv .config/tool/script.sh .config/tool/executable_script.sh
chezmoi apply

# Option 2: Fix manually (temporary - will revert on next apply)
chmod +x ~/.config/tool/script.sh
chmod 600 ~/.ssh/config

# Option 3: Use run_after script for non-standard permissions
# .chezmoiscripts/run_after_fix-permissions.sh
chmod 640 ~/.config/tool/group-readable.conf
```

**Phase recommendation:** Phase 1 (Foundation) - establish permission handling strategy and create audit scripts. Phases 2-3 (per-config) - verify permissions after each config type migration.

**Confidence:** MEDIUM (chezmoi permission model documented, but platform-specific behavior varies)

**Sources:**
- [Manage different types of file - chezmoi](https://www.chezmoi.io/user-guide/manage-different-types-of-file/)
- [Persist file permissions for group and other - GitHub Issue #769](https://github.com/twpayne/chezmoi/issues/769)
- [Design FAQ - chezmoi](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/)

---

### Pitfall 6: Template Syntax Collision
**What goes wrong:** Config files naturally containing `{{ }}` or `${ }` syntax break when chezmoi interprets them as Go templates. Common in shell scripts (bash/zsh parameter expansion), Ansible configs, Kubernetes manifests, and some tool configs.

**Why it happens:**
- chezmoi uses Go `text/template` for files ending in `.tmpl`
- chezmoi evaluates `{{ }}` syntax as template expressions
- If evaluation fails (undefined variable, syntax error), `chezmoi apply` fails
- Some tools use similar syntax for their own templating (not related to chezmoi)
- Error messages can be cryptic: "template: ... : undefined variable"

**Consequences:**
- `chezmoi apply` fails with template parsing errors
- Configs that worked as symlinks break after migration
- Difficult to debug without understanding Go template syntax
- May require escaping syntax throughout file (tedious)

**Prevention:**
1. **Audit configs for template-like syntax BEFORE migration:**
   ```bash
   # Find files with {{ }} syntax
   grep -r "{{.*}}" ~/.config/ 2>/dev/null | grep -v ".git"

   # Find files with ${ } syntax (less common to conflict, but check)
   grep -r '\${.*}' ~/.config/ 2>/dev/null | grep -v ".git"

   # Save inventory
   grep -r "{{.*}}" ~/.config/ > ~/template-syntax-inventory.txt
   ```

2. **For static configs with `{{ }}` syntax, DON'T add `.tmpl` extension:**
   ```bash
   # DON'T: chezmoi add ~/.config/tool/config.yaml
   # If tool uses {{ }} syntax, add without templating:

   # Instead, add and keep as literal (no .tmpl)
   chezmoi add ~/.config/tool/config.yaml
   # In source: .config/tool/config.yaml (no .tmpl)
   ```

3. **If file DOES need templating BUT also has `{{ }}` literals, escape them:**
   ```yaml
   # .config/tool/config.yaml.tmpl
   # chezmoi template variables (evaluated)
   home_dir: {{ .chezmoi.homeDir }}

   # Tool's own template syntax (escaped for chezmoi, literal in output)
   tool_template: {{- "{{" -}} .toolVariable {{- "}}" -}}
   ```

4. **Use `.chezmoiignore` for configs that should never be templated:**
   ```
   # .chezmoiignore
   # Configs with template syntax that don't need chezmoi templating
   .config/ansible/**
   .config/k8s/**
   ```

5. **Test template parsing BEFORE applying:**
   ```bash
   # Test if file parses as template
   chezmoi execute-template < ~/.local/share/chezmoi/.config/tool/config.yaml.tmpl

   # If errors occur, file needs escaping or shouldn't be templated
   ```

6. **Document which configs are templated and why:**
   ```markdown
   # ARCHITECTURE.md
   ## Templated Configs
   | Config | Why Templated | Contains Literals |
   |--------|---------------|-------------------|
   | .zshrc | Machine-specific PATH | No |
   | .config/git/config | Username/email per machine | No |
   | .config/tool/script.sh | Has ${ } bash syntax | Yes - escaped |
   ```

**Detection:**
- **Before migration:** `grep "{{" ~/.config/[tool]/[file]` shows potential conflicts
- **During apply:** `chezmoi apply` fails with "template: unexpected ..." error
- **After apply:** File has wrong content (template variables replaced incorrectly)

**Recovery:**
```bash
# If template parsing fails

# Option 1: Remove .tmpl extension (make file non-templated)
cd ~/.local/share/chezmoi
mv .config/tool/config.yaml.tmpl .config/tool/config.yaml
chezmoi apply

# Option 2: Escape literal {{ }} in template
# Edit .config/tool/config.yaml.tmpl
# Change: {{ .variable }}
# To: {{- "{{" -}} .variable {{- "}}" -}}
chezmoi apply

# Option 3: Ignore file (don't manage with chezmoi)
echo ".config/tool/config.yaml" >> .chezmoiignore
chezmoi apply
```

**Phase recommendation:** Phase 1 (Foundation) - audit all configs for template syntax, document which need escaping. Phases 2-3 (per-config) - test template parsing before applying each config.

**Confidence:** HIGH (well-documented chezmoi behavior + common migration issue)

**Sources:**
- [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)
- [Usage FAQ - chezmoi](https://www.chezmoi.io/user-guide/frequently-asked-questions/usage/)

---

### Pitfall 7: Large Directory Performance Degradation
**What goes wrong:** Managing large directories (`.claude/` with 50+ files) causes `chezmoi diff` and `chezmoi apply` to slow down. chezmoi validates EVERY managed file on EVERY command, even if unchanged.

**Why it happens:**
- chezmoi calculates target state for all managed files on every `diff`, `apply`, `status`, `verify`
- Template evaluation adds overhead (even if no actual templating)
- Many files = many file comparisons
- Git operations in source directory slow with many tracked files
- No incremental checking (always checks all files)

**Consequences:**
- `chezmoi diff` takes >5-10 seconds (annoying in daily workflow)
- `chezmoi apply` feels sluggish (delays feedback loop)
- Shell startup slower if using `chezmoi apply` in shell init (DON'T DO THIS)
- More files = more maintenance, harder to audit changes
- Git diffs become unwieldy (50+ files per commit)

**Prevention:**
1. **Use `.chezmoiignore` to exclude frequently-changing or unnecessary files:**
   ```
   # .chezmoiignore
   # Reduce .claude/ to essentials only
   .claude/cache/
   .claude/**/*.log
   .claude/**/temp_*
   .claude/**/.DS_Store

   # Exclude auto-generated files
   **/*_cache*
   **/*.pyc
   **/__pycache__/
   ```

2. **Measure performance before and after adding large directories:**
   ```bash
   # Before adding .claude/
   time chezmoi diff
   # Baseline: ~100ms

   # After adding .claude/
   time chezmoi diff
   # If >1000ms, too slow - reduce managed files
   ```

3. **Add directory contents selectively:**
   ```bash
   # DON'T: Add entire directory
   # chezmoi add ~/.claude/

   # DO: Add specific subdirectories
   chezmoi add ~/.claude/commands/
   chezmoi add ~/.claude/CLAUDE.md
   # Skip cache, logs, etc.
   ```

4. **Avoid templating large static files:**
   ```bash
   # If file doesn't need templating, don't add .tmpl
   # Parsing templates is slower than copying files
   ```

5. **Use `chezmoi apply --include` to update only specific paths:**
   ```bash
   # Instead of: chezmoi apply (checks all files)
   # Use: chezmoi apply --include="~/.zshrc"  (checks only one file)
   ```

6. **Monitor managed file count:**
   ```bash
   # Check total managed files
   chezmoi managed | wc -l

   # >1000 files: consider whether all are necessary
   # >500 files: monitor performance

   # Check specific directory
   chezmoi managed --include=".claude/*" | wc -l
   ```

7. **Consider splitting very large directories:**
   ```bash
   # If .claude/ becomes unwieldy, manage only critical files
   # Use .chezmoiignore for rest
   # Or use external_ attribute for git-managed subdirs
   ```

**Detection:**
- **Performance test:** `time chezmoi diff` takes >2 seconds
- **File count:** `chezmoi managed | wc -l` shows >500 files
- **User experience:** `chezmoi apply` feels noticeably slow
- **Benchmark:** Run `time chezmoi diff` after each config added, track trend

**Mitigation:**
```bash
# If performance is poor

# 1. Audit managed files
chezmoi managed | less
# Are all these files necessary?

# 2. Exclude non-essential files
echo ".claude/cache/" >> .chezmoiignore
echo ".claude/**/*.log" >> .chezmoiignore

# 3. Re-add directory (will respect .chezmoiignore)
chezmoi re-add

# 4. Test performance
time chezmoi diff
# Should be faster now
```

**Phase recommendation:** Phases 2-3 (per-config) - monitor performance after adding each config type, especially large directories like `.claude/`.

**Confidence:** MEDIUM (inferred from chezmoi architecture, but no specific benchmarks found for 50-file directories)

**Sources:**
- [Design FAQ - chezmoi](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/)
- Inferred from chezmoi's architecture (validates all managed files on every command)

---

### Pitfall 8: Cross-Platform Path Incompatibility
**What goes wrong:** Configs with macOS-specific paths (`/Users/`, `/Applications/`, `/opt/homebrew/`) break on Linux. Hardcoded absolute paths in configs don't translate across platforms or users.

**Why it happens:**
- Project targets macOS + Linux
- Some tools use different default paths per OS (Homebrew: `/usr/local` on Intel macOS, `/opt/homebrew` on Apple Silicon, `/home/linuxbrew` on Linux)
- Absolute paths like `/Users/stephanlv_fanaka/` break on Linux or other users
- Some configs don't support environment variable expansion
- Easy to forget which configs are OS-specific

**Consequences:**
- Configs break when applied on different OS
- Commands fail with "file not found" errors on wrong OS
- Other users can't use your dotfiles (hardcoded username)
- Have to maintain separate versions or branches (maintenance burden)

**Prevention:**
1. **Use chezmoi templates for OS-specific paths:**
   ```bash
   # .zshrc.tmpl
   {{- if eq .chezmoi.os "darwin" -}}
   # macOS paths
   export HOMEBREW_PREFIX="/opt/homebrew"
   {{- else if eq .chezmoi.os "linux" -}}
   # Linux paths
   export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
   {{- end -}}

   export PATH="$HOMEBREW_PREFIX/bin:$PATH"
   ```

2. **Use `.chezmoiignore` templates for OS-specific configs:**
   ```
   # .chezmoiignore
   {{- if ne .chezmoi.os "darwin" }}
   # Ignore on non-macOS
   .config/aerospace/
   Library/
   {{- end }}

   {{- if ne .chezmoi.os "linux" }}
   # Ignore on non-Linux
   .config/i3/
   {{- end }}
   ```

3. **Use `{{ .chezmoi.homeDir }}` instead of hardcoded paths:**
   ```yaml
   # .config/tool/config.yaml.tmpl
   project_dir: {{ .chezmoi.homeDir }}/Projects
   # Instead of: /Users/stephanlv_fanaka/Projects
   ```

4. **Detect Homebrew prefix dynamically:**
   ```bash
   # .zshrc
   # Works on all platforms
   if [[ -x "/opt/homebrew/bin/brew" ]]; then
     HOMEBREW_PREFIX="/opt/homebrew"
   elif [[ -x "/usr/local/bin/brew" ]]; then
     HOMEBREW_PREFIX="/usr/local"
   elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
     HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
   fi
   ```

5. **Document OS-specific configs:**
   ```markdown
   # ARCHITECTURE.md
   ## Platform-Specific Configs
   | Config | Platform | Why |
   |--------|----------|-----|
   | .config/aerospace/ | macOS only | Window manager |
   | .config/kitty/ | Cross-platform | Works on both |
   | .config/karabiner/ | macOS only | Keyboard remapping |
   ```

6. **Test on both platforms (if possible):**
   ```bash
   # On macOS
   chezmoi apply -n -v | grep "/Users/"
   # Should return nothing (use {{ .chezmoi.homeDir }} instead)

   # On Linux (VM or container)
   chezmoi init --apply https://github.com/user/dotfiles-zsh.git
   # Should work without errors
   ```

**Detection:**
- **Before migration:** `grep -r "/Users/\|/Applications/\|/opt/homebrew/" ~/.config/`
- **In chezmoi source:** `grep -r "/Users/" ~/.local/share/chezmoi/ | grep -v ".git"`
- **Cross-platform test:** Apply configs on other OS, check for errors

**Recovery:**
```bash
# If hardcoded paths break on other OS

# Option 1: Use templates
cd ~/.local/share/chezmoi
# Edit .config/tool/config.yaml
# Change to: .config/tool/config.yaml.tmpl
# Replace /Users/username/ with {{ .chezmoi.homeDir }}/

# Option 2: Use OS-specific ignores
echo "{{- if ne .chezmoi.os \"darwin\" }}" >> .chezmoiignore
echo ".config/macos-only-tool/" >> .chezmoiignore
echo "{{- end }}" >> .chezmoiignore
```

**Phase recommendation:** Phase 1 (Foundation) - establish OS detection patterns and document OS-specific configs. Phases 2-3 (per-config) - check for hardcoded paths when migrating each config.

**Confidence:** HIGH (well-documented chezmoi feature for cross-platform support)

**Sources:**
- [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)

---

## Minor Pitfalls

### Pitfall 9: Git Submodule Removal Confusion
**What goes wrong:** Dotbot is typically added as git submodule. Removing submodule incorrectly leaves debris in `.git/modules/` and `.gitmodules` file. chezmoi may try to manage `.gitmodules`, causing confusion.

**Why it happens:**
- Git submodules require multi-step removal process
- Simply `git rm dotbot` leaves state in `.git/modules/`
- `.gitmodules` file may persist if not properly removed
- chezmoi sees `.gitmodules` as a file in source, may try to apply it to home directory
- Easy to forget to clean up all submodule remnants

**Consequences:**
- `git status` shows untracked files in `dotbot/` after removal
- `.git/modules/dotbot` persists, wasting disk space
- chezmoi may manage `.gitmodules` file (confusing, harmless)
- Can't re-add submodule with same path (conflict)
- Other developers cloning repo may see submodule errors

**Prevention:**
1. **Add `.gitmodules` and `dotbot/` to `.chezmoiignore` BEFORE removal:**
   ```
   # .chezmoiignore
   .gitmodules
   dotbot/
   .git/
   ```

2. **Follow proper git submodule removal steps:**
   ```bash
   # 1. Deinitialize submodule
   git submodule deinit -f dotbot

   # 2. Remove from index and working tree
   git rm -f dotbot

   # 3. Remove .gitmodules if no other submodules
   git rm -f .gitmodules

   # 4. Commit removal
   git commit -m "chore: remove dotbot submodule"

   # 5. Clean up .git/modules
   rm -rf .git/modules/dotbot
   ```

3. **Verify clean removal:**
   ```bash
   # Should show no submodules
   git submodule status

   # Should return nothing
   git ls-files --stage | grep 160000

   # Should not exist
   ls -la .gitmodules
   ```

4. **Verify chezmoi doesn't track submodule files:**
   ```bash
   chezmoi managed | grep -E "dotbot|.gitmodules"
   # Should return nothing
   ```

**Detection:**
- **After removal:** `git status` shows untracked `dotbot/` files
- **After removal:** `git submodule status` shows errors
- **chezmoi tracking:** `chezmoi managed | grep dotbot` shows submodule files

**Recovery:**
```bash
# If submodule removal was incomplete

# 1. Re-remove submodule properly
git submodule deinit -f dotbot 2>/dev/null || true
git rm -f dotbot 2>/dev/null || true
rm -rf .git/modules/dotbot

# 2. Clean .gitmodules
if [ -f .gitmodules ] && ! grep -q "\[submodule" .gitmodules; then
  git rm -f .gitmodules
fi

# 3. Commit
git commit -m "chore: complete dotbot submodule removal"

# 4. Verify
git submodule status  # Should be empty or not show dotbot
```

**Phase recommendation:** Phase 4 (Retirement) - proper submodule removal when retiring Dotbot infrastructure.

**Confidence:** HIGH (standard git submodule behavior)

**Sources:**
- Git submodule documentation (standard workflow)
- [Customize your source directory - chezmoi](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)

---

### Pitfall 10: Machine-Type Detection Failure
**What goes wrong:** Project uses machine types (client/work vs personal). Forgetting to set machine type in chezmoi config causes wrong tools installed or wrong configs applied. Work tools on personal machine, or vice versa.

**Why it happens:**
- Dotbot used separate Brewfiles (`Brewfile_Client`, `Brewfile_Fanaka`)
- chezmoi requires explicit machine detection via config or templates
- Easy to forget to set `machine_type` on new machine
- Templates fail silently if variable undefined (default behavior)
- Not obvious which configs are machine-specific without documentation

**Consequences:**
- Work-specific tools installed on personal machine (bloat, may have licensing issues)
- Personal tools installed on work machine (unprofessional, may violate policy)
- Wrong configs applied (work Git username on personal repos)
- Confusing behavior without clear error messages
- Have to manually uninstall wrong tools

**Prevention:**
1. **Set machine type in chezmoi config on EACH machine:**
   ```toml
   # ~/.config/chezmoi/chezmoi.toml
   [data]
     machine_type = "client"  # or "personal"
     email = "work@company.com"  # or personal email
     git_signing_key = "..."
   ```

2. **Prompt for machine type during `chezmoi init`:**
   ```yaml
   # .chezmoi.toml.tmpl in source directory
   {{- $machine_type := promptString "Machine type (client/personal)" -}}
   {{- $email := promptString "Git email" -}}

   [data]
     machine_type = {{ $machine_type | quote }}
     email = {{ $email | quote }}
   ```

3. **Use machine type in templates:**
   ```toml
   # Brewfile.tmpl
   # Common tools
   brew "git"
   brew "zsh"

   {{- if eq .machine_type "client" }}
   # Work-specific tools
   brew "docker"
   brew "kubectl"
   {{- end }}

   {{- if eq .machine_type "personal" }}
   # Personal tools
   brew "steam"
   {{- end }}
   ```

4. **Use machine type in `.chezmoiignore`:**
   ```
   # .chezmoiignore
   {{- if ne .machine_type "client" }}
   # Ignore work configs on personal machine
   .config/work-tools/
   {{- end }}

   {{- if ne .machine_type "personal" }}
   # Ignore personal configs on work machine
   .config/games/
   {{- end }}
   ```

5. **Document machine types:**
   ```markdown
   # ARCHITECTURE.md
   ## Machine Types
   - **client**: Work machine (corporate laptop)
   - **personal**: Personal machine (home desktop/laptop)

   ## Machine-Specific Configs
   | Config | Client | Personal |
   |--------|--------|----------|
   | Docker | ✓ | ✗ |
   | Kubectl | ✓ | ✗ |
   | Steam | ✗ | ✓ |
   ```

6. **Verify machine type is set:**
   ```bash
   # Check current machine type
   chezmoi data | grep machine_type

   # If not set, will be empty or error
   ```

**Detection:**
- **Missing config:** `chezmoi data | grep machine_type` returns nothing
- **Wrong tools:** `brew list | grep docker` on personal machine (should only be on client)
- **Template errors:** `chezmoi apply` fails with "undefined variable: machine_type"

**Recovery:**
```bash
# If wrong machine type was set

# 1. Update chezmoi config
vi ~/.config/chezmoi/chezmoi.toml
# Change machine_type to correct value

# 2. Re-apply configs
chezmoi apply

# 3. Uninstall wrong tools manually
brew uninstall docker kubectl  # If on personal machine

# 4. Install correct tools
chezmoi apply  # Will install tools for correct machine type
```

**Phase recommendation:** Phase 0 (Preparation) - establish machine detection before ANY migrations. Phase 1 (Foundation) - document machine types and create templates.

**Confidence:** HIGH (machine-specific config is documented chezmoi feature)

**Sources:**
- [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Setup - chezmoi](https://www.chezmoi.io/user-guide/setup/)

---

### Pitfall 11: Config with Natural Template Syntax (zsh-abbr)
**What goes wrong:** `zsh-abbr` abbreviations file may contain shell syntax that looks like templates. If added with `.tmpl` extension, chezmoi tries to evaluate it as a template, breaking abbreviations.

**Why it happens:**
- `zsh-abbr` stores abbreviations in a file (format TBD - needs investigation)
- May contain `${}` or `$()` shell syntax
- chezmoi interprets these as templates if file has `.tmpl` extension
- Abbreviations that work in shell fail when templated

**Consequences:**
- Abbreviations don't work after migration
- `chezmoi apply` may fail with template errors
- Shell syntax replaced with wrong values

**Prevention:**
1. **Investigate zsh-abbr storage format before migration:**
   ```bash
   # Find where zsh-abbr stores abbreviations
   ls -la ~/.config/zsh-abbr/ 2>/dev/null
   ls -la ~/.zsh-abbr/ 2>/dev/null

   # Check file contents for syntax
   cat ~/.config/zsh-abbr/user-abbreviations 2>/dev/null
   ```

2. **If file contains shell syntax, DON'T add `.tmpl` extension:**
   ```bash
   # Add without templating
   chezmoi add ~/.config/zsh-abbr/user-abbreviations
   # Results in: .config/zsh-abbr/user-abbreviations (no .tmpl)
   ```

3. **Test abbreviations after migration:**
   ```bash
   # Open new shell
   zsh

   # Test abbreviations
   # Type abbr and press space - should expand
   ```

**Detection:**
- **Before migration:** Check file for `${}`, `$()`, `` ` `` syntax
- **After migration:** Abbreviations don't expand in new shell
- **Template error:** `chezmoi apply` fails with "undefined variable"

**Recovery:**
```bash
# If abbreviations file was templated by mistake
cd ~/.local/share/chezmoi
mv .config/zsh-abbr/user-abbreviations.tmpl .config/zsh-abbr/user-abbreviations
chezmoi apply
```

**Phase recommendation:** Phase 3 (Dev Tools) - investigate zsh-abbr storage before migration.

**Confidence:** LOW (need to investigate actual zsh-abbr file format)

**Sources:**
- Inferred from common shell syntax patterns
- Investigation needed for actual zsh-abbr storage format

---

### Pitfall 12: Dropping Tools Without Cleanup (nushell, zgenom)
**What goes wrong:** Removing unused tools (nushell, zgenom) from repo without cleaning up references in configs. Old PATH entries, source statements, or aliases remain, causing errors or warnings on shell startup.

**Why it happens:**
- Configs reference tools in multiple places (.zshrc, .zshenv, aliases, functions)
- Easy to remove tool but forget to remove references
- No automated way to find all references
- Warnings may be subtle (not obvious failures)

**Consequences:**
- Shell startup shows errors: "command not found: nu"
- Warnings accumulate over time (degraded experience)
- Confusion about which tools are actually used
- Bloated configs with dead references

**Prevention:**
1. **Find all references BEFORE removing tool:**
   ```bash
   # Find nushell references
   grep -r "nushell\|nu " ~/.config/ ~/.zshrc ~/.zshenv

   # Find zgenom references
   grep -r "zgenom" ~/.config/ ~/.zshrc ~/.zshenv

   # Check PATH additions
   grep -r "/nushell/\|/zgenom/" ~/.zshrc ~/.zshenv
   ```

2. **Remove references in same commit as tool removal:**
   ```bash
   # 1. Remove config references
   vi ~/.zshrc  # Remove zgenom source statements
   chezmoi add ~/.zshrc

   # 2. Remove tool from Brewfile
   vi Brewfile  # Remove "brew nushell"
   chezmoi add Brewfile

   # 3. Commit together
   cd ~/.local/share/chezmoi
   git commit -m "refactor: remove nushell and all references"
   ```

3. **Test shell startup after removal:**
   ```bash
   # Open new shell
   zsh -x  # Shows what's being executed
   # Look for errors or "command not found"
   ```

4. **Document removed tools:**
   ```markdown
   # MIGRATION_LOG.md
   ## Removed Tools
   - **nushell**: Unused, removed 2026-02-08
     - Removed from: Brewfile, .zshrc PATH
   - **zgenom**: Replaced by sheldon, removed 2026-02-08
     - Removed from: .zshrc, all plugin references
   ```

**Detection:**
- **After removal:** Shell shows "command not found: [tool]"
- **After removal:** `echo $PATH | grep [tool]` shows old path
- **In configs:** `grep -r [removed_tool] ~/.zshrc ~/.zshenv`

**Recovery:**
```bash
# If references remain after tool removal

# Find all references
grep -r "nushell\|zgenom" ~/.zshrc ~/.zshenv ~/.config/

# Edit configs to remove
vi ~/.zshrc
# Remove source statements, PATH additions, aliases

# Apply
chezmoi add ~/.zshrc
chezmoi apply
```

**Phase recommendation:** Phase 3 (Dev Tools) - clean up when dropping nushell/zgenom.

**Confidence:** HIGH (standard cleanup practice)

**Sources:**
- General best practice for config management

---

## Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation | Priority |
|-------|-------|---------------|------------|----------|
| 0: Preparation | `.chezmoiignore` | Not ignoring Dotbot infrastructure before removal | Add install, steps/, dotbot/, .gitmodules to `.chezmoiignore` first | CRITICAL |
| 0: Preparation | Local settings | Not excluding .local, .env, credentials before adding configs | Create comprehensive `.chezmoiignore` patterns for all known local files | CRITICAL |
| 0: Preparation | Machine detection | Not setting machine_type in chezmoi config | Create `.chezmoi.toml.tmpl` with prompts, document machine types | HIGH |
| 1: Foundation | Symlink audit | Not knowing what Dotbot currently manages | Create symlink inventory: `find ~ -type l \| grep dotfiles-zsh` | HIGH |
| 1: Foundation | Permission strategy | No plan for preserving file permissions | Audit permissions, establish naming convention with `executable_`, `private_` | HIGH |
| 1: Foundation | Template syntax | Not knowing which configs contain {{ }} syntax | Audit all configs: `grep -r "{{.*}}" ~/.config/` | MEDIUM |
| 2: Terminal emulators | Symlinks not replaced | kitty/ghostty/wezterm configs still symlinked after chezmoi add | Use `--follow` flag, verify with `ls -la` after apply | HIGH |
| 2: Terminal emulators | Cache files managed | Terminal emulator caches added to chezmoi | Add `**/cache/` to `.chezmoiignore` before adding terminal configs | MEDIUM |
| 2: Aerospace | macOS-only applied on Linux | aerospace config applied on non-macOS | Use `.chezmoiignore` template with OS detection | MEDIUM |
| 3: CLI tools | Static files templated | bat/lsd configs accidentally templated | Don't add `.tmpl` extension unless actually templating | LOW |
| 3: Dev tools | Secrets in configs | lazygit/atuin configs contain API tokens | Use password manager integration or `--encrypt`, audit before adding | CRITICAL |
| 3: Dev tools | zsh-abbr shell syntax | Abbreviations file templated, breaking shell syntax | Investigate format first, don't add `.tmpl` if contains shell syntax | MEDIUM |
| 3: Dropped tools | Dead references | nushell/zgenom removed but references remain in configs | Find all references before removal, remove in same commit | LOW |
| 3: .claude/ | Large directory slowdown | 50+ files cause slow chezmoi operations | Use `.chezmoiignore` for cache/logs, add selectively | MEDIUM |
| 3: .claude/ | Local settings committed | settings.local.json added to chezmoi | Add `.claude/settings.local.json` to `.chezmoiignore` before adding directory | CRITICAL |
| 3: Karabiner | Verbose JSON diffs | Small keyboard changes = huge git diffs | Consider managing Goku EDN source instead of generated JSON | LOW |
| 4: Dotbot retirement | Orphaned symlinks | Symlinks remain after Dotbot removal | Verify all configs migrated: compare symlink inventory with `chezmoi managed` | HIGH |
| 4: Submodule removal | Git state corruption | Incorrect dotbot submodule removal | Follow proper steps: deinit, rm, clean .git/modules | MEDIUM |
| 4: Verification | Incomplete migration | Some configs still in Dotbot, some in chezmoi | Create checklist: every Dotbot-managed file should be in `chezmoi managed` | CRITICAL |
| All phases | No dry-run | Applying changes without review | ALWAYS run `chezmoi apply -n -v` before `chezmoi apply` | CRITICAL |
| All phases | Secret exposure | Not reviewing git diff before pushing | Check `git diff --staged \| grep -E "token\|key\|password"` before push | CRITICAL |
| All phases | exact_ usage | Using exact_ directories during migration | Avoid exact_ entirely until system stable for 1+ month | HIGH |

---

## Pre-Migration Checklist

Before starting ANY config migrations:

- [ ] **Repo-as-source protection**
  - [ ] Add Dotbot infrastructure to `.chezmoiignore`
  - [ ] Verify: `chezmoi managed | grep -E "install|steps|dotbot"` returns nothing
  - [ ] Commit `.chezmoiignore` separately before any other changes

- [ ] **Secret management**
  - [ ] Create `.chezmoiignore` patterns for local settings
  - [ ] Add: `.claude/settings.local.json`, `**/*local*`, `**/*secret*`, `.env`
  - [ ] Set up password manager integration (if using)
  - [ ] Disable auto-push in `~/.config/chezmoi/chezmoi.toml`

- [ ] **Machine detection**
  - [ ] Create `.chezmoi.toml.tmpl` with machine_type prompt
  - [ ] Set machine_type on current machine
  - [ ] Document machine types in ARCHITECTURE.md

- [ ] **Symlink inventory**
  - [ ] Find all Dotbot symlinks: `find ~ -type l | grep dotfiles-zsh > ~/symlink-inventory.txt`
  - [ ] Count: `wc -l ~/symlink-inventory.txt`
  - [ ] Save for later verification

- [ ] **Permission audit**
  - [ ] Find executable files: `find ~/.config -type f -executable`
  - [ ] Find private files: `find ~/.config -type f \( -perm 600 -o -perm 700 \)`
  - [ ] Document permission requirements

- [ ] **Template syntax audit**
  - [ ] Find potential conflicts: `grep -r "{{.*}}" ~/.config/ > ~/template-syntax.txt`
  - [ ] Review list, plan escaping or non-templating

- [ ] **Performance baseline**
  - [ ] Measure: `time chezmoi diff`
  - [ ] Record baseline (should be <500ms)
  - [ ] Monitor after each config added

- [ ] **Backup**
  - [ ] Create pre-migration backup: `rsync -av ~/ /backup/home-pre-completion-$(date +%Y%m%d)/`
  - [ ] Verify backup: `ls -la /backup/`
  - [ ] Test restore process

- [ ] **Migration workflow**
  - [ ] Document workflow: audit → `--follow` → diff → dry-run → apply → verify
  - [ ] Create per-config checklist template
  - [ ] Set up migration log file

---

## Per-Config Migration Checklist

For EACH config type being migrated:

- [ ] **Pre-migration**
  - [ ] Check if currently symlinked: `ls -la ~/.config/[tool]/`
  - [ ] Audit for secrets: `grep -ri "token\|key\|password" ~/.config/[tool]/`
  - [ ] Audit for template syntax: `grep -r "{{.*}}" ~/.config/[tool]/`
  - [ ] Check permissions: `find ~/.config/[tool] -type f -ls`
  - [ ] Document expected state

- [ ] **Migration**
  - [ ] Add with `--follow`: `chezmoi add --follow ~/.config/[tool]/`
  - [ ] Review source files: `ls -la ~/.local/share/chezmoi/.config/[tool]/`
  - [ ] Check for `.tmpl` extensions (should only exist if actually templating)
  - [ ] Run `chezmoi diff` to preview changes

- [ ] **Dry-run**
  - [ ] Test: `chezmoi apply -n -v | grep [tool]`
  - [ ] Verify symlink will be replaced with file
  - [ ] Check permissions in dry-run output
  - [ ] Confirm no unexpected deletions

- [ ] **Apply**
  - [ ] Apply: `chezmoi apply`
  - [ ] Verify symlink replaced: `ls -la ~/.config/[tool]/` (should NOT show `->`)
  - [ ] Test config works: run tool, check output
  - [ ] Verify permissions: `ls -la ~/.config/[tool]/` (check modes)

- [ ] **Post-migration**
  - [ ] Update migration log
  - [ ] Measure performance: `time chezmoi diff`
  - [ ] Commit: `git commit -m "feat: migrate [tool] config to chezmoi"`
  - [ ] Update symlink inventory (one less symlink)

---

## Post-Completion Verification

After ALL configs migrated:

- [ ] **Symlink verification**
  - [ ] No Dotbot symlinks remain: `find ~ -type l | grep dotfiles-zsh` (should be empty)
  - [ ] Compare with original inventory: all accounted for

- [ ] **chezmoi verification**
  - [ ] All configs managed: `chezmoi managed | wc -l` (compare with expected count)
  - [ ] No errors: `chezmoi verify`
  - [ ] Dry-run clean: `chezmoi apply -n -v` (should show no changes)

- [ ] **Secret verification**
  - [ ] No secrets in history: `git log -p | grep -E "token|key|password" | head -20`
  - [ ] No local settings committed: `git log --all -- "settings.local.json"`
  - [ ] No absolute paths: `grep -r "/Users/" ~/.local/share/chezmoi/ | grep -v ".git"`

- [ ] **Performance verification**
  - [ ] Measure: `time chezmoi diff` (should be <2s)
  - [ ] Shell startup: `time zsh -i -c exit` (should be <300ms)
  - [ ] Compare with baseline

- [ ] **Cross-machine test**
  - [ ] Apply on second machine (if available)
  - [ ] Check OS detection works (macOS vs Linux)
  - [ ] Check machine_type detection works (client vs personal)

- [ ] **Dotbot retirement**
  - [ ] Remove install script: `git rm install install.conf.yaml`
  - [ ] Remove steps: `git rm -r steps/`
  - [ ] Remove submodule: proper removal steps (see Pitfall 9)
  - [ ] Commit: `git commit -m "chore: retire Dotbot after completing chezmoi migration"`

- [ ] **Documentation**
  - [ ] Update README: remove Dotbot references, add chezmoi workflow
  - [ ] Create MIGRATION_LOG.md: document what was migrated, when, any issues
  - [ ] Update ARCHITECTURE.md: reflect current state (chezmoi only)

---

## Gaps and Open Questions

### Config-Specific Investigations Needed

1. **Terminal Emulators (Phase 2)**
   - kitty: What files are in cache? Any runtime state?
   - ghostty: Similar cache questions
   - wezterm: Similar cache questions
   - **Action:** Investigate each before migration, add caches to `.chezmoiignore`

2. **aerospace (Phase 2)**
   - Does it store runtime state? Window positions?
   - Machine-specific keyboard shortcuts?
   - **Action:** Check if `.config/aerospace/` has dynamic files

3. **CLI Tools (Phase 3)**
   - bat, lsd, btop: Are these pure static configs? Any caches?
   - oh-my-posh: Any local state or caches?
   - **Action:** Confirm static before migration

4. **Dev Tools (Phase 3)**
   - lazygit: Does config contain auth tokens?
   - atuin: Sync key in config? Local-only settings?
   - finicky: macOS-only? Path handling?
   - **Action:** Audit for secrets before adding

5. **zsh-abbr (Phase 3)**
   - Where are abbreviations stored? Format?
   - Does file contain shell syntax that conflicts with templates?
   - **Action:** Investigate storage format, test templating

6. **.claude/ (Phase 3)**
   - Full list of files in directory
   - Which are shared vs local?
   - Are there caches or logs?
   - **Action:** `tree ~/.claude/` and categorize files

7. **Karabiner (Phase 3)**
   - Is config machine-specific (keyboard hardware)?
   - Should manage Goku EDN source or generated JSON?
   - **Action:** Check if multi-machine setup needed

### Performance Questions

1. **Large directory impact**: Actual benchmark with 50-file `.claude/` directory
2. **Template overhead**: How much slower are `.tmpl` files vs plain copies?
3. **Optimal file count**: What's a reasonable upper limit for managed files?

### Migration Validation

1. **How to verify symlink→file transition worked correctly?**
   - Beyond `ls -la`, any other checks?
   - Should we save checksums of file contents before/after?

2. **How to ensure Dotbot install script never runs again?**
   - Remove execute bit?
   - Delete entirely?
   - Keep for reference?

3. **What's the rollback plan if Phase 3 fails mid-migration?**
   - Can we roll back individual configs?
   - Or need to roll back entire phase?

---

## Recommendations for Roadmap

### Phase Ordering Rationale

1. **Phase 0 (Preparation) is CRITICAL**
   - Must establish `.chezmoiignore` for Dotbot infrastructure FIRST
   - Must set up secret management patterns BEFORE adding any large directories
   - Repo-as-source scenario makes this non-negotiable

2. **Phase 1 (Foundation) establishes patterns**
   - Symlink audit creates baseline
   - Permission strategy prevents issues in later phases
   - Template syntax audit avoids surprises

3. **Phase 2 (Terminal + Window Manager) tests workflow**
   - Simpler configs (mostly static files)
   - Tests OS detection (aerospace macOS-only)
   - Lower risk if something goes wrong

4. **Phase 3 (CLI + Dev Tools + .claude/) is complex**
   - .claude/ is highest risk (50+ files, local settings)
   - Dev tools may have secrets (need careful handling)
   - Should split into sub-phases if possible

5. **Phase 4 (Retirement) only after everything else works**
   - Can't retire Dotbot until ALL configs migrated
   - Submodule removal is point of no return
   - Should have extensive verification checklist

### Risk Mitigation Strategy

1. **Incremental migration**: One config type at a time, verify between each
2. **Dry-run everything**: `chezmoi apply -n -v` is mandatory before every apply
3. **Keep Dotbot until end**: Safety net if chezmoi migration fails
4. **Branch-based approach**: Migrate on feature branch, merge after verification
5. **Backup before each phase**: Can roll back to phase N-1 if phase N fails

### Research Flags

| Phase | Needs Research | Priority | Confidence Gap |
|-------|---------------|----------|----------------|
| Phase 2 | Terminal emulator cache behavior | Medium | Don't know what files are dynamic |
| Phase 3 | zsh-abbr storage format | High | Could break abbreviations if wrong approach |
| Phase 3 | .claude/ file categorization | Critical | Need to know what's local vs shared |
| Phase 3 | Dev tool secret locations | Critical | Must not leak secrets |
| Phase 3 | Karabiner machine-specificity | Medium | May need per-machine templates |

---

## Sources and Confidence Assessment

### HIGH Confidence (Official Documentation)

- [Migrating from another dotfile manager - chezmoi](https://www.chezmoi.io/migrating-from-another-dotfile-manager/)
- [Target types - chezmoi](https://www.chezmoi.io/reference/target-types/)
- [.chezmoiignore - chezmoi](https://www.chezmoi.io/reference/special-files/chezmoiignore/)
- [Manage machine-to-machine differences - chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Design FAQ - chezmoi](https://www.chezmoi.io/user-guide/frequently-asked-questions/design/)
- [Setup - chezmoi](https://www.chezmoi.io/user-guide/setup/)
- [Templating - chezmoi](https://www.chezmoi.io/user-guide/templating/)
- [Manage different types of file - chezmoi](https://www.chezmoi.io/user-guide/manage-different-types-of-file/)
- [Customize your source directory - chezmoi](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)
- [Claude Code settings - Claude Code Docs](https://docs.claude.com/en/docs/claude-code/settings)

### MEDIUM Confidence (GitHub Issues + Community)

- [Chezmoi confused with exact_ and externals - GitHub Issue #3414](https://github.com/twpayne/chezmoi/issues/3414) - Documented data loss
- [Persist file permissions for group and other - GitHub Issue #769](https://github.com/twpayne/chezmoi/issues/769) - Permission limitations
- [Add files within a symlinked directory - GitHub Issue #3702](https://github.com/twpayne/chezmoi/issues/3702) - Symlink handling
- [Sync Claude Code commands with chezmoi and age](https://www.arun.blog/sync-claude-code-with-chezmoi-and-age/) - Community best practices
- [Migrating a pre-existing dotfiles repository - GitHub Discussion #2330](https://github.com/twpayne/chezmoi/discussions/2330) - Real-world migration experiences

### LOW Confidence (Inferred or Needs Investigation)

- Large directory performance impact: No specific benchmarks found
- zsh-abbr storage format: Needs investigation
- Terminal emulator cache behavior: Needs investigation per tool
- Karabiner machine-specificity: Needs investigation

---

**Document Version:** 1.0
**Last Updated:** 2026-02-08
**Migration Context:** Completing Dotbot→chezmoi migration (subsequent milestone, chezmoi already managing core files)
**Related:** See `.planning/research/PITFALLS.md` for general chezmoi+mise migration pitfalls
